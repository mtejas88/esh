## =========================================
##
## Exploratory: exploring the data
##
## =========================================

## Clearing memory
rm(list=ls())


library(data.table)

##**************************************************************************************************************************************************
## 2017 FORM 470s

## READ IN DATA

district_summary <- read.csv("data/interim/district_summary.csv", as.is=T, header=T, stringsAsFactors=F)
applicant_summary <- read.csv("data/interim/applicant_summary.csv", as.is=T, header=T, stringsAsFactors=F)

funding_lost <- sum(district_summary$estimated_special_construction)
schools_impacted <- sum(district_summary$num_schools)
students_impacted <- sum(district_summary$num_students)
campuses_impacted <- sum(district_summary$num_campuses)

district_summary_sub <- data.table(district_summary[,c('postal_cd','locale','fiber_target_status','num_students','num_schools','num_campuses','estimated_special_construction','non_consortia_applicant')])

by_locale <- district_summary_sub[,lapply(.SD,sum), by=c('locale'), .SDcols =! c("postal_cd","fiber_target_status",'non_consortia_applicant')]
by_state <- district_summary_sub[,lapply(.SD,sum), by=c('postal_cd'), .SDcols =! c("locale","fiber_target_status",'non_consortia_applicant')]
by_fiber_target_status <- district_summary_sub[,lapply(.SD,sum), by=c('fiber_target_status'), .SDcols =! c("locale","postal_cd",'non_consortia_applicant')]

by_locale_and_applicant <- district_summary_sub[,lapply(.SD,sum), by=c('locale','non_consortia_applicant'), .SDcols =! c("postal_cd","fiber_target_status")]
by_state_and_applicant <- district_summary_sub[,lapply(.SD,sum), by=c('postal_cd','non_consortia_applicant'), .SDcols =! c("locale","fiber_target_status")]
by_state_no_consortia <- by_state_and_applicant[!by_state_and_applicant$non_consortia_applicant == 'Consortia Applicant',]

by_locale_districts <- aggregate(district_summary$esh_id, by = list(district_summary$locale), FUN = length)
names(by_locale_districts) <- c('locale','num_districts')

by_locale_districts_and_applicant <- aggregate(district_summary$esh_id, by = list(district_summary$locale, district_summary$non_consortia_applicant), FUN = length)
names(by_locale_districts_and_applicant) <- c('locale','non_consortia_applicant','num_districts')

by_state_districts_and_applicant <- aggregate(district_summary$esh_id, by = list(district_summary$postal_cd, district_summary$non_consortia_applicant), FUN = length)
names(by_state_districts_and_applicant) <- c('state','non_consortia_applicant','num_districts')

#barplot(by_locale$estimated_special_construction, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')
#barplot(by_locale$num_students, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')
#barplot(by_locale$num_schools, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')

applicant_summary <- applicant_summary[order(applicant_summary$estimated_special_construction, decreasing = TRUE),]

top_5_applicants <- applicant_summary[1:5,]

#barplot(top_5_applicants$estimated_special_construction, names.arg = top_5_applicants$adj_applicant_ben, main = 'Top Applicants', col = 'blue')

##**************************************************************************************************************************************************
## 2016 LINE ITEM DATA

district_summary_16 <- read.csv("data/interim/district_summary_16.csv", as.is=T, header=T, stringsAsFactors=F)
applicant_summary_16 <- read.csv("data/interim/applicant_summary_16.csv", as.is=T, header=T, stringsAsFactors=F)

funding_lost_16 <- sum(applicant_summary_16$line_item_total_cost)
districts_impacted_16 <- length(district_summary_16$esh_id)
schools_impacted_16 <- sum(district_summary_16$num_schools)
students_impacted_16 <- sum(district_summary_16$num_students)
campuses_impacted_16 <- sum(district_summary_16$num_campuses)

district_summary_sub_16 <- data.table(district_summary_16[,c('postal_cd','locale','fiber_target_status','num_students','num_schools','num_campuses','district_cost_no_extrap','district_cost_extrap')])
by_locale_16 <- district_summary_sub_16[,lapply(.SD,sum), by=c('locale'), .SDcols =! c("postal_cd","fiber_target_status")]
by_state_16 <- district_summary_sub_16[,lapply(.SD,sum), by=c('postal_cd'), .SDcols =! c("locale","fiber_target_status")]

by_locale_districts_16 <- aggregate(district_summary_16$esh_id, by = list(district_summary_16$locale), FUN = length)
names(by_locale_districts_16) <- c('locale','num_districts')

coloardo_summary <- district_summary_16[district_summary_16$postal_cd == 'CO',]

#creating a by locale summary that removes the recipients of free services

by_locale_16_no_free <- district_summary_sub_16[district_summary_sub_16$district_cost_extrap > 0,lapply(.SD,sum), by=c('locale'), .SDcols =! c("postal_cd","fiber_target_status")]
by_state_16_no_free <- district_summary_sub_16[district_summary_sub_16$district_cost_extrap > 0,lapply(.SD,sum), by=c('postal_cd'), .SDcols =! c("locale","fiber_target_status")]

by_locale_districts_16_no_free <- data.table(district_summary_16[district_summary_16$district_cost_extrap > 0,])
by_locale_districts_16_no_free <- aggregate(by_locale_districts_16_no_free$esh_id, by = list(by_locale_districts_16_no_free$locale), FUN = length)
names(by_locale_districts_16_no_free) <- c('locale','num_districts')

#editing the applicant summary to remove all free lines

applicant_summary_16 <- applicant_summary_16[applicant_summary_16$line_item_total_cost > 0,]
special_connections_16 <- sum(applicant_summary_16$line_item_total_num_lines)
by_purpose_clean_16 <- aggregate(applicant_summary_16[!applicant_summary_16$inclusion_status == 'dirty',]$line_item_total_num_lines, by = list(applicant_summary_16$purpose), FUN = sum, na.rm = T) #SHOULD I REMOVE DIRTY AND EXTRAP?

write.csv(coloardo_summary, "data/interim/coloardo_summary_16.csv", row.names=F)

##**************************************************************************************************************************************************
## 2016 DISTRICTS CONGRESS

district_congress_summary_16 <- read.csv("data/interim/district_congress_summary_16.csv", as.is=T, header=T, stringsAsFactors=F)
district_congress_sub_16 <- data.table(district_congress_summary_16[,c('state_and_district','postal_cd.x','locale','fiber_target_status','num_students','num_schools','num_campuses','district_cost_no_extrap','district_cost_extrap','exclude_from_ia_analysis','meeting_2014_goal_no_oversub','current_assumed_unscalable_campuses','current_known_unscalable_campuses','c2_postdiscount_remaining_16')])
#removing recipients of free services
by_congress_16_spec_fiber <- district_congress_sub_16[district_congress_sub_16$district_cost_extrap > 0]

by_congress_16_spec_fiber <- district_congress_sub_16[,lapply(.SD,sum), by=c('state_and_district'), .SDcols =! c("postal_cd.x","locale","fiber_target_status",'exclude_from_ia_analysis','meeting_2014_goal_no_oversub')]

##FINDING STATE EXTRAP PERCENTAGES
dd.2016 <- read.csv("data/interim/dd_16.csv", as.is=T, header=T, stringsAsFactors=F)
dd.2016 <- dd.2016[dd.2016$district_type == 'Traditional',]
dd.2016.clean <- dd.2016[dd.2016$exclude_from_ia_analysis == F,]
dd.2016.clean$meeting_students <- ifelse(dd.2016.clean$meeting_2014_goal_no_oversub == TRUE, dd.2016.clean$num_students, 0)
dd.2016.meeting <- aggregate(dd.2016.clean$meeting_students, by = list(dd.2016.clean$postal_cd), FUN = sum)
names(dd.2016.meeting) <- c('postal_cd','meeting_students')
dd.2016.total_clean <- aggregate(dd.2016.clean$num_students, by = list(dd.2016.clean$postal_cd), FUN = sum)
names(dd.2016.total_clean) <- c('postal_cd','total_students_clean')
dd.2016.total <- aggregate(dd.2016$num_students, by = list(dd.2016$postal_cd), FUN = sum)
names(dd.2016.total) <- c('postal_cd','total_students')
dd.2016.extrap <- merge(x = dd.2016.meeting, y = dd.2016.total_clean, by = 'postal_cd')
dd.2016.extrap <- merge(x = dd.2016.extrap, y = dd.2016.total, by = 'postal_cd')
dd.2016.extrap$state_extrap <- dd.2016.extrap$meeting_students / dd.2016.extrap$total_students_clean
dd.2016.extrap$state_extrap_meeting <- dd.2016.extrap$state_extrap * dd.2016.extrap$total_students

##STUDENTS MEETING BY CONGRESS
names(district_congress_sub_16)[2] <- 'postal_cd'
district_congress_sub_16 <- merge(x = district_congress_sub_16, y = dd.2016.extrap[,c('postal_cd','state_extrap')], by = 'postal_cd')
district_congress_sub_16$meeting_students <- ifelse(district_congress_sub_16$exclude_from_ia_analysis == F, 
                                                    ifelse(district_congress_sub_16$meeting_2014_goal_no_oversub == T, district_congress_sub_16$num_students, 0), 
                                                    district_congress_sub_16$num_students*district_congress_sub_16$state_extrap)
district_congress_sub_16$not_meeting_students <- district_congress_sub_16$num_students - district_congress_sub_16$meeting_students
by_congress_not_meeting <- aggregate(district_congress_sub_16$not_meeting_students, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_not_meeting) <- c('state_and_district','not_meeting_students')

sum(district_congress_summary_16$current_known_unscalable_campuses+district_congress_summary_16$current_assumed_unscalable_campuses)

by_congress_need_fiber <- aggregate(district_congress_sub_16$current_assumed_unscalable_campuses + district_congress_sub_16$current_known_unscalable_campuses, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_need_fiber) <- c('state_and_district','campuses_need_fiber')
by_congress_campuses <- aggregate(district_congress_sub_16$num_campuses, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_campuses) <- c('state_and_district','num_campuses')
by_congress_schools <- aggregate(district_congress_sub_16$num_schools, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_schools) <- c('state_and_district','num_schools')
by_congress_need_fiber <- merge(x = by_congress_need_fiber, y = by_congress_campuses, by = 'state_and_district')
by_congress_need_fiber <- merge(x = by_congress_need_fiber, y = by_congress_schools, by = 'state_and_district')
by_congress_need_fiber$percent_campuses_need_fiber <- by_congress_need_fiber$campuses_need_fiber / by_congress_need_fiber$num_campuses
by_congress_need_fiber$schools_need_fiber <- ceiling(by_congress_need_fiber$percent_campuses_need_fiber * by_congress_need_fiber$num_schools)
by_congress_remaining_funds <- aggregate(district_congress_sub_16$c2_postdiscount_remaining_16, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_remaining_funds) <- c('state_and_district','remaining_wifi_funds')


#new students meeting (difference in extrapoloated)

dd_2015 <- read.csv("data/raw/dd_2015.csv", as.is=T, header=T, stringsAsFactors=F)
new_students_meeting <- read.csv("data/raw/new_students_meeting.csv", as.is=T, header=T, stringsAsFactors=F)

new_students_meeting <- new_students_meeting[,c("postal_cd","extrap_16","extrap_15")]
source('../../General_Resources/common_functions/correct_dataset.R')
dd_2015 <- correct.dataset(dd_2015, 0 , 0)
names(dd_2015) <- c('esh_id','exclude_15','meeting_15')

district_congress_sub_16_2 <- data.table(district_congress_summary_16[,c('esh_id','state_and_district','postal_cd.x','exclude_from_ia_analysis','meeting_2014_goal_no_oversub','num_students')])
names(district_congress_sub_16_2)[3] <- 'postal_cd'
by_congress_new_students <- merge(x = district_congress_sub_16_2, y = dd_2015, by = 'esh_id')
by_congress_new_students <- merge(x = by_congress_new_students, y = new_students_meeting, by = 'postal_cd')
by_congress_new_students$new_students_meeting <- ifelse(by_congress_new_students$exclude_from_ia_analysis == FALSE & by_congress_new_students$exclude_15 == FALSE
                                                          & by_congress_new_students$meeting_15 == FALSE & by_congress_new_students$meeting_2014_goal_no_oversub == TRUE,
                                                            by_congress_new_students$num_students,
                                                          ifelse(by_congress_new_students$exclude_from_ia_analysis == FALSE & by_congress_new_students$exclude_15 == FALSE,
                                                                  0,
                                                                  by_congress_new_students$num_students * (by_congress_new_students$extrap_16 - by_congress_new_students$extrap_15)
                                                                  )
                                                        )
by_congress_new_students <- aggregate(by_congress_new_students$new_students_meeting, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_new_students) <- c('state_and_district','new_students_meeting')
by_congress_new_students <- merge(x = by_congress_new_students, y = by_congress_need_fiber, by = 'state_and_district')
by_congress_students <- aggregate(district_congress_sub_16$num_students, by = list(district_congress_sub_16$state_and_district), FUN = sum)
names(by_congress_students) <- c('state_and_district','num_students')
by_congress_new_students <- merge(x = by_congress_new_students, y = by_congress_students, by = 'state_and_district')
by_congress_new_students$new_students_meeting_perc <- by_congress_new_students$new_students_meeting / by_congress_new_students$num_students


# not meeting WIFI
wifi_schools <- read.csv("data/raw/wifi_schools.csv", as.is=T, header=T, stringsAsFactors=F)
district_congress_sub_16_3 <- data.table(district_congress_summary_16[,c('esh_id','state_and_district','postal_cd.x','exclude_from_ia_analysis','meeting_2014_goal_no_oversub','num_students','num_schools')])
wifi_schools <- merge(x = district_congress_sub_16_3, y = wifi_schools, by = 'esh_id')
wifi_schools$need_wifi_schools <- wifi_schools$not_meeting * wifi_schools$num_schools
wifi_schools$has_wifi_schools <- wifi_schools$num_schools - wifi_schools$need_wifi_schools
by_congress_wifi <- aggregate(wifi_schools$has_wifi_schools, by = list(wifi_schools$state_and_district), FUN = sum)
names(by_congress_wifi) <- c('state_and_district','has_wifi_schools')
by_congress_wifi$has_wifi_schools <- round(by_congress_wifi$has_wifi_schools,0)
by_congress_wifi <- merge(x= by_congress_wifi, y = by_congress_schools, on = 'state_and_district')
by_congress_wifi$has_wifi_perc <- by_congress_wifi$has_wifi_schools / by_congress_wifi$num_schools
