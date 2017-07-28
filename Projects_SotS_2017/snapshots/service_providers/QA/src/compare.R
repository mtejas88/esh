## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/snapshots/service_providers/QA/")

##**************************************************************************************************************************************************
## READ DATA

## Districts Deluxe
dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv")

## Services Received
sr_2017 <- read.csv("data/raw/2017_services_received.csv")

## Dominant SP
sp_2017 <- read.csv("data/raw/2017_service_providers.csv")

## Top 5 SPs
top_2017 <- read.csv("data/raw/2017_top_5_sp.csv")

##**************************************************************************************************************************************************
## find the top SP's with students not meeting goals in each state

## create subset
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$district_type == 'Traditional'),]
## create indicator for clean districts
dd_2017$clean <- ifelse(dd_2017$exclude_from_ia_analysis == FALSE, 1, 0)
## create indicator for students not meeting goals for each district
dd_2017$not_meeting_goals <- ifelse(dd_2017$meeting_2014_goal_no_oversub == FALSE, 1, 0)
## merge in dominant sp
dd_2017 <- merge(dd_2017, sp_2017, by='esh_id', all.x=T)
## aggregate number of clean students served by dominant sp
sp_agg <- aggregate(dd_2017$num_students * dd_2017$not_meeting_goals * dd_2017$clean, by=list(dd_2017$service_provider_assignment, dd_2017$postal_cd), FUN=sum, na.rm=T)
names(sp_agg) <- c('service_provider', 'postal_cd', 'num_clean_students_not_meeting_goals')
## aggregate number of clean districts served by dominant sp
dd_2017$counter <- 1
sp_agg_districts_clean <- aggregate(dd_2017$counter * dd_2017$clean, by=list(dd_2017$service_provider_assignment, dd_2017$postal_cd), FUN=sum, na.rm=T)
names(sp_agg_districts_clean) <- c('service_provider', 'postal_cd', 'num_clean_districts_served')
## aggregate number of total districts served by dominant sp
sp_agg_districts <- aggregate(dd_2017$counter, by=list(dd_2017$service_provider_assignment, dd_2017$postal_cd), FUN=sum, na.rm=T)
names(sp_agg_districts) <- c('service_provider', 'postal_cd', 'num_total_districts_served')

## combine
dta_sp <- merge(sp_agg, sp_agg_districts_clean, by=c("service_provider", "postal_cd"), all=T)
dta_sp <- merge(dta_sp, sp_agg_districts, by=c("service_provider", "postal_cd"), all=T)

## order by decreasing number of students not meeting goals decreasing by state
dta_sp <- dta_sp[order(dta_sp$postal_cd),]

## for each state, take the top 5 SPs
states <- unique(dta_sp$postal_cd)
dta <- data.frame(matrix(NA, nrow=1, ncol=ncol(dta_sp)))
names(dta) <- names(dta_sp)
for (i in 1:length(states)){
  dta.sub <- dta_sp[dta_sp$postal_cd == states[i],]
  ## order decreasing by num_students_not_meeting_goals
  dta.sub <- dta.sub[order(dta.sub$num_clean_students_not_meeting_goals, decreasing=T),]
  ## grab all SPs where num_students_not_meeting_goals !=0 
  dta.sub <- dta.sub[which(dta.sub$num_clean_students_not_meeting_goals != 0),]
  dta.sub <- dta.sub[1:5,]
  dta <- rbind(dta, dta.sub)
}

## take out NAs
dta <- dta[which(!is.na(dta$service_provider)),]

## merge in the actual SP
combined <- merge(dta, top_2017, by.x=c('service_provider', 'postal_cd'), by.y=c('service_provider_assignment', 'postal_cd'), all=T)
combined$diff_num_students_not_meeting_goals <- combined$num_clean_students_not_meeting_goals - combined$num_students_not_meeting_clean
combined$diff_num_districts_served_clean <- combined$num_clean_districts_served - combined$num_districts_served_clean
#combined$diff_num_districts_served <- combined$num_total_districts_served - combined$num_districts_served_total
