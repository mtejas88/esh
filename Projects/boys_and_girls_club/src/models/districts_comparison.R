## ==============================================
##
## Boys and Girls Club Analysis
## 
## OBJECTIVES:
##    -- Compare BandG with fiber and bw targets
##    -- Calculate district level metrics
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/")

## load the package into your environment (you need to do this for each script)
library(dplyr)

## read in data 
districts <- read.csv("data/interim/districts.csv", as.is=T, header=T)
schools_bgca <- read.csv("data/external/BGCA_School_Sites_NCES_Identified.csv", as.is=T, header=T)

#join datasets
districts_filt <- select(districts, nces_cd, fiber_target_status, bw_target_status)
schools_upd <- left_join(schools_bgca, districts_filt, 
                        by = c("NCES.District.ID" = "nces_cd"))
schools_upd$bw_target_status <- ifelse(schools_upd$bw_target_status == 'No Data' | 
                                         schools_upd$bw_target_status == '' |
                                         is.na(schools_upd$bw_target_status),
                                       'No Data',
                                       schools_upd$bw_target_status)
schools_upd$fiber_target_status <- ifelse(schools_upd$fiber_target_status == 'No Data' | 
                                         schools_upd$fiber_target_status == '' |
                                         is.na(schools_upd$fiber_target_status),
                                       'No Data',
                                       schools_upd$fiber_target_status)
##write joined dataset for bgca
write.table(schools_upd, 
            "data/processed/schools_bgca.csv", 
            col.names=TRUE, row.names = FALSE,
            sep=",")

#create fiber/bw target summary statistics
schools_upd %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
schools_upd %>%
  group_by(fiber_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
schools_upd %>%
  group_by(bw_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
schools_upd %>%
  group_by(bw_target_status, fiber_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))

#filter joined dataset to clean and district view
districts_upd <- schools_upd %>% distinct(NCES.District.ID)
districts_upd <- left_join(districts_upd, districts, 
                           by = c("NCES.District.ID" = "nces_cd"))
districts_upd$exclude_from_ia_analysis <- as.logical(districts_upd$exclude_from_ia_analysis)
districts_upd$exclude_from_ia_cost_analysis <- as.logical(districts_upd$exclude_from_ia_cost_analysis)
districts_upd <- filter(districts_upd, !is.na(exclude_from_ia_analysis))
districts_bw <- filter(districts_upd, exclude_from_ia_analysis == FALSE)
districts_bw$goal_meeting <- ifelse(districts_bw$ia_bandwidth_per_student_kbps >= 100, 1, 0)
districts_cost <- filter(districts_upd, exclude_from_ia_cost_analysis == FALSE)
districts_cost$goal_meeting <- ifelse(districts_bw$meeting_knapsack_affordability_target == 'True', 1, 0)

#create district level bw/student statistics
districts_bw %>%
  summarize(goal_meeting_districts = sum(goal_meeting),
            total_districts = n()) %>%
  mutate(pct_goal_meeting_districts = goal_meeting_districts/total_districts)

districts_cost %>%
  summarize(goal_meeting_districts = sum(goal_meeting),
            total_districts = n()) %>%
  mutate(pct_goal_meeting_districts = goal_meeting_districts/total_districts)

districts_upd %>%
  summarize(unscalable_campuses = sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses),
            total_campuses = sum(num_campuses)) %>%
  mutate(pct_unscalable_campuses = unscalable_campuses/total_campuses)
table(districts_upd$fiber_metric_calc_group)
