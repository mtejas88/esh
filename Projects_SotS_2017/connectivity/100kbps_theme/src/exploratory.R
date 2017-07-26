## ================================================================
##
## EXPLORE CHARACTERISTICS OF THOSE STILL NOT MEETING MINIMUM GOALS
##
## ================================================================
## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

#read in data
districts_notmeeting <- read.csv("../data/raw/districts_notmeeting.csv", as.is=T, header=T)
districts_meeting <- read.csv("../data/raw/districts_meeting.csv", as.is=T, header=T)

#for t tests - see if anything interesting
districts_t_test=rbind(districts_notmeeting,districts_meeting)
summary(districts_t_test)

#chi-squared test for locale and district size
tbl_l = table(districts_t_test$meeting_2014_goal_no_oversub, districts_t_test$locale) 
tbl_s = table(districts_t_test$meeting_2014_goal_no_oversub, districts_t_test$district_size) 
#both significant 
chisq.test(tbl_l) 
chisq.test(tbl_s) 
#proportional t test for 2+ bid indicator
tbl_b = table(districts_t_test$meeting_2014_goal_no_oversub, districts_t_test$frns_2p_bid_indicator)
#significant
prop.test(tbl_b)

#t test for the following variables
library(plyr)
cols_to_test <- c("ia_monthly_cost_per_mbps", "ia_bandwidth_per_student_kbps", "frl_percent","discount_rate_c1_matrix")

results <- ldply(
  cols_to_test,
  function(colname) {
    p_val = t.test(districts_t_test[[colname]] ~ districts_t_test$meeting_2014_goal_no_oversub)$p.value
    return(data.frame(colname=colname, p_value=p_val))
  })

#all are significant - not super interesting


## ================================================================
## Segmentation could be more useful here.
## ================================================================