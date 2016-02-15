#
# (c) 2014 Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#
rm(list = ls(all = TRUE))
source('R/utils.R')
source('R/cmdline.R')

library(RMySQL)

enrich <- function(df) {
  df <- enrich.users(df)
  enrich.projects(df)
}

enrich.dataset <- function(df) {
  if(debug){printf("In enrich.projects")}
  
  df$mean.prs.last.12.months <- apply(df, 1, function(x){mean.prs.last.12.months(x, 16)})
  df$project.size <-
    ordered(apply(df, 1, function(x){sizer(x, df, 16, 'mean.prs.last.12.months')}),
            levels=c("SMALL", "MEDIUM", "LARGE"))
  
  df$mean.integrators.last.12.months <- apply(df, 1, function(x){mean.integrators(x, 16)})
  df$project.integrator.size <-
    ordered(apply(df, 1, function(x){sizer(x, df, 16, 'mean.integrators.last.12.months')}),
            levels=c("SMALL", "MEDIUM", "LARGE"))
  
  df$has.community.prs <- 
    factor(apply(df, 1, function(x){has.community.prs.last.12.months(x, 16)}))

  df$top.10perc.contrib <- apply(df, 1, function(x){contributor.freq(x, 16, 75)})
  df$is.newcomer <- apply(df, 1, function(x){is.newcomer(x, 16, 75)})
  df$num.commits <- apply(df, 1, function(x){num.commits(x, 16, 75)})

  df$size.of.projects.typical.contribution <- apply(contributors, 1, function(x){size.repo.contributions(x[75])})

  df
}

mean.integrators <- function(x, repo.field) {
  q <- "select count(distinct(prh.actor_id)) as integrators, year(prh.created_at), month(prh.created_at) 
  	from pull_requests pr, pull_request_history prh, users u, projects p
		where pr.base_repo_id = p.id
		and prh.pull_request_id = pr.id
		and prh.action = 'closed'
		and prh.created_at > DATE_SUB(DATE('2014-07-01'), INTERVAL 12 MONTH)
		and prh.created_at < DATE('2014-07-01')
		and p.owner_id = u.id
		and u.login = '%s'
		and p.name = '%s'
		group by year(prh.created_at), month(prh.created_at);"
  results <- run.repo.query(q, owner.repo(x[repo.field]))
  if(debug){printf("num.integrators for %s: %s", x[repo.field], mean(results$integrators))}
  as.numeric(mean(results$integrators))
}

mean.prs.last.12.months <- function(x, repo.field) {
  q <- "select count(*) as num_pr
        from pull_requests pr, pull_request_history prh, users u, projects p
        where pr.base_repo_id = p.id
          and prh.pull_request_id = pr.id
          and prh.action = 'opened'
          and prh.created_at > DATE_SUB(DATE('2014-7-1'), INTERVAL 12 MONTH)
          and prh.created_at < DATE('2014/7/1/')
          and p.owner_id = u.id
          and u.login = '%s'
          and p.name = '%s'
          group by year(prh.created_at), month(prh.created_at)"
  results <- run.repo.query(q, owner.repo(x[repo.field]))
  if(debug){printf("mean.prs.last.12.months for %s: %f", x[repo.field], mean(results$num_pr))}
  mean(results$num_pr)
}

has.community.prs.last.12.months <- function(x, repo.field) {
  q <- "select count(*) as community_prs
        from pull_requests pr, pull_request_history prh, project_members pm, 
          users u, projects p
        where prh.pull_request_id = pr.id
          and pr.base_repo_id = p.id
          and p.owner_id = u.id
          and pm.repo_id = pr.base_repo_id 
          and prh.actor_id = pm.user_id
          and prh.action = 'opened'
          and prh.created_at > pm.created_at
          and prh.created_at > DATE_SUB(DATE('2014-7-1'), INTERVAL 12 MONTH)
          and prh.created_at < DATE('2014-7-1')
          and u.login='%s'
          and p.name='%s'"
  
  results <- run.repo.query(q, owner.repo(x[repo.field]))
  if(debug){printf("has.community.prs.last.12.months for %s: %f", x[repo.field], 
                   results$community_prs > 0)}

  results$community_prs > 0   
}

contributor.freq <- function(x, repo.field, contrib.field) {
  q <- "select u1.login as login, count(*) as num_pullreqs
  	from pull_requests pr, pull_request_history prh, users u, projects p, users u1
		where pr.base_repo_id = p.id
		and prh.pull_request_id = pr.id
		and prh.action = 'opened'
		and prh.created_at > DATE_SUB(DATE('2014-07-01'), INTERVAL 12 MONTH)
		and prh.created_at < DATE('2014-07-01')
		and p.owner_id = u.id
		and u.login = '%s'
		and p.name = '%s'
    and u1.id = prh.actor_id
    group by u1.login
    order by count(*) desc
  "
  results <- run.repo.query(q, owner.repo(x[repo.field]))
  top.10 <- quantile(results$num_pullreqs, 0.90)
  repo <- x[repo.field][[1]]
  contributor <- x[contrib.field][[1]]
  if (is.na(contributor) | nchar(contributor) == 0) {
    printf("repo: %s, unknown contributor", repo)
    return(F)
  }
  
  contributions <- subset(results, login == contributor)$num_pullreqs
  if (length(contributions) != 0) {
    if (as.numeric(contributions) > top.10){
      printf("repo: %s, contrib: %s, pullreqs: %d, top-10 percent: TRUE", repo, contributor, contributions)
      return(T)
    } else {
      printf("repo: %s, contrib: %s, pullreqs: %d, top 10 percent: FALSE", repo, contributor, contributions)
      return(F)
    }
  } else {
    printf("repo: %s, contrib: %s, No contributions", repo, contributor)
    return(F)
  }
}

is.newcomer <- function(x, repo.field, contrib.field) {
  q <- "select distinct(date(prh.created_at)) as pr_created
    from pull_requests pr, projects p, users u, pull_request_history prh, users u1
    where p.id = pr.base_repo_id
    and u.id = p.owner_id
    and u.login = '%s'
    and p.name = '%s'
    and u1.login = '%s'
    and prh.actor_id = u1.id
    and prh.created_at < DATE('2014-04-01')
    and prh.action = 'opened'
    order by prh.created_at"

  contributor <- x[contrib.field][[1]]
  owner <- owner.repo(x[repo.field][[1]])[[1]][1]
  repo <- owner.repo(x[repo.field][[1]])[[1]][2]

  if (is.na(contributor) | nchar(contributor) == 0| length(strsplit(contributor, ' ')[[1]]) > 1) {
     printf("repo: %s, unknown contributor", repo)
     return(F)
  }
  
  if (is.na(owner) | nchar(owner) == 0 | length(strsplit(owner, ' ')[[1]]) > 1) {
    printf("contributor: %s, unknown repo", repo)
    return(F)
  }
  
  printf("Repo:%s, contributor: %s", x[repo.field][[1]], x[contrib.field][[1]])
  results <- run.query(sprintf(unwrap(q), owner, repo, contributor))
  results$pr_created <- as.POSIXct(results$pr_created, origin = "1970-01-01")
  min(results$pr_created) > as.POSIXct('2013-11-01')
}

num.commits <- function(x, repo.field, contrib.field) {
  q1 <- "select count(*) as num_commits
    from commits c, projects p, project_commits pc, users u, users u1
    where c.id = pc.commit_id
    and pc.project_id = p.id
    and c.author_id = u1.id
    and p.owner_id = u.id
    and c.created_at < DATE('2014-04-01')
    and u.login = '%s'
    and p.name = '%s'
    and u1.login = '%s'"
  
  q2 <- "select count(*) as total_commits 
    from projects p, project_commits pc, users u
    where pc.project_id = p.id
    and p.owner_id = u.id
    and u.login = '%s'
    and p.name = '%s'"

  contributor <- x[contrib.field][[1]]
  owner <- owner.repo(x[repo.field][[1]])[[1]][1]
  repo <- owner.repo(x[repo.field][[1]])[[1]][2]
  
  if (is.na(contributor) | nchar(contributor) == 0| length(strsplit(contributor, ' ')[[1]]) > 1) {
    printf("repo: %s, unknown contributor", repo)
    return(0)
  }
  
  if (is.na(owner) | nchar(owner) == 0 | length(strsplit(owner, ' ')[[1]]) > 1) {
    printf("contributor: %s, unknown repo", repo)
    return(0)
  }
  
  results.user <- run.query(sprintf(unwrap(q1), owner, repo, contributor))
  results.total <- run.query(sprintf(unwrap(q2), owner, repo))
  
  printf("Repo:%s, contributor: %s, commits: %d, total: %d", x[repo.field][[1]], x[contrib.field][[1]], 
         results.user[1]$num_commits, results.total[1]$total_commits)
  results.user[1]$num_commits / results.total[1]$total_commits
}

size.repo.contributions <- function(contributor) {
  q1 <- "select u.login, p.name, p.id, count(*) as num_pullreqs
      from pull_requests pr, pull_request_history prh, users u, projects p
      where p.id = pr.base_repo_id
        and p.owner_id = u.id
        and prh.pull_request_id = pr.id
        and prh.created_at between DATE('2013-04-01') and DATE('2014-04-01')
        group by p.id
        having num_pullreqs > 0"

  printf("%s",contributor)
  if(length(contributor) == 0){
    return(NA);
  }

  if (!exists("project.sizes")) {
    if (file.exists('project-sizes.csv')) {
      project.sizes <<- read.csv('project-sizes.csv')
    } else {
      project.sizes <<- run.query(sprintf(unwrap(q1)))
      len <- floor(nrow(project.sizes) / 3)
      project.sizes <- project.sizes[order(project.sizes$num_pullreqs),]
      size <- as.factor(c(rep('s', len), rep('m', len), rep('l', len)))
      project.sizes$size <- size
      write.csv(project.sizes, 'project-sizes.csv')
    }
  }

  if(grepl(" ", contributor)){
    return(NA)
  }

  q2 <- "select u.login, p.name, p.id, count(*) as num_prs_sent
      from projects p, users u, users u1, pull_requests pr, pull_request_history prh
      where u.id = p.owner_id
      and pr.base_repo_id = p.id
      and prh.pull_request_id = pr.id
      and prh.action = 'opened'
      and prh.created_at between DATE('2013-10-01') and DATE('2014-04-01')
      and prh.actor_id = u1.id
      and u1.login = '%s'
      group by p.id;"
  print(sprintf(unwrap(q2), as.character(contributor)))
  dev.stats <- run.query(sprintf(unwrap(q2), as.character(contributor)))

  if(nrow(dev.stats) == 0){
    return(NA)
  }

  a <- merge(dev.stats, project.sizes)
  contribs.per.size <- aggregate(num_prs_sent ~ size, a, sum)
  contribs.per.size[which.max(contribs.per.size[,2]),]$size
}

sizer <- function(x, data, repo.field, size.field) {
  if(debug){printf("Running sizer (%s) for %s", size.field, x[repo.field])}
  mean.item <- subset(data, !is.na(data[,size.field]))[,size.field]
  divider <- floor(length(mean.item)/3)
  first.third <- sort(mean.item)[divider]
  second.third <- sort(mean.item)[divider + divider]
  mean.size.repo <- as.numeric(x[size.field])

  if(is.na(mean.size.repo)){
    NA
  } else if(mean.size.repo <= first.third) {
    "SMALL"
  } else if(mean.size.repo > first.third && mean.size.repo <= second.third) {
    "MEDIUM"
  } else {
    "LARGE"
  }
}

owner.repo <- function(x) {
  strsplit(trim(x), "/")
}

run.repo.query <- function(q, repo) {
  run.query(unwrap(sprintf(q, repo[[1]][1], repo[[1]][2])))
}

run.query <- function(q) {
  res <- dbSendQuery(con, unwrap(q))
  fetch(res, n = -1)
  #dbClearResult(res)
}

con <- dbConnect(dbDriver("MySQL"), user = mysql.user, password = mysql.passwd,
                 dbname = mysql.db, host = mysql.host)

contributors <- read.csv(file.path(data.file.location, "contributors.csv"))
contributors <- enrich.dataset(contributors )

dimensions <- c('project.size', 'project.integrator.size', 'has.community.prs')

for(column in dimensions) {
  for(clevel in levels(contributors[, column])) {
    for(row in dimensions) {
      for(rlevel in levels(contributors[, row])) {
        printf("%s: %s and %s: %s -> %f", row, rlevel, column, clevel,
               (length(which(contributors[,row]== rlevel & contributors[,column] == clevel))/nrow(contributors)) * 100)
      }
    }
  }
}

write.csv(contributors, file = "contributors-enriched.csv")
