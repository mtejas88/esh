## =========================================
##
## DEPLOY 2017 STATE METRICS TOOL
##
## =========================================

## Clearing memory
rm(list=ls())

#setwd("~/Documents/ESH-Code/ficher/Projects/smd_2017/")

## load packages (if not already in the environment)
packages.to.install <- c("flexdashboard", "shiny", "dplyr", "highcharter", "rsconnect", "ggplot2", "DT", "htmltools", "dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(flexdashboard) # need to run compile this tool
library(shiny) # need for render functions
library(dplyr) # most of the code is written using dplyr functions ( e.g. %>% filter(), %>% summarise(), %>% select() )
library(highcharter) # need for highchart() vizes (eg. bar charts, box plots, scatter plots)
library(rsconnect) # need for supporting R markdown 
library(ggplot2) # for ggplot vizes (i.e. square colored box with status suchc as: 36 fiber targets) 
library(DT) # need for datatables
library(htmltools) # need for html use in code (I think)
library(dotenv)

apply_state_names <- function(dta){
  ## add state name to state aggregation
  dta$state_name <- state.name[match(dta$postal_cd, state.abb)]
  dta$state_name[dta$postal_cd == 'ALL'] <- 'National'
  return(dta)
}

## source function to create the following variables in DD:
## bundled_and_dedicated_isp_sp, most_recent_ia_contract_end_date
source("src/combine_sp.R")

## source environment variables
source("../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## option to deploy the tool
deploy <- 1

##**************************************************************************************************************************************************
## READ DATA

## State Aggregation
state_2017 <- read.csv("data/raw/2017_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
state_2016 <- read.csv("data/raw/2016_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
state_2016_froz <- read.csv("data/raw/2016_2015_frozen_state_aggregation_2017-01-13.csv", as.is=T, header=T, stringsAsFactors=F)
## Districts Deluxe
dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016 <- read.csv("data/raw/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016_froz <- read.csv("data/raw/2016_frozen_deluxe_districts_2017-01-13.csv", as.is=T, header=T, stringsAsFactors=F)
#dd_2015_froz <- read.csv("data/raw/2015_frozen_deluxe_districts_2017-01-13.csv", as.is=T, header=T, stringsAsFactors=F)
## Date
date <- read.csv("data/raw/date.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

## add state name to state aggregation
state_2016 <- apply_state_names(state_2016)
state_2017 <- apply_state_names(state_2017)

## make sure to include districts in universe
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE),]
dd_2016 <- dd_2016[which(dd_2016$include_in_universe_of_districts == TRUE),]
dd_2016_froz <- dd_2016_froz[which(dd_2016_froz$include_in_universe_of_districts == TRUE),]

## create sp indicators
dd_2017 <- combine.sp(dd_2017)
dd_2016 <- combine.sp(dd_2016)
dd_2016_froz <- combine.sp(dd_2016_froz)

##**************************************************************************************************************************************************
## SUBSET DATA

## CLEAN FOR IA (Click-Through)
##-------------------------------
## 2017
current17.click.through <- dd_2017[,c("esh_id", "postal_cd", "name", "locale", "district_size", "district_type",
                                                "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip",
                                                "lines_w_dirty", names(dd_2017)[grepl("exclude", names(dd_2017))])]
current17.click.through$no_data <- ifelse(current17.click.through$lines_w_dirty == 0, TRUE, FALSE)
current17.click.through$lines_w_dirty <- NULL
## add in IRT links
current17.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", current17.click.through$esh_id, "'>",
                                                    "http://irt.educationsuperhighway.org/entities/districts/", current17.click.through$esh_id, "</a>", sep='')
## order dataset
current17.click.through <- current17.click.through[order(current17.click.through$postal_cd),]

## 2016
sots16.click.through <- dd_2016_froz[,c("esh_id", "postal_cd", "name", "locale", "district_size", "district_type",
                                                "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip", "lines_w_dirty",
                                                names(dd_2016_froz)[grepl("exclude", names(dd_2016_froz))])]
sots16.click.through$no_data <- ifelse(sots16.click.through$lines_w_dirty == 0, TRUE, FALSE)
sots16.click.through$lines_w_dirty <- NULL
## add in IRT links
sots16.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", sots16.click.through$esh_id, "'>",
                                                    "http://irt.educationsuperhighway.org/entities/districts/", sots16.click.through$esh_id, "</a>", sep='')
## order dataset
sots16.click.through <- sots16.click.through[order(sots16.click.through$postal_cd),]


## UPGRADES (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('num_schools', 'num_campuses', 'num_students',
                             'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps', 'ia_monthly_cost_total',
                             'meeting_2014_goal_no_oversub', 'meeting_knapsack_affordability_target',
                             'non_fiber_internet_upstream_lines_w_dirty',
                             'fiber_internet_upstream_lines_w_dirty', 'bundled_and_dedicated_isp_sp',
                             'most_recent_ia_contract_end_date', 'num_internet_upstream_lines')
## districts that are clean in both years
dd_2017_cl <- dd_2017[which(dd_2017$exclude_from_ia_analysis == FALSE),]
dd_2016_cl <- dd_2016[which(dd_2016$exclude_from_ia_analysis == FALSE),]
overlap.ids <- dd_2017_cl$esh_id[which(dd_2017_cl$esh_id %in% dd_2016_cl$esh_id)]

## 2017
upgrades.click.through <- dd_2017_cl[dd_2017_cl$esh_id %in% overlap.ids, c('esh_id', 'name', 'postal_cd', 'locale',
                                                               'district_size', 'upgrade_indicator', cols.to.merge.each.year)]
names(upgrades.click.through)[names(upgrades.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(upgrades.click.through)[names(upgrades.click.through) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
upgrades.click.through <- merge(upgrades.click.through, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(upgrades.click.through)[names(upgrades.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(upgrades.click.through)[names(upgrades.click.through) %in% cols.to.merge.each.year], "2016", sep="_")

upgrades.click.through$diff_bw <- upgrades.click.through$ia_bw_mbps_total_2017 - upgrades.click.through$ia_bw_mbps_total_2016
## order the dataset
upgrades.click.through <- upgrades.click.through[order(upgrades.click.through$diff_bw, decreasing=T),]
## round cols
upgrades.click.through[grepl("ia_bw_mbps_total", names(upgrades.click.through))] <- round(upgrades.click.through[grepl("ia_bw_mbps_total", names(upgrades.click.through))], 0)
upgrades.click.through[grepl("ia_monthly_cost_total", names(upgrades.click.through))] <- round(upgrades.click.through[grepl("ia_monthly_cost_total", names(upgrades.click.through))], 2)
upgrades.click.through[grepl("ia_bandwidth_per_student_kbps", names(upgrades.click.through))] <- round(upgrades.click.through[grepl("ia_bandwidth_per_student_kbps", names(upgrades.click.through))], 0)


## CONNECTIVITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('ia_bandwidth_per_student_kbps', 'meeting_2014_goal_no_oversub', 'ia_bw_mbps_total',
                             'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')
## 2017
connectivity.click.through <- dd_2017[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                         'num_students', cols.to.merge.each.year, 'bw_target_status', names(dd_2017)[grepl('exclude', names(dd_2017))])]
names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
connectivity.click.through <- merge(connectivity.click.through, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year], "2016", sep="_")

## round cols
connectivity.click.through[grepl("ia_bandwidth_per_student_kbps", names(connectivity.click.through))] <- round(connectivity.click.through[grepl("ia_bandwidth_per_student_kbps", names(connectivity.click.through))], 0)
connectivity.click.through[grepl("ia_bw_mbps_total", names(connectivity.click.through))] <- round(connectivity.click.through[grepl("ia_bw_mbps_total", names(connectivity.click.through))], 0)
## add in IRT links
connectivity.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", connectivity.click.through$esh_id, "'>",
                                             "http://irt.educationsuperhighway.org/entities/districts/", connectivity.click.through$esh_id, "</a>", sep='')
## order the dataset by not meeting goals in 2016 to meeting goals in 2017
connectivity.click.through <- connectivity.click.through[order(connectivity.click.through$meeting_2014_goal_no_oversub_2016,
                                                               rev(connectivity.click.through$meeting_2014_goal_no_oversub_2017), decreasing=F),]


## FIBER (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')
## 2017
fiber.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'num_campuses',
                                  cols.to.merge.each.year, 'fiber_target_status',
                                  'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                  'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses',
                                  names(dd_2017)[grepl('exclude', names(dd_2017))],
                                  names(dd_2017)[grepl('flag', names(dd_2017))],
                                  names(dd_2017)[grepl('tag', names(dd_2017))])]
names(fiber.click.through)[names(fiber.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(fiber.click.through)[names(fiber.click.through) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
fiber.click.through <- merge(fiber.click.through, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(fiber.click.through)[names(fiber.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(fiber.click.through)[names(fiber.click.through) %in% cols.to.merge.each.year], "2016", sep="_")
## order the dataset
fiber.click.through <- fiber.click.through[order(fiber.click.through$current_assumed_unscalable_campuses, decreasing=T),]
## add in IRT links
fiber.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", fiber.click.through$esh_id, "'>",
                                      "http://irt.educationsuperhighway.org/entities/districts/", fiber.click.through$esh_id, "</a>", sep='')


## AFFORDABILITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total', 
                             'meeting_knapsack_affordability_target')
## 2017
affordability.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'locale', 'district_size',
                                           'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
                                           'num_internet_upstream_lines', 'num_students', cols.to.merge.each.year)]
names(affordability.click.through)[names(affordability.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(affordability.click.through)[names(affordability.click.through) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
affordability.click.through <- merge(affordability.click.through, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(affordability.click.through)[names(affordability.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(affordability.click.through)[names(affordability.click.through) %in% cols.to.merge.each.year], "2016", sep="_")

## round cols
affordability.click.through[grepl("ia_monthly_cost_per_mbps", names(affordability.click.through))] <- round(affordability.click.through[grepl("ia_monthly_cost_per_mbps", names(affordability.click.through))], 2)
affordability.click.through[grepl("ia_bw_mbps_total", names(affordability.click.through))] <- round(affordability.click.through[grepl("ia_bw_mbps_total", names(affordability.click.through))], 0)
affordability.click.through[grepl("ia_monthly_cost_total", names(affordability.click.through))] <- round(affordability.click.through[grepl("ia_monthly_cost_total", names(affordability.click.through))], 2)
## order the dataset
affordability.click.through <- affordability.click.through[order(affordability.click.through$ia_monthly_cost_per_mbps_2016, decreasing=T),]
## add in IRT links
affordability.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", affordability.click.through$esh_id, "'>",
                                              "http://irt.educationsuperhighway.org/entities/districts/", affordability.click.through$esh_id, "</a>", sep='')


## CONNECTIVITY (Targets)
##-------------------------------
cols.to.merge.each.year <- c('bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')
## 2017
connectivity.targets <- dd_2017[which(dd_2017$bw_target_status == 'Target' | dd_2017$bw_target_status == 'Potential Target'),]
connectivity.targets <- connectivity.targets[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                                cols.to.merge.each.year, 'num_students', 'ia_bandwidth_per_student_kbps',
                                                'ia_bw_mbps_total', 'ia_monthly_cost_total', 'bw_target_status',
                                                names(connectivity.targets)[grepl('exclude', names(connectivity.targets))])]
names(connectivity.targets)[names(connectivity.targets) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.targets)[names(connectivity.targets) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
connectivity.targets <- merge(connectivity.targets, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(connectivity.targets)[names(connectivity.targets) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.targets)[names(connectivity.targets) %in% cols.to.merge.each.year], "2016", sep="_")

## round cols
connectivity.targets[grepl("ia_monthly_cost_per_mbps", names(connectivity.targets))] <- round(connectivity.targets[grepl("ia_monthly_cost_per_mbps", names(connectivity.targets))], 2)
connectivity.targets[grepl("ia_bw_mbps_total", names(connectivity.targets))] <- round(connectivity.targets[grepl("ia_bw_mbps_total", names(connectivity.targets))], 0)
connectivity.targets[grepl("ia_bandwidth_per_student_kbps", names(connectivity.targets))] <- round(connectivity.targets[grepl("ia_bandwidth_per_student_kbps", names(connectivity.targets))], 0)
connectivity.targets[grepl("ia_monthly_cost_total", names(connectivity.targets))] <- round(connectivity.targets[grepl("ia_monthly_cost_total", names(connectivity.targets))], 2)
## order the dataset
connectivity.targets <- connectivity.targets[order(connectivity.targets$bw_target_status, decreasing=T),]
## add in IRT links
connectivity.targets$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", connectivity.targets$esh_id, "'>",
                                       "http://irt.educationsuperhighway.org/entities/districts/", connectivity.targets$esh_id, "</a>", sep='')


## FIBER (Targets)
##-------------------------------
cols.to.merge.each.year <- c('bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')

## 2017
## create an indicator for no data district
dd_2017$no_data <- ifelse(dd_2017$lines_w_dirty == 0, TRUE, FALSE)
## create number of circuits field
dd_2017$num_circuits <- dd_2017$non_fiber_lines + dd_2017$fiber_wan_lines + dd_2017$fiber_internet_upstream_lines
## create total number of unknown campuses field
dd_2017$total_unknown_campuses <- dd_2017$current_assumed_scalable_campuses + dd_2017$current_assumed_unscalable_campuses
fiber.targets <- dd_2017[which(dd_2017$fiber_target_status == 'Target' | dd_2017$fiber_target_status == 'Potential Target'),]
fiber.targets <- fiber.targets[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size',
                                                'num_students', 'num_campuses', 'num_circuits',
                                                cols.to.merge.each.year, 'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total',
                                                'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                                'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses', 'total_unknown_campuses',
                                                'fiber_target_status', 'no_data',
                                                names(fiber.targets)[grepl('exclude', names(fiber.targets))])]
names(fiber.targets)[names(fiber.targets) %in% cols.to.merge.each.year] <- 
  paste(names(fiber.targets)[names(fiber.targets) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
fiber.targets <- merge(fiber.targets, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(fiber.targets)[names(fiber.targets) %in% cols.to.merge.each.year] <- 
  paste(names(fiber.targets)[names(fiber.targets) %in% cols.to.merge.each.year], "2016", sep="_")

## round cols
fiber.targets[grepl("ia_bandwidth_per_student_kbps", names(fiber.targets))] <- round(fiber.targets[grepl("ia_bandwidth_per_student_kbps", names(fiber.targets))], 0)
fiber.targets[grepl("ia_bw_mbps_total", names(fiber.targets))] <- round(fiber.targets[grepl("ia_bw_mbps_total", names(fiber.targets))], 0)
fiber.targets[grepl("current_assumed_scalable", names(fiber.targets))] <- round(fiber.targets[grepl("current_assumed_scalable", names(fiber.targets))], 0)
fiber.targets[grepl("current_assumed_unscalable", names(fiber.targets))] <- round(fiber.targets[grepl("current_assumed_unscalable", names(fiber.targets))], 0)
## order the dataset
fiber.targets <- fiber.targets[order(fiber.targets$current_assumed_unscalable_campuses, decreasing=T),]
## add in IRT links
fiber.targets$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", fiber.targets$esh_id, "'>",
                                       "http://irt.educationsuperhighway.org/entities/districts/", fiber.targets$esh_id, "</a>", sep='')



##** STILL NEED TO CREATE SNAPSHOTS SUBSET ONCE THE VARIABLES TO INCLUDE ARE DECIDED ON **##
## SNAPSHOTS
##-------------------------------

##**************************************************************************************************************************************************
## WRITE OUT DATA

## state aggregation
write.csv(state_2017, "tool/data/2017_state_aggregation.csv", row.names=F)
write.csv(state_2016, "tool/data/2016_state_aggregation.csv",row.names=F)
write.csv(state_2016_froz, "tool/data/2016_2015_sots_state_aggregation.csv",row.names=F)
## deluxe districts
write.csv(dd_2017, "tool/data/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "tool/data/2016_deluxe_districts.csv", row.names=F)
write.csv(dd_2016_froz, "tool/data/2016_sots_deluxe_districts.csv", row.names=F)
## click-throughs
write.csv(current17.click.through, "tool/data/current17_click_through.csv", row.names=F)
write.csv(sots16.click.through, "tool/data/sots16_click_through.csv", row.names=F)
write.csv(upgrades.click.through, "tool/data/upgrades_click_through.csv", row.names=F)
write.csv(connectivity.click.through, "tool/data/connectivity_click_through.csv", row.names=F)
write.csv(fiber.click.through, "tool/data/fiber_click_through.csv", row.names=F)
write.csv(affordability.click.through, "tool/data/affordability_click_through.csv", row.names=F)
## targets
write.csv(connectivity.targets, "tool/data/connectivity_targets.csv", row.names=F)
write.csv(fiber.targets, "tool/data/fiber_targets.csv", row.names=F)
## snapshots
#write.csv(snapshots, "tool/data/snapshots.csv", row.names=F)
## Date
write.csv(date, "tool/data/date.csv", row.names=F)

##**************************************************************************************************************************************************
## DEPLOY TOOL

if (deploy == 1){
  options(repos=c(CRAN="https://cran.rstudio.com"))
  rsconnect::setAccountInfo(name=rstudio_name,
                            token=rstudio_token,
                            secret=rstudio_secret)
  rsconnect::deployDoc("tool/2017_State_Metrics_Dashboard.Rmd")
}
