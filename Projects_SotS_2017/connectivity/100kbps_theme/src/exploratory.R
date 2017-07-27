## ================================================================
##
## EXPLORE CHARACTERISTICS OF THOSE STILL NOT MEETING MINIMUM GOALS
##
## ================================================================
## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("geosphere", "caTools", "dplyr", "gRbase", "dtplyr", "data.table")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(geosphere)
library(caTools)
library(dtplyr) 
library(data.table)

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
cols_to_test <- c("ia_bandwidth_per_student_kbps", "frl_percent","discount_rate_c1_matrix")

results <- ldply(
  cols_to_test,
  function(colname) {
    p_val = t.test(districts_t_test[[colname]] ~ districts_t_test$meeting_2014_goal_no_oversub)$p.value
    return(data.frame(colname=colname, p_value=p_val))
  })
results
t.test(districts_t_test[["ia_monthly_cost_per_mbps"]][districts_t_test$exclude_from_ia_cost_analysis=='false'] ~ districts_t_test$meeting_2014_goal_no_oversub[districts_t_test$exclude_from_ia_cost_analysis=='false'])$p.value 
#all are significant - not super interesting

## ================================================================
## Segmentation/clustering could be more useful here. To revisit
## ================================================================

## ================================================================
## Calulate Haversine distance to nearest school meeting goals
## ================================================================
#merge in the schools meeting in the state
districts_notmeeting_expanded=merge(districts_notmeeting,districts_meeting[,c('postal_cd','latitude','longitude')],by='postal_cd',all.x=T)

length(unique(districts_notmeeting_expanded$esh_id)) #521
districts_notmeeting_expanded=as.data.table(districts_notmeeting_expanded)

system.time({
  districts_notmeeting_expanded[,distance_hav := distHaversine(matrix(c(districts_notmeeting_expanded$longitude.x, districts_notmeeting_expanded$latitude.x), ncol = 2),
                                     matrix(c(districts_notmeeting_expanded$longitude.y, districts_notmeeting_expanded$latitude.y), ncol = 2))]
  ## convert to miles
  districts_notmeeting_expanded$distance_hav <- districts_notmeeting_expanded$distance_hav * 0.000621371
})

library(dplyr)    
districts_notmeeting_final = districts_notmeeting_expanded %>% 
  group_by(esh_id) %>% 
  slice(which.min(distance_hav))

#merge back
districts_meeting$distance_hav=0
districts_meeting$latitude.y=0
districts_meeting$longitude.y=0
districts_meeting=districts_meeting[c("esh_id","postal_cd","name","county","latitude","longitude","fiber_target_status","locale","district_size","ia_monthly_cost_total","ia_bw_mbps_total","ia_monthly_cost_per_mbps","ia_bandwidth_per_student_kbps"
                                       ,"meeting_2014_goal_no_oversub",  "exclude_from_ia_cost_analysis", "num_schools","num_students"                
                                       ,"num_campuses","frl_percent","discount_rate_c1_matrix","frns_0_bid_indicator"         
                                       ,"frns_1_bid_indicator","frns_2p_bid_indicator","latitude.y","longitude.y","distance_hav")]
names(districts_meeting)=names(districts_notmeeting_final)
dta=rbind(districts_notmeeting_final,districts_meeting)
write.csv(dta, "../data/interim/districts_notmeeting_final.csv", row.names=F)