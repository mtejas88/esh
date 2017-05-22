## =========================================
##
## Exploratory: exploring the data
##
## =========================================

## Clearing memory
rm(list=ls())


library(data.table)
library(dplyr)

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

# not meeting WIFI PERFECT
wifi_schools_2 <- read.csv("data/raw/wifi_schools_2.csv", as.is=T, header=T, stringsAsFactors=F)
district_congress_sub_16_3 <- data.table(district_congress_summary_16[,c('esh_id','state_and_district','postal_cd.x','exclude_from_ia_analysis','meeting_2014_goal_no_oversub','num_students','num_schools')])
wifi_schools_2 <- merge(x = district_congress_sub_16_3, y = wifi_schools_2, by = 'esh_id')
wifi_schools_2$need_wifi_schools <- wifi_schools_2$not_meeting * wifi_schools_2$num_schools
wifi_schools_2$has_wifi_schools <- wifi_schools_2$num_schools - wifi_schools_2$need_wifi_schools
by_congress_wifi_2 <- aggregate(wifi_schools_2$has_wifi_schools, by = list(wifi_schools_2$state_and_district), FUN = sum)
names(by_congress_wifi_2) <- c('state_and_district','has_wifi_schools')
by_congress_wifi_2$has_wifi_schools <- round(by_congress_wifi_2$has_wifi_schools,0)
by_congress_wifi_2 <- merge(x= by_congress_wifi_2, y = by_congress_schools, on = 'state_and_district')
by_congress_wifi_2$has_wifi_perc <- by_congress_wifi_2$has_wifi_schools / by_congress_wifi_2$num_schools


##**************************************************************************************************************************************************
## Differentiating between self-provisioned and other conn types

applicant_summary_16 <- read.csv("data/interim/applicant_summary_16.csv", as.is=T, header=T, stringsAsFactors=F)
form_470s_16 <- read.csv("data/raw/form_470s_2016.csv", as.is=T, header=T, stringsAsFactors=F)
sr_16 <- read.csv("data/raw/sr_2016.csv", as.is=T, header=T, stringsAsFactors=F)
dd_16 <- read.csv("data/raw/dd_2016.csv", as.is=T, header=T, stringsAsFactors=F)

line_items <- read.csv("data/raw/special_fiber_2016.csv", as.is=T, header=T, stringsAsFactors=F)

#correcting columns for 2016 self provision vs other conn types
source('../../General_Resources/common_functions/correct_dataset.R')
line_items <- correct.dataset(line_items, 0 , 0)

line_items <- select(line_items, line_item_id, applicant_id, line_item_recurring_elig_cost)
line_items <- distinct(line_items)

line_items <- merge(applicant_summary_16, line_items, by = 'line_item_id', all.x = T)
line_items$has_recurring <- ifelse(line_items$line_item_recurring_elig_cost > 0,T,F)

#defining self provisioning by line items that have no recurring cost (and were included in the special_construction original line items)
line_items$summary_category <- ifelse(line_items$has_recurring == F, 'self-provisioning', line_items$connect_category)
summary_category <- summarise(group_by(line_items, summary_category), special_cost = sum(line_item_total_cost, na.rm = T))

# how many people filed self provisioned 470s (in our universe - 
# there are some null Applicant IDs, so not including them)
x <- distinct(form_470s_16, applicant_id) %>% filter(!is.na(applicant_id))
self_provision <- filter(line_items, summary_category == 'self-provisioning')
y <- distinct(self_provision, applicant_id)

#number of applicants in 470 who filed for self provisioning
self_provision_470_applicants_16 <- nrow(x)

#number of applicants who filed 470 and ended up with self provisioning
in_both <- data.frame(intersect(y$applicant_id, x$applicant_id))
names(in_both) <- 'applicant_id'
self_provision_470_and_471_16 <- nrow(in_both)

#number of applicants who filed 471 for self-provisioning but no 470 with that Function
only_471 <- nrow(y) - self_provision_470_and_471_16

print(paste(self_provision_470_applicants_16,'applicants filed 470s for self provisioning'))
print(paste(self_provision_470_and_471_16,'applicants filed 470s and 471s for self provisioning'))
print(paste(only_471,'applicants only filed 471s for self provisioning'))

# just looking at the applicants who didn't end up with self-provisioning, but filed a 470 for it
just_470 <- filter(x, !(x$applicant_id %in% in_both$applicant_id))

sr_16 <- correct.dataset(sr_16, 0, 0)
sr_16 <- select(sr_16, line_item_id, applicant_id, inclusion_status, purpose, connect_category, line_item_total_cost, line_item_total_num_lines, bandwidth_in_mbps)
sr_16 <- distinct(sr_16)

just_470 <- merge(x = just_470, y = sr_16, by = 'applicant_id', all.x = T)
table(just_470$inclusion_status)

summary_just_470 <- summarise(group_by(just_470, connect_category), num_lines = sum(line_item_total_num_lines, na.rm = T))
summary_just_470 <- filter(summary_just_470, !connect_category == 'ISP Only')
summary_just_470$percent <- summary_just_470$num_lines / sum(summary_just_470$num_lines, na.rm = T)

#% fiber lines applied for
z <- filter(summary_just_470, connect_category %in% c('Lit Fiber','Dark Fiber')) %>% summarise(sum(percent)) %>% round(2)
print(paste(z*100,'percent of the services received from applicants who filed 470s for self-provision fiber but chose something else were fiber'))


#looking at the district metrics for the districts who applied for self provision form 470s but chose something else
dd_16 <- correct.dataset(dd_16, 0, 0)

#merging just_470 back with sr16, so I can join the recipients of services to the DD
just_470 <- filter(x, !(x$applicant_id %in% in_both$applicant_id))
sr_16 <- read.csv("data/raw/sr_2016.csv", as.is=T, header=T, stringsAsFactors=F)
sr_16 <- correct.dataset(sr_16, 0, 0)
sr_16 <- select(sr_16, line_item_id, applicant_id, inclusion_status, purpose, connect_category, line_item_total_cost, line_item_total_num_lines, bandwidth_in_mbps, recipient_id)
just_470 <- merge(x = just_470, y = sr_16, by = 'applicant_id', all.x = T)


no_self_provision_dd <- merge(x = distinct(just_470, recipient_id), y = dd_16, by.x = 'recipient_id', by.y = 'esh_id', all.x = T)
no_self_provision_dd <- filter(no_self_provision_dd, !is.na(nces_cd), exclude_from_ia_analysis == F) 

meeting_goals <- summarise(group_by(no_self_provision_dd, meeting_2014_goal_no_oversub), count = n())
meeting_goals$percent <- meeting_goals$count / sum(meeting_goals$count)
meeting_goals_percent <- as.numeric(meeting_goals[meeting_goals$meeting_2014_goal_no_oversub == T, 'percent']) %>% round(2)

print(paste(meeting_goals_percent*100,'percent of the districts who were recipients of an services from an applicant that filed 470s for self-provision fiber but chose something else are meeting 100 kbps / student'))
