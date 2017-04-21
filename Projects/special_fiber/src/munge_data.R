## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

sf.2017 <- read.csv("data/raw/special_fiber_2017.csv", as.is=T, header=T, stringsAsFactors=F)
applicant_470s.2017 <- read.csv("data/raw/applicant_470s_2017.csv", as.is=T, header=T, stringsAsFactors=F)
joe_f.2017 <- read.csv("joe_f/joe_f_form470.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

#correcting columns
source('../../General_Resources/common_functions/correct_dataset.R')
sf.2017 <- correct.dataset(sf.2017, 0 , 0)

#adjusting name of 470 column
colnames(joe_f.2017)[6] <- 'form_470'

#getting rid of blank columns in joe's spreadsheet
joe_f.2017 <- joe_f.2017[!joe_f.2017$Applicant.Name == "",]


#cleaning up joe f's spreadsheet. two rows have multiple 470s listed. since the applicants are the same, I'm just going
#to only keep one of the 470 numbers
joe_f.2017$form_470 <- ifelse(joe_f.2017$Applicant.Name == 'Lincoln Public School District ', 170048745,
                        ifelse(joe_f.2017$Applicant.Name == 'South Pasadena Unified School District ', 170058965, 
                          joe_f.2017$form_470))

#cleaning up special construction costs
joe_f.2017[joe_f.2017$form_470 == 170055375 & joe_f.2017$Lit.Dark.Self == 'Category1 Network Equipment ','Estimated.Special.construction'] <- '$300,000.00'
joe_f.2017[joe_f.2017$form_470 == 170066403 & joe_f.2017$Lit.Dark.Self == 'Category1 Network Equipment ','Estimated.Special.construction'] <- '$1,200,000.00'
joe_f.2017$Estimated.Special.construction <- gsub(",","",joe_f.2017$Estimated.Special.construction)
joe_f.2017$Estimated.Special.construction <- substring(joe_f.2017$Estimated.Special.construction,2)
joe_f.2017$Estimated.Special.construction <- as.numeric(joe_f.2017$Estimated.Special.construction)

write.csv(joe_f.2017, "data/interim/joe_f.2017.csv", row.names=F)

#joining applicant BENs to joe f's spreadsheet. losing some rows because they don't go to districts / schools
new_joe_f.2017 <- merge(x = joe_f.2017, y = applicant_470s.2017, by = 'form_470')


#creating a df of just the applicant ben and the sum of the amount they are requesting
applicant_requests.2017 <- new_joe_f.2017[,c('adj_applicant_ben','Estimated.Special.construction')]
applicant_requests.2017 <- aggregate(applicant_requests.2017$Estimated.Special.construction, by = list(applicant_requests.2017$adj_applicant_ben), FUN = sum, na.rm = T)
names(applicant_requests.2017) <- c('adj_applicant_ben','estimated_special_construction')

#creating a df to count the number of recipients for each applicant, and the percent of the applicant's cost that each recip has

length(unique(sf.2017$adj_applicant_ben))
recipient_count <- aggregate(sf.2017$recipient_id, by = list(sf.2017$adj_applicant_ben), FUN = length)
names(recipient_count) <- c('adj_applicant_ben', 'count_recips')
recipient_count$recip_perc <- 1 / recipient_count$count_recips

missing <- applicant_requests.2017[!applicant_requests.2017$adj_applicant_ben %in% recipient_count$adj_applicant_ben,]

#merging together the recipient_count df with new_joe_df to get the recip % of cost with the total cost
applicant_requests.2017 <- merge(x = recipient_count, y = applicant_requests.2017, by = 'adj_applicant_ben')
applicant_requests.2017$recip_cost <- applicant_requests.2017$recip_perc * applicant_requests.2017$estimated_special_construction

#merging together recipient cost with sf.2017
sf.2017 <- merge(x = sf.2017, y = applicant_requests.2017, by = 'adj_applicant_ben')

#unique recipient district costs
district_costs <- aggregate(sf.2017$recip_cost, by = list(sf.2017$recipient_id), FUN = sum, na.rm = T)
names(district_costs) <- c('esh_id','estimated_special_construction')

#final district summary df
columns_to_keep <- c('esh_id','nces_cd','district_size', 'district_type','num_schools','num_campuses','num_students', 'locale',
                     'frl_percent','discount_rate_c1','postal_cd','county','latitude','longitude','exclude_from_ia_analysis',
                     'exclude_from_ia_cost_analysis','include_in_universe_of_districts','ia_bandwidth_per_student_kbps',
                     'meeting_2014_goal_no_oversub','meeting_2018_goal_oversub','ia_monthly_cost_per_mbps','meeting_knapsack_affordability_target',
                     'fiber_target_status','bw_target_status')
district_summary <- sf.2017[,columns_to_keep]
district_summary <- district_summary[!duplicated(district_summary),]
district_summary <- merge(x = district_summary, y = district_costs, by = 'esh_id')
district_summary <- district_summary[district_summary$include_in_universe_of_districts == TRUE,]

write.csv(district_summary, "data/interim/district_summary.csv", row.names=F)
write.csv(applicant_requests.2017, "data/interim/applicant_summary.csv", row.names=F)
