## ==============================================================================================================================
##
## SERVICE PROVIDER ANALYSIS
##
## STUDENTS MEETING GOALS IF ALL SERVICE PROVIDERS CONNECTED STUDENTS NOT MEETING GOALS
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

## set the current directory as the working directory
wd <- setwd(".")
setwd(wd)
#setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Org-wide Projects/Progress Tracking/MASTER_MASTER/code/")

##**************************************************************************************************************************************************
## READ IN FILES

## service providers
sp.2016 <- read.csv("../data/2016_service_providers_to_districts.csv", as.is=T, header=T, stringsAsFactors=F)
sp.2016.all <- read.csv("../data/2016_service_providers_to_districts_all.csv", as.is=T, header=T, stringsAsFactors=F)

## Deluxe Districts files
dd.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/deluxe_districts/"
dd.files <- list.files(dd.directory)
dd.2016.files <- dd.files[grepl("2016-districts-deluxe", dd.files)]
## read in deluxe districts
dd.2016 <- read.csv(paste(dd.directory, dd.2016.files[length(dd.2016.files)], sep=''), as.is=T, header=T, stringsAsFactors=FALSE)

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## create subset of districts without a dominant service provider
districts.with.dom <- unique(sp.2016.all$esh_id[sp.2016.all$predominant_sp_2016 == TRUE])
sub <- dd.2016[which(!dd.2016$esh_id %in% districts.with.dom),]
sub$district_meeting_connectivity <- ifelse(((sub$ia_bw_mbps_total * 1000) / sub$num_students) >= 100, 1, 0)
sub$district_not_meeting_connectivity <- ifelse(sub$district_meeting_connectivity == 0, 1, 0)

sp.2016 <- merge(sp.2016, dd.2016, by='esh_id', all.x=T)
sp.2016 <- sp.2016[which(!is.na(sp.2016$esh_id)),]
sp.2016.all <- merge(sp.2016.all, dd.2016, by='esh_id', all.x=T)
sp.2016.all <- sp.2016.all[which(!is.na(sp.2016.all$esh_id)),]
## take out the charter districts
sp.2016 <- sp.2016[sp.2016$district_type == 'Traditional',]
sp.2016.all <- sp.2016.all[sp.2016.all$district_type == 'Traditional',]
## subset to only dominant service provider
sp.2016 <- sp.2016[sp.2016$predominant_sp_2016 == TRUE,]
sp.2016.all <- sp.2016.all[sp.2016.all$predominant_sp_2016 == TRUE,]
## also take out the service providers who provide both Upstream and Internet
#sp.2016 <- sp.2016[which(!sp.2016$purpose_2016 %in% c('Internet, Upstream', 'Upstream, Internet')),]

## create a binary indicator if a service provider is solely allowing a district to meet connectivity goals
sp.2016$sp_bw_per_student <- (sp.2016$bandwidth_in_mbps_2016 * 1000) / sp.2016$num_students
sp.2016$sp_meeting_goals_2014 <- ifelse(sp.2016$sp_bw_per_student >= 100, 1, 0)
sp.2016$sp_not_meeting_goals_2014 <- ifelse(sp.2016$sp_meeting_goals_2014 == 0, 1, 0)

sp.2016.all$sp_bw_per_student <- (sp.2016.all$bandwidth_in_mbps_2016 * 1000) / sp.2016.all$num_students
sp.2016.all$sp_meeting_goals_2014 <- ifelse(sp.2016.all$sp_bw_per_student >= 100, 1, 0)
sp.2016.all$sp_not_meeting_goals_2014 <- ifelse(sp.2016.all$sp_meeting_goals_2014 == 0, 1, 0)

## create a binary indicator if a full district is solely allowing a district to meet connectivity goals
sp.2016$district_bw_per_student <- (sp.2016$ia_bw_mbps_total * 1000) / sp.2016$num_students
sp.2016$district_meeting_goals_2014 <- ifelse(sp.2016$district_bw_per_student >= 100, 1, 0)
sp.2016$district_not_meeting_goals_2014 <- ifelse(sp.2016$district_meeting_goals_2014 == 0, 1, 0)

sp.2016.all$district_bw_per_student <- (sp.2016.all$ia_bw_mbps_total * 1000) / sp.2016.all$num_students
sp.2016.all$district_meeting_goals_2014 <- ifelse(sp.2016.all$district_bw_per_student >= 100, 1, 0)
sp.2016.all$district_not_meeting_goals_2014 <- ifelse(sp.2016.all$district_meeting_goals_2014 == 0, 1, 0)

##**************************************************************************************************************************************************

## calculate the top service providers that are not meeting goals

## aggregate by service provider -- total number of districts served
sp.2016$counter <- 1
sp.agg.districts <- aggregate(sp.2016$counter, by=list(sp.2016$service_provider_2016), FUN=sum, na.rm=T)
names(sp.agg.districts) <- c('service_provider', 'num_districts_served')

## subset only to the districts not meeting goals
sp.2016.not.meeting <- sp.2016[sp.2016$district_meeting_goals_2014 == 0,]
## take out the 78 districts that say the service provider is meeting even though the district is not
sp.2016.not.meeting.sp.meeting <- sp.2016.not.meeting[sp.2016.not.meeting$sp_meeting_goals_2014 == 1,]
sp.2016.not.meeting <- sp.2016.not.meeting[sp.2016.not.meeting$sp_meeting_goals_2014 == 0,]
## aggregate by service provider -- number of students not meeting goals
sp.agg.students.not <- aggregate(sp.2016.not.meeting$district_not_meeting_goals_2014*sp.2016.not.meeting$num_students,
                                 by=list(sp.2016.not.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(sp.agg.students.not) <- c('service_provider', 'num_students_not_meeting_goal')
sp.agg.students.not.sp.meeting <- aggregate(sp.2016.not.meeting.sp.meeting$district_not_meeting_goals_2014*sp.2016.not.meeting.sp.meeting$num_students,
                                            by=list(sp.2016.not.meeting.sp.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(sp.agg.students.not.sp.meeting) <- c('service_provider', 'num_students_not_meeting_goal_but_sp_meeting_goal')

## subset to the districts meeting goals
sp.2016.meeting <- sp.2016[sp.2016$district_meeting_goals_2014 == 1,]
## aggregate by service provider -- number of students meeting goals
sp.agg.students <- aggregate(sp.2016.meeting$district_meeting_goals_2014*sp.2016.meeting$num_students,
                             by=list(sp.2016.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(sp.agg.students) <- c('service_provider', 'num_students_meeting_goal')

## subset to dirty districts
dirty.districts <- sp.2016.all[which(sp.2016.all$exclude_from_ia_analysis.x == TRUE),]
## aggregate by service provider the number of students in dirty districts
sp.agg.students.dirty <- aggregate(dirty.districts$num_students, by=list(dirty.districts$service_provider_2016), FUN=sum, na.rm=T)
names(sp.agg.students.dirty) <- c('service_provider', 'num_students_dirty')

## merge
dta.sp <- merge(sp.agg.students.not, sp.agg.students, by='service_provider', all=T)
dta.sp <- merge(dta.sp, sp.agg.students.not.sp.meeting, by='service_provider', all=T)
dta.sp <- merge(dta.sp, sp.agg.districts, by='service_provider', all=T)
dta.sp <- merge(dta.sp, sp.agg.students.dirty, by='service_provider', all=T)

## sub NAs for 0 for students not meeting/meeting the goal
dta.sp$num_students_not_meeting_goal[which(is.na(dta.sp$num_students_not_meeting_goal))] <- 0
dta.sp$num_students_meeting_goal[which(is.na(dta.sp$num_students_meeting_goal))] <- 0
dta.sp$num_students_not_meeting_goal_but_sp_meeting_goal[which(is.na(dta.sp$num_students_not_meeting_goal_but_sp_meeting_goal))] <- 0
dta.sp$num_students_dirty[which(is.na(dta.sp$num_students_dirty))] <- 0

## add percentage of students not meeting/meeting the goal out of the total number of students in the nation
dta.sp$percentage_students_not_meeting_goal_nationally <- dta.sp$num_students_not_meeting_goal / sum(dta.sp$num_students_not_meeting_goal, na.rm=T)
dta.sp$percentage_students_meeting_goal_nationally <- dta.sp$num_students_meeting_goal / sum(dta.sp$num_students_meeting_goal, na.rm=T)
## add percentage of students not meeting/meeting goal of all students served
dta.sp$percentage_students_not_meeting_goal_of_all_served <- dta.sp$num_students_not_meeting_goal / (dta.sp$num_students_meeting_goal + dta.sp$num_students_not_meeting_goal)
dta.sp$percentage_students_meeting_goal_of_all_served <- dta.sp$num_students_meeting_goal / (dta.sp$num_students_meeting_goal + dta.sp$num_students_not_meeting_goal)

## order by decreasing number of students not meeting goal
dta.sp <- dta.sp[order(dta.sp$num_students_not_meeting_goal, decreasing=T),]

## EXTRAPOLATE
## extrapolate by applying the percentage of students not meeting goal to the number of students in the dirty districts
dta.sp$extrapolated_additional_students_not_meeting <- round(dta.sp$percentage_students_not_meeting_goal_of_all_served * dta.sp$num_students_dirty, 0)
dta.sp$extrapolated_additional_students_not_meeting[which(is.nan(dta.sp$extrapolated_additional_students_not_meeting))] <- 0
dta.sp$extrapolated_num_students_not_meeting_goal <- dta.sp$extrapolated_additional_students_not_meeting + dta.sp$num_students_not_meeting_goal
sum(dta.sp$extrapolated_num_students_not_meeting_goal) + sum(sub$num_students[sub$district_not_meeting_connectivity == 1], na.rm=T)

## extrapolate by applying the percentage of students meeting goal to the number of students in the dirty districts
dta.sp$extrapolated_additional_students_meeting <- round(dta.sp$percentage_students_meeting_goal_of_all_served * dta.sp$num_students_dirty, 0)
dta.sp$extrapolated_additional_students_meeting[which(is.nan(dta.sp$extrapolated_additional_students_meeting))] <- 0
dta.sp$extrapolated_num_students_meeting_goal <- dta.sp$extrapolated_additional_students_meeting + dta.sp$num_students_meeting_goal
sum(dta.sp$extrapolated_num_students_meeting_goal) +  sum(sub$num_students[sub$district_meeting_connectivity == 1], na.rm=T)

## old extrapolation: apply the percentage not meeting 
#dta.sp$extrapolated_num_students_not_meeting_goal <- round(dta.sp$percentage_students_not_meeting_goal_nationally * 11534180, digits=-4)
#dta.sp$extrapolated_num_students_meeting_goal <- round(dta.sp$percentage_students_meeting_goal_nationally * 34936580, digits=-4)
#dta.sp$extrapolated_num_students_not_meeting_goal <- format(dta.sp$extrapolated_num_students_not_meeting_goal, big.mark = ",", nsmall = 0, scientific = FALSE)
#dta.sp$extrapolated_num_students_meeting_goal <- format(dta.sp$extrapolated_num_students_meeting_goal, big.mark = ",", nsmall = 0, scientific = FALSE)

## calculate the percentage
dta.sp$extrapolated_percentage <- dta.sp$extrapolated_num_students_not_meeting_goal / (dta.sp$extrapolated_num_students_not_meeting_goal + dta.sp$extrapolated_num_students_meeting_goal)
dta.sp$extrapolated_percentage <- round(dta.sp$extrapolated_percentage*100, 0)

## reformat the columns
dta.sp$percentage_students_not_meeting_goal_nationally <- round(dta.sp$percentage_students_not_meeting_goal_nationally*100, 0)
dta.sp$percentage_students_meeting_goal_nationally <- round(dta.sp$percentage_students_meeting_goal_nationally*100, 0)
dta.sp$percentage_students_not_meeting_goal_of_all_served <- round(dta.sp$percentage_students_not_meeting_goal_of_all_served*100, 0)
dta.sp$percentage_students_meeting_goal_of_all_served <- round(dta.sp$percentage_students_meeting_goal_of_all_served*100, 0)

## take out "NC Office" and "State Replacement"
not.real.service.providers <- c('NC Office', 'State Replacement ', 'OneNet', 'OneNet ')
dta.sp <- dta.sp[!dta.sp$service_provider %in% not.real.service.providers,]

dta.sp.publish <- dta.sp[,c('service_provider', 'extrapolated_num_students_not_meeting_goal', 'extrapolated_num_students_meeting_goal', 'extrapolated_percentage')]

## number of service providers who have 100% of their schools meeting goals
## 544
nrow(dta.sp[which(dta.sp$percentage_students_meeting_goal_of_all_served == 100),])
## 61%
round(nrow(dta.sp[which(dta.sp$percentage_students_meeting_goal_of_all_served == 100),]) / nrow(dta.sp), 2)


## add a few more columns to the data:
## number of districts not meeting goals
agg.districts.not.meeting <- aggregate(sp.2016$district_not_meeting_goals_2014, by=list(sp.2016$service_provider_2016), FUN=sum, na.rm=T)
names(agg.districts.not.meeting) <- c('service_provider', 'number_districts_not_meeting_goals')
dta.sp <- merge(dta.sp, agg.districts.not.meeting, by='service_provider', all.x=T)

## calculate total BW needed to get them to goal meeting status
sp.2016.not.meeting$total_bw_needed_to_make_meeting_mbps <- (sp.2016.not.meeting$num_students*100) - (sp.2016.not.meeting$ia_bw_mbps_total*1000)
## make mbps
sp.2016.not.meeting$total_bw_needed_to_make_meeting_mbps <- sp.2016.not.meeting$total_bw_needed_to_make_meeting_mbps/1000
## aggregate bw needed when not meeting goals
agg.bw.needed <- aggregate(sp.2016.not.meeting$total_bw_needed_to_make_meeting_mbps, by=list(sp.2016.not.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(agg.bw.needed) <- c('service_provider', 'total_bw_needed_to_make_meeting_goals_mbps')
dta.sp <- merge(dta.sp, agg.bw.needed, by='service_provider', all.x=T)

## aggregate bw needed when not meeting goals -- mean
agg.bw.needed.mean <- aggregate(sp.2016.not.meeting$total_bw_needed_to_make_meeting_mbps,
                                by=list(sp.2016.not.meeting$service_provider_2016), FUN=mean, na.rm=T)
names(agg.bw.needed.mean) <- c('service_provider', 'mean_bw_needed_to_make_meeting_goals_mbps')
dta.sp <- merge(dta.sp, agg.bw.needed.mean, by='service_provider', all.x=T)

## weighted average cost/mbps for meeting and not meeting goals and overall
## Meeting
agg.total.mrc.meeting <- aggregate(sp.2016.meeting$total_monthly_cost_2016, by=list(sp.2016.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.mrc.meeting) <- c('service_provider', 'total_mrc')
agg.total.bw.meeting <- aggregate(sp.2016.meeting$bandwidth_in_mbps_2016, by=list(sp.2016.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.bw.meeting) <- c('service_provider', 'total_bw')
agg.weighted.avg.cost.mbps.meeting <- merge(agg.total.mrc.meeting, agg.total.bw.meeting, by='service_provider', all=T)
agg.weighted.avg.cost.mbps.meeting$weighted_avg_cost_per_mbps_meeting_goals <- agg.weighted.avg.cost.mbps.meeting$total_mrc / agg.weighted.avg.cost.mbps.meeting$total_bw
dta.sp <- merge(dta.sp, agg.weighted.avg.cost.mbps.meeting[,c('service_provider', 'weighted_avg_cost_per_mbps_meeting_goals')], by='service_provider', all.x=T)
## Not Meeting
agg.total.mrc.not.meeting <- aggregate(sp.2016.not.meeting$total_monthly_cost_2016, by=list(sp.2016.not.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.mrc.not.meeting) <- c('service_provider', 'total_mrc')
agg.total.bw.not.meeting <- aggregate(sp.2016.not.meeting$bandwidth_in_mbps_2016, by=list(sp.2016.not.meeting$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.bw.not.meeting) <- c('service_provider', 'total_bw')
agg.weighted.avg.cost.mbps.not.meeting <- merge(agg.total.mrc.not.meeting, agg.total.bw.not.meeting, by='service_provider', all=T)
agg.weighted.avg.cost.mbps.not.meeting$weighted_avg_cost_per_mbps_not_meeting_goals <- agg.weighted.avg.cost.mbps.not.meeting$total_mrc / agg.weighted.avg.cost.mbps.not.meeting$total_bw
dta.sp <- merge(dta.sp, agg.weighted.avg.cost.mbps.not.meeting[,c('service_provider', 'weighted_avg_cost_per_mbps_not_meeting_goals')], by='service_provider', all.x=T)
## Overall
agg.total.mrc.all <- aggregate(sp.2016$total_monthly_cost_2016, by=list(sp.2016$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.mrc.all) <- c('service_provider', 'total_mrc')
agg.total.bw.all <- aggregate(sp.2016$bandwidth_in_mbps_2016, by=list(sp.2016$service_provider_2016), FUN=sum, na.rm=T)
names(agg.total.bw.all) <- c('service_provider', 'total_bw')
agg.weighted.avg.cost.mbps.all <- merge(agg.total.mrc.all, agg.total.bw.all, by='service_provider', all=T)
agg.weighted.avg.cost.mbps.all$weighted_avg_cost_per_mbps_all <- agg.weighted.avg.cost.mbps.all$total_mrc / agg.weighted.avg.cost.mbps.all$total_bw
dta.sp <- merge(dta.sp, agg.weighted.avg.cost.mbps.all[,c('service_provider', 'weighted_avg_cost_per_mbps_all')], by='service_provider', all.x=T)

## total BW already of districts not meeting goals
#agg.bw.total <- aggregate(sp.2016$district_not_meeting_goals_2014*sp.2016$bandwidth_in_mbps_2016, by=list(sp.2016$service_provider_2016), FUN=sum, na.rm=T)
#names(agg.bw.total) <- c('service_provider', 'total_bw_of_districts_not_meeting_goals')
#dta.sp <- merge(dta.sp, agg.bw.total, by='service_provider', all.x=T)

## Mean MRC for those not meeting (to multiply by cost per mbps)
#agg.mrc.mean <- aggregate(sp.2016.not.meeting$total_monthly_cost_2016, by=list(sp.2016.not.meeting$service_provider_2016), FUN=mean, na.rm=T)
#names(agg.mrc.mean) <- c('service_provider', 'mean_mrc_of_districts_not_meeting_goals')
#dta.sp <- merge(dta.sp, agg.mrc.mean, by='service_provider', all.x=T)


## if 10, 15, 20, 25 service providers upgraded their students
dta.sp <- dta.sp[order(dta.sp$num_students_not_meeting_goal, decreasing=T),]

## total number of students not meeting goals in the population
total.students <- sum(sp.2016.not.meeting$num_students)

## 10
sum(dta.sp$num_students_not_meeting_goal[1:10])
## extrapolate to entire population of students currently not meeting goals
## (11,534,180, from frozen SMD: Total Population of Students 2016 - Extrapolated Number of Students Meeting Connectivity Goal)
## 62%
perc.10 <- round(sum(dta.sp$num_students_not_meeting_goal[1:10]) / total.students, 2)
## in Ultimate Master: 7.2 M
11534180 * perc.10

## 15
sum(dta.sp$num_students_not_meeting_goal[1:15])
## extrapolate to entire population of students currently not meeting goals
## (11,534,180, from frozen SMD: Total Population of Students 2016 - Extrapolated Number of Students Meeting Connectivity Goal)
## 62%
perc.10 <- round(sum(dta.sp$num_students_not_meeting_goal[1:10]) / total.students, 2)
## in Ultimate Master: 7.2 M
11534180 * perc.10


## 20
sum(dta.sp$num_students_not_meeting_goal[1:20])
## extrapolate to entire population of students currently not meeting goals
## (11,534,180, from frozen SMD: Total Population of Students 2016 - Extrapolated Number of Students Meeting Connectivity Goal)
## 73%
perc.20 <- round(sum(dta.sp$num_students_not_meeting_goal[1:20]) / total.students, 2)
## in Ultimate Master: 8.4 M
11534180 * perc.20

## subset to the top 20
dta.sp <- dta.sp[1:20,]

## subset districts to all served by the top service providers
sp.2016.all <- sp.2016.all[sp.2016.all$service_provider_2016 %in% dta.sp$service_provider,]
## subset to relevant columns
sp.2016.all <- sp.2016.all[,c('esh_id', 'name', 'num_students', 'ia_bw_mbps_total', 'district_bw_per_student', 'district_meeting_goals_2014',
                              'service_provider_2016', 'bandwidth_in_mbps_2016', 'sp_bw_per_student', 'sp_meeting_goals_2014',
                              'contract_end_date_2016', 'purpose_2016', 'percent_bw_2016', 'total_monthly_cost_2016',
                              'predominant_sp_2016', 'exclude_from_ia_analysis.x', 'locale', 'district_size', 'city', 'postal_cd', 'zip')]

names(sp.2016.all)[names(sp.2016.all) == 'exclude_from_ia_analysis.x'] <- 'exclude_from_ia_analysis'

## subset to top 20 providers
dta.sp.publish <- dta.sp.publish[order(dta.sp.publish$extrapolated_num_students_not_meeting_goal, decreasing=T),]
dta.sp.publish <- dta.sp.publish[1:20,]
dta.sp.publish <- dta.sp.publish[order(dta.sp.publish$extrapolated_percentage, decreasing=T),]
dta.sp.publish$extrapolated_num_students_meeting_goal <- round(dta.sp.publish$extrapolated_num_students_meeting_goal / 1000000, digits=2)
dta.sp.publish$extrapolated_num_students_not_meeting_goal <- round(dta.sp.publish$extrapolated_num_students_not_meeting_goal / 1000000, digits=2)

write.csv(sp.2016, "../data/dd_2016_with_dom_service_provider.csv", row.names=F)
write.csv(sp.2016.all, "../data/dd_2016_top_20_service_provider_all.csv", row.names=F)
write.csv(dta.sp, "../data/service_provider_analysis_bucket_7.csv", row.names=F)
write.csv(dta.sp.publish, "../data/top_20_service_providers_not_meeting_goal_publish.csv", row.names=F)
