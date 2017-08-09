## =========================================
##
## DEPLOY 2017 SERVICE PROVIDER METRICS TOOL
##
## =========================================

## Clearing memory
rm(list=ls())

print(Sys.time())

#setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/spmd_2017/")
#setwd("~/Documents/R_WORK/ficher/Projects_SotS_2017/spmd_2017/")

## load packages (if not already in the environment)
packages.to.install <- c("flexdashboard", "shiny", "dplyr", "highcharter", "rsconnect", "ggplot2", "DT",
                         "htmltools", "dotenv", "knitr", "rmarkdown", "DBI")
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
library(knitr)
library(rmarkdown)
library(DBI)

## source environment variables
source("../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## option to deploy the tool
deploy <- 1

## retrieve date (in order to accurately timestamp files)
actual.date <- Sys.time()
weekday <- weekdays(actual.date)
actual.date <- gsub("PST", "", actual.date)
actual.date <- gsub(" ", "_", actual.date)
actual.date <- gsub(":", ".", actual.date)

##**************************************************************************************************************************************************
## READ DATA

## SP Aggregation
sp_2017 <- read.csv("data/raw/sp_aggregation/2017_sp_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
sp_2016 <- read.csv("data/raw/sp_aggregation/2016_sp_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)

## Deluxe Districts
dd_2017 <- read.csv("data/raw/deluxe_districts/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016 <- read.csv("data/raw/deluxe_districts/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

## Date
date <- read.csv("data/raw/date.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

## make sure to include districts in universe
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE),]
dd_2016 <- dd_2016[which(dd_2016$include_in_universe_of_districts == TRUE),]

## also subset to Traditional districts
dd_2017 <- dd_2017[which(dd_2017$district_type == "Traditional"),]
dd_2016 <- dd_2016[which(dd_2016$district_type == "Traditional"),]

## take out NA SP
dd_2017 <- dd_2017[!is.na(dd_2017$service_provider_assignment),]
dd_2016 <- dd_2016[!is.na(dd_2016$service_provider_assignment),]
sp_2017 <- sp_2017[!is.na(sp_2017$service_provider_assignment),]
sp_2016 <- sp_2016[!is.na(sp_2016$service_provider_assignment),]

dd_2017 <- dd_2017[which(dd_2017$service_provider_assignment != ""),]
dd_2016 <- dd_2016[which(dd_2016$service_provider_assignment != ""),]
sp_2017 <- sp_2017[which(sp_2017$service_provider_assignment != ""),]
sp_2016 <- sp_2016[which(sp_2016$service_provider_assignment != ""),]

## only subset to Service Providers that overlap in both years
sp_2017 <- sp_2017[which(sp_2017$service_provider_assignment %in% sp_2016$service_provider_assignment),]
sp_2016 <- sp_2016[which(sp_2016$service_provider_assignment %in% sp_2017$service_provider_assignment),]

## rank by top sp's (50)
sp_2017 <- sp_2017[order(sp_2017$students_population, decreasing=T),]
sp_2017 <- sp_2017[1:50,]
sp_2016 <- sp_2016[which(sp_2016$service_provider_assignment %in% sp_2017$service_provider_assignment),]

## subset deluxe districts to the same service providers
dd_2016 <- dd_2016[which(dd_2016$service_provider_assignment %in% sp_2016$service_provider_assignment),]
dd_2017 <- dd_2017[which(dd_2017$service_provider_assignment %in% sp_2017$service_provider_assignment),]

##**************************************************************************************************************************************************
## SUBSET DATA

## CLEAN FOR IA (Click-Through)
##-------------------------------
## 2017
current17.click.through <- dd_2017[,c("esh_id", "name", 'service_provider_assignment', 'switcher', "postal_cd", "locale", "district_size", "district_type",
                                      "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip",
                                      "lines_w_dirty", names(dd_2017)[grepl("exclude", names(dd_2017))])]
current17.click.through$no_data <- ifelse(current17.click.through$lines_w_dirty == 0, TRUE, FALSE)
current17.click.through$lines_w_dirty <- NULL
## add in IRT links
current17.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", current17.click.through$esh_id, "'>",
                                          "http://irt.educationsuperhighway.org/entities/districts/", current17.click.through$esh_id, "</a>", sep='')
## order dataset
current17.click.through <- current17.click.through[order(current17.click.through$service_provider_assignment),]

## 2016
current16.click.through <- dd_2016[,c("esh_id", "name", 'service_provider_assignment', 'switcher', "postal_cd", "locale", "district_size", "district_type",
                                        "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip", "lines_w_dirty",
                                        names(dd_2016)[grepl("exclude", names(dd_2016))])]
current16.click.through$no_data <- ifelse(current16.click.through$lines_w_dirty == 0, TRUE, FALSE)
current16.click.through$lines_w_dirty <- NULL
## add in IRT links
current16.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", current16.click.through$esh_id, "'>",
                                       "http://irt.educationsuperhighway.org/entities/districts/", current16.click.through$esh_id, "</a>", sep='')
## order dataset
current16.click.through <- current16.click.through[order(current16.click.through$service_provider_assignment),]


## UPGRADES (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('service_provider_assignment', 'num_schools', 'num_campuses', 'num_students',
                             'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps', 'ia_monthly_cost_total',
                             'meeting_2014_goal_no_oversub', 'meeting_knapsack_affordability_target',
                             'non_fiber_internet_upstream_lines_w_dirty', 'ia_monthly_cost_per_mbps',
                             'fiber_internet_upstream_lines_w_dirty', 'most_recent_ia_contract_end_date')
## districts that are clean in both years
dd_2017_cl <- dd_2017[which(dd_2017$exclude_from_ia_analysis == FALSE),]
dd_2016_cl <- dd_2016[which(dd_2016$exclude_from_ia_analysis == FALSE),]
overlap.ids <- dd_2017_cl$esh_id[which(dd_2017_cl$esh_id %in% dd_2016_cl$esh_id)]

## 2017
upgrades.click.through <- dd_2017_cl[dd_2017_cl$esh_id %in% overlap.ids, c('esh_id', 'name', 'postal_cd', 'locale',
                                                                           'district_size', 'upgrade_indicator', 'switcher',
                                                                           cols.to.merge.each.year)]
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

## add in IRT links
upgrades.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", upgrades.click.through$esh_id, "'>",
                                             "http://irt.educationsuperhighway.org/entities/districts/", upgrades.click.through$esh_id, "</a>", sep='')
## Rearrange columns to pair key metrics (column order). columns repeat after
upgrades.click.through <- upgrades.click.through[,c('esh_id', 'name', 'switcher', 'service_provider_assignment_2016', 'service_provider_assignment_2017', 'postal_cd', 'locale','district_size', 'upgrade_indicator','num_schools_2017', 'num_campuses_2017', 'num_students_2017',
                                                   'ia_bw_mbps_total_2017','ia_bw_mbps_total_2016', 'diff_bw', 'ia_bandwidth_per_student_kbps_2017', 'ia_bandwidth_per_student_kbps_2016',
                                                   'ia_monthly_cost_per_mbps_2017','ia_monthly_cost_per_mbps_2016', 'ia_monthly_cost_total_2017',
                                                   'ia_monthly_cost_total_2016','meeting_2014_goal_no_oversub_2017', 'meeting_knapsack_affordability_target_2017',
                                                   'non_fiber_internet_upstream_lines_w_dirty_2017', 'fiber_internet_upstream_lines_w_dirty_2017', 'most_recent_ia_contract_end_date_2017',
                                                   'num_schools_2016', 'num_campuses_2016', 'num_students_2016', 
                                                   'meeting_2014_goal_no_oversub_2016', 'meeting_knapsack_affordability_target_2016','non_fiber_internet_upstream_lines_w_dirty_2016',
                                                   'fiber_internet_upstream_lines_w_dirty_2016', 'most_recent_ia_contract_end_date_2016', 'irt_link')]
                                                   
                                                   
                                                   
                                                   

## CONNECTIVITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('service_provider_assignment', 'ia_bandwidth_per_student_kbps', 'meeting_2014_goal_no_oversub', 'ia_bw_mbps_total',
                             'most_recent_ia_contract_end_date','ia_monthly_cost_per_mbps')
## 2017
connectivity.click.through <- dd_2017[,c('esh_id', 'switcher', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                         'num_students', cols.to.merge.each.year, 'bw_target_status', names(dd_2017)[grepl('exclude', names(dd_2017))])]
names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year], "2017", sep="_")

## 2016
connectivity.click.through <- merge(connectivity.click.through, dd_2016[,c('esh_id', cols.to.merge.each.year)], by='esh_id', all.x=T)
names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year] <- 
  paste(names(connectivity.click.through)[names(connectivity.click.through) %in% cols.to.merge.each.year], "2016", sep="_")

connectivity.click.through$diff_bw <- connectivity.click.through$ia_bw_mbps_total_2017 - connectivity.click.through$ia_bw_mbps_total_2016

## round cols
connectivity.click.through[grepl("ia_bandwidth_per_student_kbps", names(connectivity.click.through))] <- round(connectivity.click.through[grepl("ia_bandwidth_per_student_kbps", names(connectivity.click.through))], 0)
connectivity.click.through[grepl("ia_bw_mbps_total", names(connectivity.click.through))] <- round(connectivity.click.through[grepl("ia_bw_mbps_total", names(connectivity.click.through))], 0)
## add in IRT links
connectivity.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", connectivity.click.through$esh_id, "'>",
                                             "http://irt.educationsuperhighway.org/entities/districts/", connectivity.click.through$esh_id, "</a>", sep='')
## order the dataset by not meeting goals in 2016 to meeting goals in 2017
connectivity.click.through <- connectivity.click.through[order(connectivity.click.through$meeting_2014_goal_no_oversub_2016,
                                                               rev(connectivity.click.through$meeting_2014_goal_no_oversub_2017), decreasing=F),]
## Reordering Columns to put key metrics together
connectivity.click.through <- connectivity.click.through[c('esh_id', 'name', 'switcher', 'service_provider_assignment_2016', 'service_provider_assignment_2017',
                                                           'postal_cd', 'locale', 'district_size', 'num_schools',
                                                           'num_students', 'ia_bandwidth_per_student_kbps_2017',
                                                           'ia_bandwidth_per_student_kbps_2016', 
                                                           'ia_bw_mbps_total_2017','ia_bw_mbps_total_2016', 'diff_bw',
                                                           'meeting_2014_goal_no_oversub_2017', 
                                                           'most_recent_ia_contract_end_date_2017', 'meeting_2014_goal_no_oversub_2016',
                                                           'most_recent_ia_contract_end_date_2016','irt_link')]
                              

## FIBER (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('service_provider_assignment', 'most_recent_ia_contract_end_date','current_known_scalable_campuses',
                             'current_assumed_scalable_campuses',
                             'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses')
## 2017
fiber.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'switcher', 'num_campuses',
                                  'fiber_target_status', cols.to.merge.each.year,
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
fiber.click.through <- fiber.click.through[order(fiber.click.through$current_assumed_unscalable_campuses_2017, decreasing=T),]
## add in IRT links
fiber.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", fiber.click.through$esh_id, "'>",
                                      "http://irt.educationsuperhighway.org/entities/districts/", fiber.click.through$esh_id, "</a>", sep='')

## Reorder Columns to place key metrics side by side
fiber.click.through <- fiber.click.through[c("name", 'switcher', 'service_provider_assignment_2016',
                                             'service_provider_assignment_2017',
                                             'postal_cd', 'esh_id', 'num_campuses',
                                             'fiber_target_status',
                                             'most_recent_ia_contract_end_date_2017',
                                             'most_recent_ia_contract_end_date_2016',
                                             'current_known_scalable_campuses_2017',
                                             'current_assumed_scalable_campuses_2017',
                                             'current_assumed_unscalable_campuses_2017',
                                             'current_known_unscalable_campuses_2017',
                                             'current_known_scalable_campuses_2016',
                                             'current_assumed_scalable_campuses_2016',
                                             'current_assumed_unscalable_campuses_2016',
                                             'current_known_unscalable_campuses_2016',
                                            names(fiber.click.through)[grepl('exclude', names(fiber.click.through))],
                                            names(fiber.click.through)[grepl('flag', names(fiber.click.through))],
                                            names(fiber.click.through)[grepl('tag', names(fiber.click.through))])]

## AFFORDABILITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('service_provider_assignment',
                             'ia_monthly_cost_per_mbps', 'ia_bw_mbps_total',
                             'ia_monthly_cost_total', 'meeting_knapsack_affordability_target')
## 2017
affordability.click.through <- dd_2017[,c('postal_cd', 'switcher', 'esh_id', 'name', 'locale', 'district_size',
                                          'most_recent_ia_contract_end_date',
                                          'num_students', cols.to.merge.each.year)]
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
## Reorder Columns
affordability.click.through <- affordability.click.through[c('name', 'switcher', 'service_provider_assignment_2016',
                                                             'service_provider_assignment_2017',
                                                             'postal_cd', 'esh_id', 'locale', 'district_size',
                                                             'most_recent_ia_contract_end_date', 'num_students',
                                                             'meeting_knapsack_affordability_target_2017',
                                                             'meeting_knapsack_affordability_target_2016',
                                                             'ia_monthly_cost_per_mbps_2017', 'ia_monthly_cost_per_mbps_2016',
                                                             'ia_bw_mbps_total_2017', 'ia_bw_mbps_total_2016',
                                                             'ia_monthly_cost_total_2017', 'ia_monthly_cost_total_2016', 'irt_link')]

## WIFI (Click-Through)
##-------------------------------


## CONNECTIVITY (Targets)
##-------------------------------
cols.to.merge.each.year <- c('service_provider_assignment', 'most_recent_ia_contract_end_date')
## 2017
connectivity.targets <- dd_2017[which(dd_2017$bw_target_status == 'Target' | dd_2017$bw_target_status == 'Potential Target'),]
connectivity.targets <- connectivity.targets[,c('esh_id', 'name', 'switcher', 'postal_cd', 'locale', 'district_size', 'num_schools',
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
cols.to.merge.each.year <- c('service_provider_assignment', 'most_recent_ia_contract_end_date')

## 2017
## create an indicator for no data district
dd_2017$no_data <- ifelse(dd_2017$lines_w_dirty == 0, TRUE, FALSE)
## create number of circuits field
dd_2017$num_circuits <- dd_2017$non_fiber_lines + dd_2017$fiber_wan_lines + dd_2017$fiber_internet_upstream_lines
## create total number of unknown campuses field
dd_2017$total_unknown_campuses <- dd_2017$current_assumed_scalable_campuses + dd_2017$current_assumed_unscalable_campuses
fiber.targets <- dd_2017[which(dd_2017$fiber_target_status == 'Target' | dd_2017$fiber_target_status == 'Potential Target'),]
fiber.targets <- fiber.targets[,c('esh_id', 'name', 'switcher', 'postal_cd', 'locale', 'district_size',
                                  'num_students', 'num_campuses', 'num_circuits',
                                  cols.to.merge.each.year, 'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total',
                                  'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                  'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses',
                                  'total_unknown_campuses',
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

##**************************************************************************************************************************************************
## WRITE OUT DATA

## State Aggregation
write.csv(sp_2017, "tool/data/2017_sp_aggregation.csv", row.names=F)
write.csv(sp_2016, "tool/data/2016_sp_aggregation.csv", row.names=F)

## Deluxe Districts
write.csv(dd_2017, "tool/data/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "tool/data/2016_deluxe_districts.csv", row.names=F)

## Click-Throughs
write.csv(current17.click.through, "tool/data/current17_click_through.csv", row.names=F)
write.csv(current16.click.through, "tool/data/current16_click_through.csv", row.names=F)
write.csv(upgrades.click.through, "tool/data/upgrades_click_through.csv", row.names=F)
write.csv(connectivity.click.through, "tool/data/connectivity_click_through.csv", row.names=F)
write.csv(fiber.click.through, "tool/data/fiber_click_through.csv", row.names=F)
write.csv(affordability.click.through, "tool/data/affordability_click_through.csv", row.names=F)

## Targets
write.csv(connectivity.targets, "tool/data/connectivity_targets.csv", row.names=F)
write.csv(fiber.targets, "tool/data/fiber_targets.csv", row.names=F)

## Date
write.csv(date, "tool/data/date.csv", row.names=F)

##**************************************************************************************************************************************************
## DEPLOY TOOL

if (deploy == 1){
  options(repos=c(CRAN="https://cran.rstudio.com"))
  rsconnect::setAccountInfo(name=rstudio_name,
                            token=rstudio_token,
                            secret=rstudio_secret)
  rsconnect::deployDoc("tool/2017_Service_Provider_Metrics_Dashboard.Rmd")
}
