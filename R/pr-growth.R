library(ggplot2)
library(scales)
library(reshape)

prs <- read.csv('~/Desktop/prs-per-month.csv')
# should be result of:
#select last_day(prh.created_at) as month, count(*)
#from pull_requests pr, pull_request_history prh
#where pr.id = prh.pull_request_id
#and prh.action='opened'
#group by last_day(prh.created_at)
prs$Month <- as.POSIXct(prs$Month, origin = "1970-01-01")

repos <- read.csv('~/Desktop/repos-with-prs.csv')
# should be result of:
#select last_day(prh.created_at) as month, count(distinct(pr.base_repo_id))
#from pull_requests pr, pull_request_history prh
#where pr.id = prh.pull_request_id
#and prh.action='opened'
#group by month
repos$Month <- as.POSIXct(repos$Month, origin = "1970-01-01")

data <- merge(prs, repos)
data <- melt(data, id.vars = 'Month')
data$variable <- gsub('\\.', ' ', data$variable)

p <- ggplot(data) +
  aes(x=Month, y = value, linetype = variable) +
  geom_line()+
  scale_x_datetime(name=element_blank()) +
  scale_y_continuous(labels = comma, name=element_blank()) +
  theme(panel.grid.major = element_blank()) +
  theme(panel.grid.minor = element_blank()) +
  theme_bw() +
  theme(legend.position="bottom", 
        legend.text = element_text(size = 9), 
        legend.key = element_rect(colour = "white"),
        legend.title=element_blank()) 

pdf('~/Desktop/prs-per-month.pdf',width=10, height = 5)
print(p)
dev.off()


