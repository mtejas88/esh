## =========================================
##
## Exploratory: exploring the data
##
## =========================================

## Clearing memory
rm(list=ls())


library(data.table)

##**************************************************************************************************************************************************
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

by_locale_districts <- aggregate(district_summary$esh_id, by = list(district_summary$locale), FUN = length)
names(by_locale_districts) <- c('locale','num_districts')

by_locale_districts_and_applicant <- aggregate(district_summary$esh_id, by = list(district_summary$locale, district_summary$non_consortia_applicant), FUN = length)
names(by_locale_districts_and_applicant) <- c('locale','non_consortia_applicant','num_districts')

barplot(by_locale$estimated_special_construction, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')
barplot(by_locale$num_students, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')
barplot(by_locale$num_schools, names.arg = by_locale$locale, main = 'Funding Lost by Locale', col = 'blue')

applicant_summary <- applicant_summary[order(applicant_summary$estimated_special_construction, decreasing = TRUE),]

top_5_applicants <- applicant_summary[1:5,]

barplot(top_5_applicants$estimated_special_construction, names.arg = top_5_applicants$adj_applicant_ben, main = 'Top Applicants', col = 'blue')

