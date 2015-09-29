### Alluvial diagrams ###
library(MASS)
library(devtools)
#install_github("mbojan/alluvial")
library(alluvial)

### Load Data
districts <- read.csv("districts_sept_28.csv")

districts$ia_bandwidth_per_student[districts$ia_bandwidth_per_student == "Insufficient data"] <- NA
districts$ia_bandwidth_per_student <- as.numeric(as.character(districts$ia_bandwidth_per_student))
districts$goals_2014 <- ifelse(districts$ia_bandwidth_per_student > 100, "Meets Goals", "Doesn't meet")
table(districts$goals_2014)

districts$ia_cost_per_mbps[districts$ia_cost_per_mbps == "Insufficient data"] <- NA
districts$ia_cost_per_mbps[districts$ia_cost_per_mbps == "Infinity"] <- NA
districts$ia_cost_per_mbps <- as.numeric(as.character(districts$ia_cost_per_mbps))
districts$afford <- ifelse(districts$ia_bandwidth_per_student < 3, "Affordable", "Not affordable")

### Subset to only fields to be plotted ###
colnames(districts)
test <- districts[,c(12,16,35, 37, 38)]

### Create vector specifying all fiber or not ###
test$all_fiber <- ifelse(test$percentage_fiber == "All fiber", "All fiber", "Not all fiber")
table(test$all_fiber)

### Generate a vector of frequency counts ###
test$freq <- rep(1,length(test[,1]))
dist.agg <- aggregate(test$freq ~ test$locale + test$district_size + 
                        test$percentage_fiber + test$goals_2014 +
                        test$afford, FUN=sum)

### Alluvial plot - no color ###
alluvial(dist.agg,freq=dist.agg$`test$freq`, hide = dist.agg$`test$freq` < quantile(dist.agg$`test$freq`,.8))

### Alluvial plot - color ###
# Regenerate frequencies
dist.agg <- aggregate(test$freq ~ test$goals_2014 + test$all_fiber + test$afford
                      + test$locale + test$district_size, 
                        FUN=sum)
# Subest frequencies
dist.agg <- subset(dist.agg, dist.agg$`test$freq` > 130)
nrow(dist.agg)

alluvial(dist.agg, freq=dist.agg$`test$freq`,
         col=ifelse(dist.agg$`test$goals_2014` == "Meets Goals", "darkgreen", "red"), 
         gap.width=.01, xw = .05, cw=.18)

