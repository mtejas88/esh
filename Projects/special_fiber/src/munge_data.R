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
##2017 FORM 470 MUNGING

#correcting columns
source('../../General_Resources/common_functions/correct_dataset.R')
sf.2017 <- correct.dataset(sf.2017, 0 , 0)

#subsetting to districts in our universe
sf.2017 <- sf.2017[sf.2017$include_in_universe_of_districts == TRUE,]

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
sf.2017$non_consortia_applicant <- ifelse(sf.2017$Applicant.Type %in% c('School','School District'), 1, 0)

#df of num schools and students served by applicant (note, some students and schools are double counted)
applicant_schools <- aggregate(sf.2017$num_schools, by = list(sf.2017$adj_applicant_ben), FUN = sum)
names(applicant_schools) <- c('adj_applicant_ben','num_schools')
applicant_students <- aggregate(sf.2017$num_students, by = list(sf.2017$adj_applicant_ben), FUN = sum)
names(applicant_students) <- c('adj_applicant_ben','num_students')

applicant_requests.2017 <- merge(x = applicant_requests.2017, y = applicant_schools, by = 'adj_applicant_ben')
applicant_requests.2017 <- merge(x = applicant_requests.2017, y = applicant_students, by = 'adj_applicant_ben')

#unique recipient district costs
district_costs <- aggregate(sf.2017$recip_cost, by = list(sf.2017$recipient_id), FUN = sum, na.rm = T)
names(district_costs) <- c('esh_id','estimated_special_construction')

#determining if the district receives from consortia
consortia_summary <- aggregate(sf.2017$non_consortia_applicant, by = list(sf.2017$recipient_id), FUN = sum, na.rm = T)
names(consortia_summary) <- c('esh_id','non_consortia_applicant')

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
district_summary <- merge(x = district_summary, y = consortia_summary, by = 'esh_id')
sum(district_summary$estimated_special_construction)
district_summary$non_consortia_applicant <- ifelse(district_summary$non_consortia_applicant == 0, 'Consortia Applicant', 'Non Consortia Applicant')

write.csv(district_summary, "data/interim/district_summary.csv", row.names=F)
write.csv(applicant_requests.2017, "data/interim/applicant_summary.csv", row.names=F)

##**************************************************************************************************************************************************
##2016 FORM 470 MUNGING

sf.2016 <- read.csv("data/raw/special_fiber_2016.csv", as.is=T, header=T, stringsAsFactors=F)
dd.2016 <- read.csv("data/raw/dd_2016.csv", as.is=T, header=T, stringsAsFactors=F)

#correcting columns
source('../../General_Resources/common_functions/correct_dataset.R')
sf.2016 <- correct.dataset(sf.2016, 0 , 0)
dd.2016 <- correct.dataset(dd.2016, 0 , 0)

#creating  dataframe of the unique special fiber line items applied for
applicant_summary_16 <- sf.2016[,c('line_item_id','inclusion_status','purpose','line_item_total_num_lines','connect_category','line_item_total_cost',
                                   'bandwidth_in_mbps','reporting_name')]
applicant_summary_16 <- applicant_summary_16[!duplicated(applicant_summary_16),]

#creating a df of just the costs for the districts (line_item_district_monthly_total * months). NEED TO REMOVE DUPs FROM DISTRICT COSTS. FIXXXXXX

district_costs_16 <- sf.2016[,c('line_item_id','line_item_district_monthly_cost_total','months_of_service','recipient_id')]
district_costs_16 <- district_costs_16[!duplicated(district_costs_16),]
district_costs_16 <- aggregate(district_costs_16$line_item_district_monthly_cost_total * district_costs_16$months_of_service, by = list(district_costs_16$recipient_id), FUN = sum)
names(district_costs_16) <- c('esh_id','district_cost_no_extrap')

#calculating total cost (not just received by districts, since some goes to NIFs). this will be used to extrapolate the district costs 
total_district_costs_16 <- sum(applicant_summary_16$line_item_total_cost)
extrap_percent <- (total_district_costs_16 / sum(district_costs_16$district_cost_no_extrap))

#extrapolated district costs (to spread out the costs that just go to NIFs from those line items and the missing one time costs)
district_costs_16$district_cost_extrap <- district_costs_16$district_cost_no_extrap * (extrap_percent)


#only keeping districts that receive special fiber services
district_summary_16 <- dd.2016[dd.2016$esh_id %in% sf.2016$recipient_id,]

#merging in district costs
district_summary_16 <- merge(x= district_summary_16, y = district_costs_16, by = 'esh_id')

#dirty line items

table(unique(sf.2016[,c('line_item_id','inclusion_status')])$inclusion_status)


sum(unique(sf.2016[,c('line_item_id','line_item_total_cost')])$line_item_total_cost)
sum(applicant_summary_16$line_item_total_cost)

write.csv(district_summary_16, "data/interim/district_summary_16.csv", row.names=F)
write.csv(applicant_summary_16, "data/interim/applicant_summary_16.csv", row.names=F)

##**************************************************************************************************************************************************
##CONGRESS MUNGING 

congress <- read.csv("congress/districts_to_congress_shp.csv", as.is=T, header=T, stringsAsFactors=F)
congress <- congress[congress$KEEP. == 'yes',c('esh_id','name','postal_cd','CD115FP','State.and.Rep.District')]

#only keeping districts that receive special fiber services
district_congress_summary_16 <- congress[congress$esh_id %in% sf.2016$recipient_id,]

#merging in district costs
district_congress_summary_16 <- merge(x= district_congress_summary_16, y = district_costs_16, by = 'esh_id')
names(district_congress_summary_16) <- c('esh_id','name','postal_cd','district','state_and_district','district_cost_no_extrap','district_cost_extrap')

#merging in other districts deluxe fields
district_congress_summary_16 <- merge(x = district_congress_summary_16, y = dd.2016, by = 'esh_id')

write.csv(district_congress_summary_16, "data/interim/district_congress_summary_16.csv", row.names=F)
