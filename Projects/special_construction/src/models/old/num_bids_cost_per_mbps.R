## ==============================================
##
## BIDS ANALYSIS - COST PER MBPS
## 
## OBJECTIVES:
##    -- Compare cost per mbps by number of bids 
##    -- Dig into trends 
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/")

library(lubridate)
library(ggplot2)
library(dplyr)
library(plotly)
library(ggmap)
library(RColorBrewer)
library(scales)
library(gridExtra)

##bids prepping
bids <- read.csv("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/external/frns_with_district_info.csv", 
                 as.is=TRUE)
bids <- filter(bids, bids$num_bids_received < 26)
bids$indic_0_bids <- ifelse(bids$num_bids_received == 0,1,0)
bids$indic_1_bids <- ifelse(bids$num_bids_received == 1,1,0)
bids$indic_2p_bids <- ifelse(bids$num_bids_received > 1,1,0)
bids$num_bids_category <- ifelse(bids$num_bids_received > 1,2,bids$num_bids_received)
bids$urban_indicator <- ifelse(bids$locale == 'Urban', 'true', 'false')
bids$suburban_indicator <- ifelse(bids$locale == 'Suburban', 'true', 'false')
bids$town_indicator <- ifelse(bids$locale == 'Town', 'true', 'false')
bids$rural_indicator <- ifelse(bids$locale == 'Rural', 'true', 'false')

##agg summary
bids_clean <- filter(bids, bids$exclude_from_ia_cost_analysis == 'false')
bids_clean <- filter(bids_clean, bids_clean$exclude_from_ia_analysis == 'false')
bids_clean <- filter(bids_clean, bids_clean$fiber_target_status != 'Potential Target')

groups_bids_clean <- group_by(bids_clean, fiber_target_status, locale, num_bids_category)
summary <- summarize(groups_bids_clean,
                     count = n(),
                     median_ia_monthly_cost_per_mbps = median(ia_monthly_cost_per_mbps, na.rm = T),
                     median_ia_bandwidth_per_student_kbps = median(ia_bandwidth_per_student_kbps, na.rm = T))
summary <-  summary %>% 
            arrange(fiber_target_status, locale, num_bids_category,median_ia_monthly_cost_per_mbps) %>% 
            mutate(rank_ia_monthly_cost_per_mbps = rank(median_ia_monthly_cost_per_mbps, ties.method = 'first'))
summary <-  summary %>% 
            arrange(fiber_target_status, locale, num_bids_category,median_ia_bandwidth_per_student_kbps) %>% 
            mutate(rank_ia_bandwidth_per_student_kbps = rank(median_ia_bandwidth_per_student_kbps, ties.method = 'first'))

write.csv(summary, file = "data/interim/summary.csv")

#agg state summary
bids_state <- filter(bids, bids$exclude_from_ia_cost_analysis == 'false')
bids_state <- filter(bids_state, bids_state$exclude_from_ia_analysis == 'false')
groups_bids_state <- group_by(bids_state, postal_cd, num_bids_category)
summary_state <- summarize(groups_bids_state,
                     count = n(),
                     median_ia_monthly_cost_per_mbps = median(ia_monthly_cost_per_mbps, na.rm = T),
                     median_ia_bandwidth_per_student_kbps = median(ia_bandwidth_per_student_kbps, na.rm = T))
summary_state <-  summary_state %>% 
  arrange(postal_cd, num_bids_category,median_ia_monthly_cost_per_mbps) %>% 
  mutate(rank_ia_monthly_cost_per_mbps = rank(median_ia_monthly_cost_per_mbps, ties.method = 'first'))
summary_state <-  summary_state %>% 
  arrange(postal_cd, num_bids_category,median_ia_bandwidth_per_student_kbps) %>% 
  mutate(rank_ia_bandwidth_per_student_kbps = rank(median_ia_bandwidth_per_student_kbps, ties.method = 'first'))

write.csv(summary_state, file = "data/interim/summary_state.csv")


##fiber target summary
fiber_target_groups_bids_clean <- group_by(bids_clean, fiber_target_status, num_bids_category)
fiber_target_summary <- summarize(fiber_target_groups_bids_clean,
                                  count = n(),
                                  median_ia_monthly_cost_per_mbps = median(ia_monthly_cost_per_mbps, na.rm = T),
                                  median_ia_bandwidth_per_student_kbps = median(ia_bandwidth_per_student_kbps, na.rm = T))
fiber_target_summary <- fiber_target_summary %>% 
                        arrange(fiber_target_status, num_bids_category,median_ia_monthly_cost_per_mbps) %>% 
                        mutate(rank_ia_monthly_cost_per_mbps = rank(median_ia_monthly_cost_per_mbps, ties.method = 'first'))
fiber_target_summary <- fiber_target_summary %>% 
                        arrange(fiber_target_status, num_bids_category,median_ia_bandwidth_per_student_kbps) %>% 
                        mutate(rank_ia_bandwidth_per_student_kbps = rank(median_ia_bandwidth_per_student_kbps, ties.method = 'first'))

write.csv(fiber_target_summary, file = "data/interim/fiber_target_summary.csv")
