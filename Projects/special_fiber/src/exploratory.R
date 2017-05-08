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
district_congress_sub_16 <- data.table(district_congress_sub_16[,c('state_and_district','postal_cd.x','locale','fiber_target_status','num_students','num_schools','num_campuses','district_cost_no_extrap','district_cost_extrap')])
#removing recipients of free services
district_congress_sub_16 <- district_congress_sub_16[district_congress_sub_16$district_cost_extrap > 0]

by_congress_16 <- district_congress_sub_16[,lapply(.SD,sum), by=c('state_and_district'), .SDcols =! c("postal_cd.x","locale","fiber_target_status")]

##**************************************************************************************************************************************************
## 2016 DISTRICTS CONGRESS

