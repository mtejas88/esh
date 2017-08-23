## =========================================
##
## DEPLOY 2017 STATE METRICS TOOL -- LIVE
##
## =========================================

## Clearing memory
rm(list=ls())

print(Sys.time())

#setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/smd_2017/")
#setwd("~/Documents/R_WORK/ficher/Projects_SotS_2017/smd_2017/")

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

## retrieve date (in order to accurately timestamp files)
actual.date <- Sys.time()
weekday <- weekdays(actual.date)
actual.date <- gsub("PST", "", actual.date)
actual.date <- gsub(" ", "_", actual.date)
actual.date <- gsub(":", ".", actual.date)

##**************************************************************************************************************************************************
## READ DATA

## State Aggregation
state_2017 <- read.csv("data/raw/state_aggregation/2017_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
state_2016 <- read.csv("data/raw/state_aggregation/2016_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
state_2016_froz <- read.csv("data/raw/frozen_files/2016_2015_frozen_state_aggregation_2017-01-13.csv", as.is=T, header=T, stringsAsFactors=F)
state_rural_small_town <- read.csv("data/raw/state_aggregation/2017_rural_small_town_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)

## Top Service Providers
top_sp <- read.csv("data/raw/top_service_providers.csv", as.is=T, header=T, stringsAsFactors=F)

## Districts Deluxe
dd_2017 <- read.csv("data/raw/deluxe_districts/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016 <- read.csv("data/raw/deluxe_districts/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016_froz <- read.csv("data/raw/frozen_files/2016_frozen_deluxe_districts_2017-01-13.csv", as.is=T, header=T, stringsAsFactors=F)

## Date
date <- read.csv("data/raw/date.csv", as.is=T, header=T, stringsAsFactors=F)

## Statie Info
#statie <- read.csv("../../General_Resources/datasets/statie_info_for_snaps_v1.csv", as.is=T, header=T, stringsAsFactors=F)
statie <- read.csv("../../General_Resources/datasets/statie_info_for_snaps_v2.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

## add state name to state aggregation
state_2016 <- apply_state_names(state_2016)
state_2017 <- apply_state_names(state_2017)

## rename rural/small town columns
state_rural_small_town$postal_cd.1 <- NULL
names(state_rural_small_town)[!names(state_rural_small_town)
                              %in% c('postal_cd', 'erate_money_no_voice_millions')] <- paste(names(state_rural_small_town)[!names(state_rural_small_town)
                                                                                                          %in% c('postal_cd', 'erate_money_no_voice_millions')],
                                                                                                          "rural_small_town", sep="_")
## merge in rural_small_town with state_agg
state_2017 <- merge(state_2017, state_rural_small_town, by='postal_cd', all.x=T)
names(state_2017)[names(state_2017) == 'erate_money_no_voice_millions'] <- 'erate_money_millions'

## merge in statie info for snapshots
state_2017 <- merge(state_2017, statie, by='postal_cd', all.x=T)

## make sure to include districts in universe
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE),]
dd_2016 <- dd_2016[which(dd_2016$include_in_universe_of_districts == TRUE),]
dd_2016_froz <- dd_2016_froz[which(dd_2016_froz$include_in_universe_of_districts == TRUE),]

## also subset to Traditional districts
dd_2017 <- dd_2017[which(dd_2017$district_type == "Traditional"),]
dd_2016 <- dd_2016[which(dd_2016$district_type == "Traditional"),]
dd_2016_froz <- dd_2016_froz[which(dd_2016_froz$district_type == "Traditional"),]

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
                             'non_fiber_internet_upstream_lines_w_dirty', 'ia_monthly_cost_per_mbps',
                             'fiber_internet_upstream_lines_w_dirty', 'bundled_and_dedicated_isp_sp',
                             'most_recent_ia_contract_end_date', 'num_internet_upstream_lines')
## districts that are clean in both years
dd_2017_cl <- dd_2017[which(dd_2017$exclude_from_ia_analysis == FALSE),]
dd_2016_cl <- dd_2016[which(dd_2016$exclude_from_ia_analysis == FALSE),]
overlap.ids <- dd_2017_cl$esh_id[which(dd_2017_cl$esh_id %in% dd_2016_cl$esh_id)]

## 2017
upgrades.click.through <- dd_2017_cl[dd_2017_cl$esh_id %in% overlap.ids, c('esh_id', 'name', 'postal_cd', 'locale',
                                                                           'district_size', 'upgrade_indicator','outlier_type', 'outlier_status', cols.to.merge.each.year)]
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
upgrades.click.through <- upgrades.click.through[c('esh_id', 'name', 'postal_cd', 'locale','district_size', 'upgrade_indicator','outlier_type', 'outlier_status','num_schools_2017', 'num_campuses_2017', 'num_students_2017',
                                                   'ia_bw_mbps_total_2017','ia_bw_mbps_total_2016', 'diff_bw', 'ia_bandwidth_per_student_kbps_2017', 'ia_bandwidth_per_student_kbps_2016',
                                                   'ia_monthly_cost_per_mbps_2017','ia_monthly_cost_per_mbps_2016', 'ia_monthly_cost_total_2017',
                                                   'ia_monthly_cost_total_2016','meeting_2014_goal_no_oversub_2017', 'meeting_knapsack_affordability_target_2017',
                                                   'non_fiber_internet_upstream_lines_w_dirty_2017', 'fiber_internet_upstream_lines_w_dirty_2017', 'bundled_and_dedicated_isp_sp_2017','most_recent_ia_contract_end_date_2017',
                                                   'num_internet_upstream_lines_2017','num_schools_2016', 'num_campuses_2016', 'num_students_2016', 
                                                   'meeting_2014_goal_no_oversub_2016', 'meeting_knapsack_affordability_target_2016','non_fiber_internet_upstream_lines_w_dirty_2016',
                                                   'fiber_internet_upstream_lines_w_dirty_2016', 'bundled_and_dedicated_isp_sp_2016',
                                                   'most_recent_ia_contract_end_date_2016', 'num_internet_upstream_lines_2016','irt_link' )]
                                                   
                                                   
                                                   
                                                   

## CONNECTIVITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('ia_bandwidth_per_student_kbps', 'meeting_2014_goal_no_oversub', 'ia_bw_mbps_total',
                             'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date','ia_monthly_cost_per_mbps')
## 2017
connectivity.click.through <- dd_2017[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                         'num_students','outlier_type', 'outlier_status', cols.to.merge.each.year, 'bw_target_status', names(dd_2017)[grepl('exclude', names(dd_2017))])]
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
connectivity.click.through <- connectivity.click.through[c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                 'num_students', 'outlier_type','outlier_status','ia_bandwidth_per_student_kbps_2017','ia_bandwidth_per_student_kbps_2016', 
                                 'ia_bw_mbps_total_2017','ia_bw_mbps_total_2016', 'diff_bw', 'meeting_2014_goal_no_oversub_2017', 
                                 'bundled_and_dedicated_isp_sp_2017', 'most_recent_ia_contract_end_date_2017', 
                                 'meeting_2014_goal_no_oversub_2016', 'bundled_and_dedicated_isp_sp_2016', 'most_recent_ia_contract_end_date_2016','irt_link')]
                                 

## FIBER (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date','current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                             'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses')
## 2017
fiber.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'num_campuses',
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
fiber.click.through <- fiber.click.through[c('postal_cd', 'esh_id', 'name', 'num_campuses',
  'fiber_target_status', 'bundled_and_dedicated_isp_sp_2017', 'bundled_and_dedicated_isp_sp_2016','most_recent_ia_contract_end_date_2017','most_recent_ia_contract_end_date_2016',
  'current_known_scalable_campuses_2017', 'current_assumed_scalable_campuses_2017',
  'current_assumed_unscalable_campuses_2017', 'current_known_unscalable_campuses_2017',
   'current_known_scalable_campuses_2016', 'current_assumed_scalable_campuses_2016',
  'current_assumed_unscalable_campuses_2016', 'current_known_unscalable_campuses_2016',
  names(fiber.click.through)[grepl('exclude', names(fiber.click.through))],
  names(fiber.click.through)[grepl('flag', names(fiber.click.through))],
  names(fiber.click.through)[grepl('tag', names(fiber.click.through))])]

## AFFORDABILITY (Click-Through)
##-------------------------------
cols.to.merge.each.year <- c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total', 
                             'meeting_knapsack_affordability_target')
## 2017
affordability.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'locale', 'district_size',
                                          'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
                                          'num_internet_upstream_lines', 'num_students','outlier_type', 'outlier_status', cols.to.merge.each.year)]
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
affordability.click.through <- affordability.click.through[c('postal_cd', 'esh_id', 'name', 'locale', 'district_size',
    'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
    'num_internet_upstream_lines', 'num_students','outlier_type', 'outlier_status','meeting_knapsack_affordability_target_2017', 'meeting_knapsack_affordability_target_2016',
    'ia_monthly_cost_per_mbps_2017', 'ia_monthly_cost_per_mbps_2016','ia_bw_mbps_total_2017', 'ia_bw_mbps_total_2016',
    'ia_monthly_cost_total_2017', 'ia_monthly_cost_total_2016', 'irt_link')]

## WIFI (Click-Through)
##-------------------------------
wifi.click.through <- dd_2017[,c('postal_cd', 'esh_id', 'name', 'locale', 'district_size','num_students','needs_wifi','c2_prediscount_remaining_17','c2_prediscount_remaining_16')]
#wifi.click.through <- select(dd_2017, postal_cd, esh_id, name, locale, district_size,num_students,needs_wifi,c2_prediscount_remaining_17,c2_prediscount_remaining_16,irt_link)
## order the dataset
wifi.click.through <- wifi.click.through[order(wifi.click.through$needs_wifi, decreasing=T),]
## round cols
wifi.click.through[grepl("c2_prediscount_remaining_17", names(wifi.click.through))] <- round(wifi.click.through[grepl("c2_prediscount_remaining_17", names(wifi.click.through))], 2)
wifi.click.through[grepl("c2_prediscount_remaining_16", names(wifi.click.through))] <- round(wifi.click.through[grepl("c2_prediscount_remaining_16", names(wifi.click.through))], 2)

## add in IRT links
wifi.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/entities/districts/", wifi.click.through$esh_id, "'>",
                                     "http://irt.educationsuperhighway.org/entities/districts/", wifi.click.through$esh_id, "</a>", sep='')

## CONNECTIVITY (Targets)
##-------------------------------
cols.to.merge.each.year <- c('bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')
## 2017
connectivity.targets <- dd_2017[which(dd_2017$bw_target_status == 'Target' | dd_2017$bw_target_status == 'Potential Target'),]
connectivity.targets <- connectivity.targets[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                                cols.to.merge.each.year, 'num_students','outlier_type', 'outlier_status', 'ia_bandwidth_per_student_kbps',
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



## SNAPSHOTS (MASTER METRICS)
##-------------------------------
## store state_2017 so we don't keep renames
state_2017_orig <- state_2017

## Connectivity Ranking (by percent of STUDENTS meeting BW goal)
## right now, ranking everyone with 100% as 1st and then anyone after as 9th, 10th, etc.
state_2017$connectivity_ranking <- NA
state_2017$students_meeting_2014_bw_goal_perc <- state_2017$students_meeting_2014_bw_goal / state_2017$students_clean_ia_sample
state_2017 <- state_2017[order(state_2017$students_meeting_2014_bw_goal_perc, decreasing=T),]
state_2017$connectivity_ranking[state_2017$students_meeting_2014_bw_goal_perc == 1] <- 1
state_2017$connectivity_ranking[state_2017$students_meeting_2014_bw_goal_perc != 1 & state_2017$postal_cd != 'ALL'] <-
  seq(length(state_2017$connectivity_ranking[state_2017$students_meeting_2014_bw_goal_perc == 1]) + 1,
      nrow(state_2017) - 1)
## reorder back
state_2017 <- state_2017[order(state_2017$postal_cd),]

## Connectivity Ranking (by percent of DISTRICTS meeting BW goal)
## right now, ranking everyone with 100% as 1st and then anyone after as 9th, 10th, etc.
state_2017$connectivity_ranking_districts <- NA
state_2017$districts_meeting_2014_bw_goal_perc <- state_2017$districts_meeting_2014_bw_goal / state_2017$districts_clean_ia_sample
state_2017 <- state_2017[order(state_2017$districts_meeting_2014_bw_goal_perc, decreasing=T),]
state_2017$connectivity_ranking_districts[state_2017$districts_meeting_2014_bw_goal_perc == 1] <- 1
state_2017$connectivity_ranking_districts[state_2017$districts_meeting_2014_bw_goal_perc != 1 & state_2017$postal_cd != 'ALL'] <-
  seq(length(state_2017$connectivity_ranking_districts[state_2017$districts_meeting_2014_bw_goal_perc == 1]) + 1,
      nrow(state_2017) - 1)
## reorder back
state_2017 <- state_2017[order(state_2017$postal_cd),]

## Affordability Ranking (by percent of STUDENTS meeting goal)
## right now, ranking everyone with 100% as 1st and then anyone after as 9th, 10th, etc.
state_2017$affordability_ranking <- NA
state_2017$students_meeting_affordability_perc <- state_2017$students_meeting_affordability / state_2017$students_clean_ia_cost_sample
state_2017 <- state_2017[order(state_2017$students_meeting_affordability_perc, decreasing=T),]
state_2017$affordability_ranking[state_2017$students_meeting_affordability_perc == 1] <- 1
state_2017$affordability_ranking[state_2017$students_meeting_affordability_perc != 1 & state_2017$postal_cd != 'ALL'] <-
  seq(length(state_2017$affordability_ranking[state_2017$students_meeting_affordability_perc == 1]) + 1,
      nrow(state_2017) - 1)
## reorder back
state_2017 <- state_2017[order(state_2017$postal_cd),]

## Affordability Ranking (by percent of DISTRICTS meeting goal)
## right now, ranking everyone with 100% as 1st and then anyone after as 9th, 10th, etc.
state_2017$affordability_ranking_districts <- NA
state_2017$districts_meeting_affordability_perc <- state_2017$districts_meeting_affordability / state_2017$districts_clean_ia_cost_sample
state_2017 <- state_2017[order(state_2017$districts_meeting_affordability_perc, decreasing=T),]
state_2017$affordability_ranking_districts[state_2017$districts_meeting_affordability_perc == 1] <- 1
state_2017$affordability_ranking_districts[state_2017$districts_meeting_affordability_perc != 1 & state_2017$postal_cd != 'ALL'] <-
  seq(length(state_2017$affordability_ranking_districts[state_2017$districts_meeting_affordability_perc == 1]) + 1,
      nrow(state_2017) - 1)
## reorder back
state_2017 <- state_2017[order(state_2017$postal_cd),]

## Fiber Ranking (by percent of CAMPUSES meeting goal)
## right now, ranking everyone with 100% as 1st and then anyone after as 9th, 10th, etc.
state_2017$fiber_ranking <- NA
state_2017$campuses_on_fiber_perc <- state_2017$scalable_campuses / state_2017$campuses_population
state_2017 <- state_2017[order(state_2017$campuses_on_fiber_perc, decreasing=T),]
state_2017$fiber_ranking[state_2017$campuses_on_fiber_perc == 1] <- 1
state_2017$fiber_ranking[state_2017$campuses_on_fiber_perc != 1 & state_2017$postal_cd != 'ALL'] <-
  seq(length(state_2017$fiber_ranking[state_2017$campuses_on_fiber_perc == 1]) + 1,
      nrow(state_2017) - 1)
## reorder back
state_2017 <- state_2017[order(state_2017$postal_cd),]

## Original Methodology: use extrapolated number for 2016 districts/students meeting bw goals in 2016 and take difference with extrapolated 2017
## merge in 2016 frozen data to 2017
state_2017 <- merge(state_2017, state_2016_froz[,c('postal_cd', 'current16_districts_mtg2014goal', 'current16_districts_sample',
                                                   'current16_districts_pop', 'current16_students_mtg2014goal', 'current16_students_sample',
                                                   'current16_students_pop')], by='postal_cd', all.x=T)
## districts
state_2017$districts_meeting_2014_bw_goal_2016_extrap_original_meth <- round((state_2017$current16_districts_mtg2014goal / state_2017$current16_districts_sample)
                                                                             * state_2017$current16_districts_pop, 0)
state_2017$districts_meeting_2014_bw_goal_2017_extrap_original_meth <- round((state_2017$districts_meeting_2014_bw_goal / state_2017$districts_clean_ia_sample)
                                                                             * state_2017$districts_population, 0)

## 2017 and 2016 Districts/Students Not Meeting Goal (Actual and Extrapolated)
state_2017$districts_not_meeting_2014_bw_goal_actual <- state_2017$districts_clean_ia_sample - state_2017$districts_meeting_2014_bw_goal
state_2017$districts_not_meeting_2014_bw_goal_extrap <- round((state_2017$districts_not_meeting_2014_bw_goal_actual / state_2017$districts_clean_ia_sample)
                                                              * state_2017$districts_population, 0)
state_2017$students_not_meeting_2014_bw_goal_actual <- state_2017$students_clean_ia_sample - state_2017$students_meeting_2014_bw_goal
state_2017$students_not_meeting_2014_bw_goal_extrap <- round((state_2017$students_not_meeting_2014_bw_goal_actual / state_2017$students_clean_ia_sample)
                                                             * state_2017$students_population, 0)

state_2017$districts_not_meeting_2014_bw_goal_2016_actual <- state_2017$current16_districts_sample - state_2017$current16_districts_mtg2014goal
state_2017$districts_not_meeting_2014_bw_goal_2016_extrap <- round((state_2017$districts_not_meeting_2014_bw_goal_2016_actual / state_2017$current16_districts_sample)
                                                                   * state_2017$current16_districts_pop, 0)
state_2017$students_not_meeting_2014_bw_goal_2016_actual <- state_2017$current16_students_sample - state_2017$current16_students_mtg2014goal
state_2017$students_not_meeting_2014_bw_goal_2016_extrap <- round((state_2017$students_not_meeting_2014_bw_goal_2016_actual / state_2017$current16_students_sample)
                                                                  * state_2017$current16_students_pop, 0)


## create extrapolated number of more students connected between 2016 and 2017
## students
state_2017$students_meeting_2014_bw_goal_2016_extrap_original_meth <- round((state_2017$current16_students_mtg2014goal / state_2017$current16_students_sample)
                                                                            * state_2017$current16_students_pop, 0)
state_2017$students_meeting_2014_bw_goal_2017_extrap_original_meth <- round((state_2017$students_meeting_2014_bw_goal / state_2017$students_clean_ia_sample)
                                                                            * state_2017$students_population, 0)
## calculate differences
state_2017$more_districts_connected_extrap_original_meth <- state_2017$districts_meeting_2014_bw_goal_2017_extrap_original_meth - state_2017$districts_meeting_2014_bw_goal_2016_extrap_original_meth
state_2017$more_students_connected_extrap_original_meth <- state_2017$students_meeting_2014_bw_goal_2017_extrap_original_meth - state_2017$students_meeting_2014_bw_goal_2016_extrap_original_meth

## Upgrade Methodology: how many had a bandwidth upgrade and went from not meeting to meeting goals
state_2017$more_students_connected_actual_upgrade_meth <- state_2017$students_upgraded_meeting_goals
state_2017$more_students_connected_extrap_upgrade_meth <- round((state_2017$students_upgraded_meeting_goals / state_2017$students_clean_upgrades_2016_not_meeting_sample)
                                                                * state_2017$students_not_meeting_2014_bw_goal_2016_extrap, 0)
state_2017$more_districts_connected_actual_upgrade_meth <- state_2017$districts_upgraded_meeting_goals
state_2017$more_districts_connected_extrap_upgrade_meth <- round((state_2017$districts_upgraded_meeting_goals / state_2017$districts_clean_upgrades_2016_not_meeting_sample)
                                                                 * state_2017$districts_not_meeting_2014_bw_goal_2016_extrap, 0)

## 2016 More Students/Districts Connected (From Frozen 2016 Snapshots)
state_2017 <- merge(state_2017, state_2016_froz[,c('postal_cd', 'num_students_meeting_connectivity_goal_extrap_2016',
                                                   'num_students_meeting_connectivity_goal_extrap_2015',
                                                   'current15_districts_mtg2014goal', 'current15_districts_sample', 'current15_districts_pop')],
                    by='postal_cd', all.x=T)
state_2017$more_students_connected_2016_snapshot <- state_2017$num_students_meeting_connectivity_goal_extrap_2016 -
  state_2017$num_students_meeting_connectivity_goal_extrap_2015
state_2017$more_students_connected_2016_snapshot <- ifelse(state_2017$more_students_connected_2016_snapshot < 0, 0, state_2017$more_students_connected_2016_snapshot)
state_2017$num_districts_meeting_connectivity_goal_extrap_2016 <- round((state_2017$current16_districts_mtg2014goal / state_2017$current16_districts_sample) * state_2017$current16_districts_pop, 0)
state_2017$num_districts_meeting_connectivity_goal_extrap_2015 <- round((state_2017$current15_districts_mtg2014goal / state_2017$current15_districts_sample) * state_2017$current15_districts_pop, 0)
state_2017$more_districts_connected_2016_snapshot <- state_2017$num_districts_meeting_connectivity_goal_extrap_2016 - state_2017$num_districts_meeting_connectivity_goal_extrap_2015
state_2017$more_districts_connected_2016_snapshot <- ifelse(state_2017$more_districts_connected_2016_snapshot < 0, 0, state_2017$more_districts_connected_2016_snapshot)

## 2017 Service Providers serving the most students not meeting goals
## number of SPs serving students not meeting goals
## aggregate by state
top_sp$counter <- 1
sp_state <- aggregate(top_sp$counter, by=list(top_sp$postal_cd), FUN=sum, na.rm=T)
names(sp_state) <- c('postal_cd', 'num_service_providers_w_students_not_meeting_goals')
## number of students not meeting goals served by SPs
## aggregate by state
sp_state_students <- aggregate(top_sp$num_students_not_meeting_clean, by=list(top_sp$postal_cd), FUN=sum, na.rm=T)
names(sp_state_students) <- c('postal_cd', 'num_students_not_meeting_goals_served_by_sp')
## merge in state_2017
state_2017 <- merge(state_2017, sp_state, by='postal_cd', all.x=T)
state_2017 <- merge(state_2017, sp_state_students, by='postal_cd', all.x=T)
## calculate percentage of students affected by all sp out of overall not meeting
state_2017$students_not_meeting_goals_served_by_sp_perc_actual_not_meeting <- round(state_2017$num_students_not_meeting_goals_served_by_sp / state_2017$students_not_meeting_2014_bw_goal_actual, 2)
## calculate percentage of students affected by all sp out of overall not meeting extrap
state_2017$students_not_meeting_goals_served_by_sp_perc_extrap_not_meeting <- round(state_2017$num_students_not_meeting_goals_served_by_sp / state_2017$students_not_meeting_2014_bw_goal_extrap, 2)

## number of SPs serving students not meeting goals (Top 5)
top_sp_sub <- top_sp[which(top_sp$r <= 5),]
## aggregate by state
sp_state <- aggregate(top_sp_sub$counter, by=list(top_sp_sub$postal_cd), FUN=sum, na.rm=T)
names(sp_state) <- c('postal_cd', 'num_service_providers_w_students_not_meeting_goals_top_5')
## number of students not meeting goals served by SPs
## aggregate by state
sp_state_students <- aggregate(top_sp_sub$num_students_not_meeting_clean, by=list(top_sp_sub$postal_cd), FUN=sum, na.rm=T)
names(sp_state_students) <- c('postal_cd', 'num_students_not_meeting_goals_served_by_sp_top_5')
## merge in state_2017
state_2017 <- merge(state_2017, sp_state, by='postal_cd', all.x=T)
state_2017 <- merge(state_2017, sp_state_students, by='postal_cd', all.x=T)

## 2017 Districts that Need Fiber (Extrapolated)
state_2017$district_fiber_targets_extrap <- round((state_2017$clean_district_bw_targets / state_2017$districts_clean_ia_sample)
                                                  * state_2017$districts_population, 0)
## 2017 Campuses on Fiber
names(state_2017)[names(state_2017) == 'scalable_campuses'] <- 'total_schools_on_fiber'
state_2017$total_schools_on_fiber <- round(state_2017$total_schools_on_fiber, 0)
## 2017 Campuses not on Fiber
names(state_2017)[names(state_2017) == 'unscalable_campuses'] <- 'total_schools_not_on_fiber'
state_2017$total_schools_not_on_fiber <- round(state_2017$total_schools_not_on_fiber, 0)
## just Rural / Small Town
names(state_2017)[names(state_2017) == 'unscalable_campuses_rural_small_town'] <- 'schools_not_on_fiber_rural_small_town'
state_2017$schools_not_on_fiber_rural_small_town <- round(state_2017$schools_not_on_fiber_rural_small_town, 0)
state_2017$schools_not_on_fiber_rural_small_town_perc <- round(state_2017$schools_not_on_fiber_rural_small_town / state_2017$total_schools_not_on_fiber, 2)
## override if schools not on fiber is less < 10
state_2017$schools_not_on_fiber_rural_small_town_perc <- ifelse(state_2017$total_schools_not_on_fiber <= 10, NA, state_2017$schools_not_on_fiber_rural_small_town_perc)

## 2017 Districts Not Meeting Affordability Goals (Actual and Extrapolated)
state_2017$districts_not_meeting_affordability <- state_2017$districts_clean_ia_cost_sample - state_2017$districts_meeting_affordability

## rename students meeting goal
names(state_2017)[names(state_2017) == 'students_meeting_2014_bw_goal'] <- 'students_meeting_2014_bw_goal_actual'
names(state_2017)[names(state_2017) == 'districts_meeting_2014_bw_goal'] <- 'districts_meeting_2014_bw_goal_actual'

## calculate Mega and Large clean percent
state_2017$mega_large_clean_perc <- round(state_2017$mega_large_clean_ia_sample / state_2017$mega_large_population, 2)

## percent clean districts
state_2017$districts_clean_ia_sample_perc <- round(state_2017$districts_clean_ia_sample / state_2017$districts_population, 2)

## round c2 to nearest million
state_2017$c2_budget_2015 <- round(state_2017$c2_budget_2015 / 1000000, 1)
state_2017$c2_remaining_2017 <- round(state_2017$c2_remaining_2017 / 1000000, 1)

## placeholder columns
state_2017$gov_pic <- NA
state_2017$state_outline_image <- NA

## order the columns: state abbr, state name, connectivity rank, e-rate $, state match $, more students connected, more districts connected,
## current num districts connected, current num students connected, students still not meeting goals, districts still not meeting goals,
## number of service providers to partner with, number of students affected by sp, number of districts that need fiber, % in rural and small towns,
## wifi funds remaining, number of districts who still have wifi funds, number of districts not meeting affordability goals
snapshots <- state_2017[state_2017$postal_cd != 'ALL',c('postal_cd', 'state_name', 'connectivity_ranking', 'erate_money_millions',
                                                        'state_action_or_state_match', 'gov_pic', 'gov_quote', 'gov_last_name',
                                                        'state_outline_image', 'more_students_connected_2016_snapshot', 'more_districts_connected_2016_snapshot',
                                                        'more_students_connected_extrap_original_meth', 'more_districts_connected_extrap_original_meth',
                                                        'more_students_connected_extrap_upgrade_meth', 'more_districts_connected_extrap_upgrade_meth',
                                                        'more_students_connected_actual_upgrade_meth', 'more_districts_connected_actual_upgrade_meth',
                                                        'students_meeting_2014_bw_goal_actual', 'students_meeting_2014_bw_goal_2017_extrap_original_meth',
                                                        'students_meeting_2014_bw_goal_2016_extrap_original_meth',
                                                        'districts_meeting_2014_bw_goal_actual', 'districts_meeting_2014_bw_goal_2017_extrap_original_meth',
                                                        'districts_meeting_2014_bw_goal_2016_extrap_original_meth',
                                                        'students_not_meeting_2014_bw_goal_actual', 'students_not_meeting_2014_bw_goal_extrap',
                                                        'districts_not_meeting_2014_bw_goal_actual', 'districts_not_meeting_2014_bw_goal_extrap',
                                                        'num_service_providers_w_students_not_meeting_goals_top_5', 'num_students_not_meeting_goals_served_by_sp_top_5',
                                                        'total_schools_on_fiber', 'total_schools_not_on_fiber', 'schools_not_on_fiber_rural_small_town_perc',
                                                        'c2_budget_2015', 'c2_remaining_2017', 'num_districts_c2_remaining',
                                                        'districts_meeting_affordability', 'districts_not_meeting_affordability',
                                                        'districts_clean_ia_sample', 'districts_population',
                                                        'schools_clean_ia_sample', 'schools_population',
                                                        'campuses_clean_ia_sample', 'campuses_population',
                                                        'students_clean_ia_sample', 'students_population',
                                                        'districts_clean_ia_sample_perc', 'mega_large_clean_perc')]

## add commas for numbers over 1,000
## grab only numeric columns
nums <- sapply(snapshots, is.numeric)
cols <- names(snapshots)[nums]

## for each numeric column, when any total is >= 1,000, format with commas
for (col in cols){
  if (length(which(snapshots[,col]  > 1000)) > 0){
    snapshots[,col] <- format(snapshots[,col], big.mark = ",", nsmall = 0, scientific = FALSE)
  }
}

## subset to just state rankings
state_rankings <- state_2017[state_2017$postal_cd != 'ALL',c('postal_cd', 'state_name', 'connectivity_ranking', 'students_meeting_2014_bw_goal_perc',
                                                             'connectivity_ranking_districts', 'districts_meeting_2014_bw_goal_perc',
                                                             'affordability_ranking', 'students_meeting_affordability_perc',
                                                             'affordability_ranking_districts', 'districts_meeting_affordability_perc',
                                                             'fiber_ranking', 'campuses_on_fiber_perc')]

##**************************************************************************************************************************************************
## WRITE OUT DATA

## State Aggregation
write.csv(state_2017_orig, "tool/data/2017_state_aggregation.csv", row.names=F)
write.csv(state_2016, "tool/data/2016_state_aggregation.csv",row.names=F)
write.csv(state_2016_froz, "tool/data/2016_2015_sots_state_aggregation.csv",row.names=F)

## Deluxe Districts
write.csv(dd_2017, "tool/data/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "tool/data/2016_deluxe_districts.csv", row.names=F)
write.csv(dd_2016_froz, "tool/data/2016_sots_deluxe_districts.csv", row.names=F)

## Click-Throughs
write.csv(current17.click.through, "tool/data/current17_click_through.csv", row.names=F)
write.csv(sots16.click.through, "tool/data/sots16_click_through.csv", row.names=F)
write.csv(upgrades.click.through, "tool/data/upgrades_click_through.csv", row.names=F)
write.csv(connectivity.click.through, "tool/data/connectivity_click_through.csv", row.names=F)
write.csv(fiber.click.through, "tool/data/fiber_click_through.csv", row.names=F)
write.csv(affordability.click.through, "tool/data/affordability_click_through.csv", row.names=F)
write.csv(wifi.click.through, "tool/data/wifi_click_through.csv", row.names=F)

## Targets
write.csv(connectivity.targets, "tool/data/connectivity_targets.csv", row.names=F)
write.csv(fiber.targets, "tool/data/fiber_targets.csv", row.names=F)

## Snapshots
write.csv(snapshots, "tool/data/snapshots.csv", row.names=F)

## State Rankings
write.csv(state_rankings, "data/raw/state_rankings_live.csv")

## Date
write.csv(date, "tool/data/date.csv", row.names=F)

##**************************************************************************************************************************************************
## DEPLOY TOOL

if (deploy == 1){
  options(repos=c(CRAN="https://cran.rstudio.com"))
  rsconnect::setAccountInfo(name=rstudio_name,
                            token=rstudio_token,
                            secret=rstudio_secret)
  rsconnect::deployDoc("tool_live/2017_Live_State_Metrics_Dashboard.Rmd")
}
