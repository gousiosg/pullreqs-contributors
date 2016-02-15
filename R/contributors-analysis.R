#
# (c) 2015 -- onwards Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#
#
# Loads the contributors.csv file, renames columns to abbreviated names
# Stores results in the `contributors` workspace variable
#

rm(list = ls(all = TRUE))
source('R/utils.R')
source('R/cmdline.R')

source('R/contributors-loader.R')
source('R/survey-analysis.R')
library(klaR)

plot.name <- function(name) {
  if (nchar(prefix > 0)) {
    sprintf("%s-%s", prefix, name)
  } else {
    name
  }
}

### Demographics
prefix <- "full"
store.pdf(plot.pie(contributors, "Q1", 'Developer Roles',
                   levels = c("Project owner",
                              "Source code contributor",
                              "Translator",
                              "Documentation contributor",
                              "Other (please specify)")),
          plot.name("q1.pdf"))

store.pdf(plot.pie(contributors, "Q2", 'Developer Experience \n(years)',
                   levels = c("< 1", "1 - 2", "3 - 6", "7 - 10", "10+")),
          plot.name("q2.pdf"))

store.pdf(plot.pie(contributors, "Q3", 'Developer Experience \n(distributed software development, years)',
                   levels = c("< 1", "1 - 2", "3 - 6", "7 - 10", "10+")),
          plot.name("q3.pdf"))

store.pdf(plot.pie(contributors, "Q4", 'Developer Experience \n(open source software, years)',
                   levels = c("Never", "< 1", "1 - 2", "3 - 6", "7 - 10", "10+")),
          plot.name("q4.pdf"))

store.pdf(plot.pie(data = contributors,
                   question = "Q5",
                   title = 'Contributors work for',
                   levels = c("The industry", "The academia",
                              "The government", "Open Source Software")),
          plot.name("q5.pdf"))

columns <- c('Q1', 'Q2', 'Q5')
cl <- kmodes(contributors[, columns], 3)
print(cl$modes)

nrow(subset(contributors, Q1 == "Source code contributor" & Q5 == "The industry" & (Q2 == "10+" | Q2 == "7 - 10")))
nrow(subset(contributors, Q1 == "Source code contributor" & Q5 == "The academia" & (Q2 == "10+" | Q2 == "7 - 10")))
nrow(subset(contributors, Q1 == "Source code contributor" & Q5 == "Open Source Software" & Q2 == "3 - 6"))

printf("responses without repos: %d", nrow(subset(contributors, Q6 == '')))
printf("responses without github ids: %d", nrow(subset(contributors, githubid == '')))


### For further analysis, only use contributors that contribute exclusively via
### pull requests as reported in Q9
contributors <- subset(contributors, Q6 != '')
contributors <- subset(contributors, Q9.A3 != '' | Q9.A4 != '')
prefix <- "exclusive-contribs"

# RQ1
store.pdf(plot.multi.choice(contributors, "Q7",
                            "Why do you contribute to this specific repo"),
          plot.name("q7.pdf"))

store.pdf(plot.single.choice(contributors,
                             question = "Q8",
                             order = c("Less than 5", "5 to 10", "11 to 30", "More than 30"),
                            title = "How many pull requests did you submit to this repo in the last month"),
          plot.name("q8.pdf"))

store.pdf(plot.multi.choice(contributors, "Q9",
                            "How do you contribute code to the project"),
          plot.name("q9.pdf"))

store.pdf(plot.likert.data(contributors, "Q10",
                           c("Never", "Occasionally", "Often", "Always"),
                           "I contribute pull requests containing exclusively"),
          plot.name("q10.pdf"))

store.pdf(plot.likert.data(contributors, "Q11",
                           c("Never", "Occasionally", "Often", "Always"),
                           "Before starting to work on a pull request, I"),
          plot.name("q11.pdf"))

store.pdf(plot.multi.choice(contributors, "Q12",
                            "How do you communicate the intended changes"),
          plot.name("q12.pdf"))

store.pdf(plot.single.choice(contributors,
                            question = "Q13",
                            order = c(),
                            title = "Did you look up for the project's pull request guidelines at least once?"),
          plot.name("q13.pdf"))

store.pdf(plot.single.choice(contributors,
                             question = "Q14",
                             order = c(),
                             title = "How do you decide on the contents of a pull request?"),
          plot.name("q14.pdf"))

store.pdf(plot.likert.data(contributors, "Q16",
                           c("Never", "Occasionally", "Often", "Always"),
                           "When I am ready to submit a pull request, I"),
          plot.name("q16.pdf"))

store.pdf(plot.likert.data(contributors, "Q17",
                           c("Negatively", "Does not affect me", "Positively"),
                           "How do the following factors affect your decision to contribute to a project?"),
          plot.name("q17.pdf"))

q15 <- load.tagged.file('contrib-q15-coded.csv')
q15 <- subset(q15, q15$X %in% row.names(contributors))

store.pdf(plot.tag.freq(data = q15,
                        filter = c('', 'none'),
                        title = "How do you assess the quality of pull requests before submitting?"),
          plot.name('q15-tag-freq.pdf'))

store.pdf(plot.tag.freq(data = q15,
                        filter = c('', 'none'),
                        title = "How do you assess the quality of pull requests before submitting?",
                        ranking = F),
          plot.name('q15-tag-freq-no-rank.pdf'))

# Trying to construct a what -> how alluvial chart
# Unfortunately, not enough cases to plot
what <- c('project compliance', 'documentation', 'self appreciation', 'code quality',
          'address issue', 'makes sense', 'commit quality', 'standard practices')
how  <- c('testing - manual', 'testing - sandbox', 'testing - peer', 'code review - self',
          'code review - after', 'code review - diff', 'code review - peer',
          'static analysis', 'continuous integration', 'self contained', 'building',
          'discussion', 'branching strategy', 'advice', 'coverage', 'validation scripts')

tag.frequencies <- data.frame(what = c(), how = c())
for(w in what) {
  for(h in how) {
    tag.frequencies <- rbind(tag.frequencies, data.frame(what = c(w), how = c(h)))
  }
}

tag.frequencies$Freq <-
  apply(tag.frequencies, 1, function(x) {
    sum(apply(q15[, -1], 1, function(y) {
      if (y[[2]] == '') {
        return(0)
      }

      if (y[[3]] == '') {
        if (((y[[1]] == x[[1]] && y[[2]] == x[[2]]) ||
             (y[[1]] == x[[2]] && y[[2]] == x[[1]] ))) {
          return(1)
        } else {
          return(0)
        }
      }

      if (y[[3]] != '') {
        if (((y[[1]] == x[[1]] && y[[2]] == x[[2]]) ||
             (y[[1]] == x[[2]] && y[[2]] == x[[1]] ))) {
          return(1)
        } else if(((y[[1]] == x[[1]] && y[[3]] == x[[2]]) ||
                   (y[[3]] == x[[2]] && y[[1]] == x[[1]] ))) {
          return(1)
        } else if(((y[[2]] == x[[1]] && y[[3]] == x[[2]]) ||
                   (y[[3]] == x[[2]] && y[[2]] == x[[1]] ))) {
          return(1)
        } else {
          return(0)
        }
      }
      return(0)
    }))
  })

printf("perc of pleople using testing also using manual testing: %f",
       tag.coexistence(q15, "testing", "testing - manual") /
         tag.existence(q15, "testing"))

printf("perc exclusive manual testing: %f",
       nrow(subset(q15, tag1 == "testing - manual" & tag2 == ""))/ nrow(q15))

printf("perc code review self and diff %f",
      (tag.existence(q15, "code review - self") +
        tag.existence(q15, "code review - diff")) / nrow(q15))



# q18
q18 <- load.tagged.file('contrib-q18-coded.csv')
q18 <- subset(q18, q18$X %in% row.names(contributors))

store.pdf(plot.tag.freq(data = q18,
                        filter = c(""),
                        title = "What could projects do to attract new contributors?"),
          plot.name('q18-tag-freq.pdf'))

store.pdf(plot.tag.freq(data = q18,
                        filter = c(""),
                        title = "What could projects do to attract new contributors?",
                        ranking = F),
          plot.name('q18-tag-freq-no-rank.pdf'))

# q18-compasionate
q18.compassionate <- load.tagged.file('contrib-q18-compassionate.csv')
q18.compassionate <- subset(q18.compassionate, q18.compassionate$X %in% row.names(contributors))

store.pdf(plot.tag.freq(data = q18.compassionate,
                        filter = c(""),
                        title = "What could projects do to attract new contributors?"),
          plot.name('q18-compassionate.pdf'))

store.pdf(plot.tag.freq(data = q18.compassionate,
                        filter = c(""),
                        title = "What could projects do to attract new contributors?",
                        ranking = F),
          plot.name('q18-compassionate.pdf'))

# q19
q19 <- load.tagged.file('contrib-q19-coded.csv')
q19 <- subset(q19, q19$X %in% row.names(contributors))

store.pdf(plot.tag.freq(data = q19,
                        filter = c('', 'none'),
                        title = "What is the biggest challenge with PRs?"),
          plot.name('q19-tag-freq.pdf'))

store.pdf(plot.tag.freq(data = q19,
                        filter = c('', 'none'),
                        title = "What is the biggest challenge with PRs?",
                        ranking = F),
          plot.name('q19-tag-freq-no-rank.pdf'))

q19 <- load.data.file('contrib-q19-coded.csv')
q19 <- subset(q19, q19$X %in% row.names(contributors))

q19 <- q19[ , -which(names(q19) %in% c("row.names","x"))]
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
q19$social <- as.numeric(trim(q19$social))
q19$tools.and.model <- as.numeric(trim(q19$tools.and.model))
q19$code <- as.numeric(trim(q19$code))

q19$type <- apply(q19, 1, function(x){
  if(!is.na(x[5]) ){return("social")}
  if(!is.na(x[6]) ){return("tool/model")}
  if(!is.na(x[7]) ){return("code")}
  NA
})

#For input to: http://app.raw.densitydesign.org
write.csv(subset(subset(merge(contributors, q19), select=c(top.10perc.contrib, type, tag1)), !is.na(type)),
          file = "q19-alluvial-data.csv",
          row.names = FALSE, quote = FALSE)


# Challenges per project size
write.csv(subset(subset(merge(contributors, q19),
                        project.size=='SMALL'|project.size=='LARGE',
                        select=c(project.size, type, tag1)), !is.na(type)),
          file = "q19-per-size-alluvial-data.csv",
          row.names = FALSE, quote = FALSE)

write.csv(subset(merge(contributors, q19),
                        project.size=='SMALL'|project.size=='LARGE',
                        select=c(project.size, tag1)),
          file = "q19-per-size-no-type-data.csv",
          row.names = FALSE, quote = FALSE)
