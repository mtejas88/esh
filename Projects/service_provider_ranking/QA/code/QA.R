## ===========================================================================================================================
##
## QA: This script compares Jeremy's SP-State output with the SP ranking used for 2016 National Analysis
##
## ===========================================================================================================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

jeremy.qa <- read.csv("QA/data/jeremy_output_03-14-2017.csv", as.is=T, header=T, stringsAsFactors=F)
dta.sp <- read.csv("data/interim/service_provider_aggregated_clean_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

sp.agg <- aggregate(jeremy.qa$num_districts_served, by=list(jeremy.qa$reporting_name), FUN=sum, na.rm=T)
names(sp.agg) <- c('service_provider', 'num_districts_served_jeremy')
dta.compare <- merge(sp.agg, dta.sp[,c('service_provider', 'num_districts_served')], by='service_provider', all=T)
dta.compare$diff <- dta.compare$num_districts_served_jeremy - dta.compare$num_districts_served
## 2 SPs differ
table(dta.compare$diff)
sub <- dta.compare[which(dta.compare$diff != 0),]
## because Services Received reporting name was not updated with the Charter, ENA fixes (since Jeremy is merging on that field)

sp.agg.students <- aggregate(jeremy.qa$num_students_served, by=list(jeremy.qa$reporting_name), FUN=sum, na.rm=T)
names(sp.agg.students) <- c('service_provider', 'num_students_served_jeremy')
dta.sp$num_students_served <- dta.sp$num_students_not_meeting_goal + dta.sp$num_students_meeting_goal
dta.compare.students <- merge(sp.agg.students, dta.sp[,c('service_provider', 'num_students_served')],
                     by='service_provider', all=T)
dta.compare.students$diff <- dta.compare.students$num_students_served_jeremy - dta.compare.students$num_students_served
## 28 SPs differ
table(dta.compare.students$diff)
sub <- dta.compare.students[which(dta.compare.students$diff != 0),]
## because for National Analysis, we took out districts where the SP was allowing them to meet goals but the district was not actually meeting
## this is because they provide upstream but the BW the district is receiving is actually limited by their ISP

##**************************************************************************************************************************************************
## write out data

write.csv(dta.compare, "QA/data/compare_districts.csv", row.names=F)
write.csv(dta.compare.students, "QA/data/compare_students.csv", row.names=F)
