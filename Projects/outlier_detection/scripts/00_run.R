# clear the console
cat("\014")

# remove every object in the environment
rm(list = ls())

library(dplyr)

# set up workding directory -- it is currently set up to the folder which contains all scripts
#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/sat_r_programs/R_database_access/'

# initiate export data table
export_data <- c()

source("01_get_tables.R")

# let's apply general filters
source("02_apply_general_filters.R")

# load csv files
# deluxe districts
d_16 <- read.csv("../data/intermediate/d16_custom_filters.csv", as.is = TRUE)
d_17 <- read.csv("../data/intermediate/d17_custom_filters.csv", as.is = TRUE)
# services received
s_16 <- read.csv("../data/intermediate/s16_custom_filters.csv", as.is = TRUE)
s_17 <- read.csv("../data/intermediate/s17_custom_filters.csv", as.is = TRUE)

# identify outliers
source("03_use_cases.R")

#Create empty data frame
master_output <- data.frame(outlier_use_case_name=character(),
                            outlier_use_case_cd=character(),
                            outlier_use_case_parameters=character(),
                            outlier_test_parameters=character(),
                            outlier_unique_id=numeric(),
                            outlier_value=numeric(),
                            R=numeric(),
                            lam=numeric())

###
# run line item use case 1 
### 
# Cable Internet
uc1=use_case_li(s_16,s_17,'Cost per Circuit', c(50), c("Cable"), c("Internet"),with_16=0,n_17_at_time=1)
uc2=use_case_li(s_16,s_17,'Cost per Circuit', c(100), c("Cable"), c("Internet"),with_16=0,n_17_at_time=1)
uc3=use_case_li(s_16,s_17,'Cost per Circuit', c(150), c("Cable"), c("Internet"),with_16=0,n_17_at_time=1)
# Fiber (Internet and WAN) - takes a few mins
uc4=NULL
s_matrix_fiber=s_16 %>% group_by(bandwidth_in_mbps, connect_category, purpose) %>% filter (bandwidth_in_mbps %in% c(100,200,500,1000,10000), connect_category=='Lit Fiber', purpose %in% c('WAN','Internet')) %>% select(bandwidth_in_mbps, connect_category, purpose) %>% unique() %>% arrange(bandwidth_in_mbps, connect_category, purpose)
for(i in 1:nrow(s_matrix_fiber)) {
  uc4=rbind(uc4,use_case_li(s_16,s_17,'Cost per Circuit', s_matrix_fiber[i,1], s_matrix_fiber[i,2], s_matrix_fiber[i,3],with_16=0,n_17_at_time=1))
}
# Fixed Wireless
uc5=use_case_li(s_16,s_17,'Cost per Circuit', c(50), c("Fixed Wireless"), c("Internet"),with_16=0,n_17_at_time=1)
uc6=use_case_li(s_16,s_17,'Cost per Circuit', c(100), c("Fixed Wireless"), c("Internet"),with_16=0,n_17_at_time=1)
uc7=use_case_li(s_16,s_17,'Cost per Circuit', c(100), c("Fixed Wireless"), c("WAN"),with_16=0,n_17_at_time=1)
uc8=use_case_li(s_16,s_17,'Cost per Circuit', c(1000), c("Fixed Wireless"), c("WAN"),with_16=0,n_17_at_time=1)
# DSL Internet
uc9=use_case_li(s_16,s_17,'Cost per Circuit', c(1.5), c("DSL"), c("Internet"),with_16=0,n_17_at_time=1)
uc10=use_case_li(s_16,s_17,'Cost per Circuit', c(10), c("DSL"), c("Internet"),with_16=0,n_17_at_time=1)
# T-1
uc11=use_case_li(s_16,s_17,'Cost per Circuit', c(1.5), c("T-1"), c("Internet"),with_16=0,n_17_at_time=1)
uc12=use_case_li(s_16,s_17,'Cost per Circuit', c(1.5), c("T-1"), c("WAN"),with_16=0,n_17_at_time=1)

li_distributions=rbind(uc1,uc2,uc3,uc4,uc5,uc6,uc7,uc8,uc9,uc10,uc11,uc12)
###
# run district use cases at national AND state level
# TIME WARNING!!
###
ucd=NULL
d_matrix=d_16 %>% group_by(locale, district_size, postal_cd) %>% select(locale, district_size, postal_cd) %>% unique() %>% arrange(locale, district_size, postal_cd)
d_matrix_n=d_16 %>% group_by(locale, district_size) %>% select(locale, district_size) %>% unique() %>% arrange(locale, district_size) %>% mutate(postal_cd=c('National'))
d_matrix=rbind(d_matrix,d_matrix_n)
system.time(for(i in 1:nrow(d_matrix)) {
  ucd=rbind(ucd,use_case_district(d_16,d_17,'Change in Total BW', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
  ucd=rbind(ucd,use_case_district(d_16,d_17,'% Change in BW', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
  ucd=rbind(ucd,use_case_district(d_16,d_17,'Change in Total Monthly Cost', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
  ucd=rbind(ucd,use_case_district(d_16,d_17,'% Change in Monthly Cost', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
  ucd=rbind(ucd,use_case_district(d_16,d_17,'Monthly Cost per Mbps', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
  ucd=rbind(ucd,use_case_district(d_16,d_17,'BW per Student', d_matrix[i,1], d_matrix[i,2], d_matrix[i,3], with_16=0,n_17_at_time=1))
})

#Run Rule Based Use Cases
use_case_rule('2017','meeting_to_not_meeting_connectivity')
use_case_rule('2017','meeting_to_not_meeting_affordability')
use_case_rule('2017','decrease_in_bw')
use_case_rule('2017','increase_in_cost')


consolidate_dups=function(case,data,columns) {
  if (grepl('master', case)) {
    df1=data %>% filter(outlier_use_case_name != 'Cost per Circuit') %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count==1)
    dfg1=data %>% filter(outlier_use_case_name != 'Cost per Circuit') %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count>1)
    uniques=data[(data$outlier_unique_id %in% df1$outlier_unique_id),]}
  else {
    df1=data %>% filter(outlier_flag==1) %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count==1)
    dfg1=data %>% filter(outlier_flag==1) %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count>1)
    uniques=data[(data$outlier_unique_id %in% df1$outlier_unique_id) & data$outlier_flag==1,]  
  }
  if (case=='master_output_national') {
    doubles=data[(data$outlier_unique_id %in% dfg1$outlier_unique_id) & !grepl('National',data$outlier_use_case_parameters) ,]
    data=unique(rbind(data[data$outlier_use_case_name=='Cost per Circuit',],uniques,doubles))}
  if (case=='tableau_national') {
    doubles=data[(data$outlier_unique_id %in% dfg1$outlier_unique_id) & data$state!='National' & data$outlier_flag==1,]
    data=unique(rbind(data[data$outlier_flag==0,],uniques,doubles)) }
  if (case=='master_output_new') {
    doubles=data[(data$outlier_unique_id %in% dfg1$outlier_unique_id) & (data$outlier_use_case_name %in% columns) ,]
    if (columns==c('Meeting-not Meeting Connectivity Rule','Decrease in BW Rule')) {
      ucm <- merge(d_17, doubles, by.x="esh_id",by.y="outlier_unique_id")
      doubles$outlier_use_case_name='Decrease BW Not Meeting Connectivity'
      doubles$outlier_use_case_cd='decrease_bandwidth_not_meeting_connectivity'
      doubles$outlier_value=as.numeric(ucm$change_in_bw_tot)
    } else{
      ucm <- merge(d_17, doubles, by.x="esh_id",by.y="outlier_unique_id")
      doubles$outlier_use_case_name='Increase Cost/Mbps Not Meeting Affordability'
      doubles$outlier_use_case_cd='increase_cost_per_mbps_not_meeting_affordability'
      doubles$outlier_value=as.numeric(ucm$change_in_cost_tot)
    }
    notdoubles=data[!(data$outlier_unique_id %in% doubles$outlier_unique_id),]
    data=unique(rbind(data[data$outlier_use_case_name=='Cost per Circuit',],notdoubles,doubles))}
  if (case=='tableau_new') {
    doubles=data[(data$outlier_unique_id %in% dfg1$outlier_unique_id) & (data$outlier_use_case_name %in% columns) & data$outlier_flag==1,]
    if (columns==c('Meeting-not Meeting Connectivity Rule','Decrease in BW Rule')) {
      doubles$outlier_use_case_name='Decrease BW Not Meeting Connectivity'
    } else{
      doubles$outlier_use_case_name='Increase Cost/Mbps Not Meeting Affordability'
    }
    notdoubles=data[!(data$outlier_unique_id %in% doubles$outlier_unique_id)  & (data$outlier_flag==1),]
    data=unique(rbind(data[data$outlier_flag==0,],notdoubles,doubles)) }
  return(data)
}
#Remove from National if outlier shows up in National AND State for the same use case
  #for master output
master_output=consolidate_dups('master_output_national',master_output,c())
  #for tableau
ucd=consolidate_dups('tableau_national',ucd,c())

#Consolidate the specific requested duplicate use cases (and create new use case names) for districts
#for master output
master_output=consolidate_dups('master_output_new',master_output,c('Meeting-not Meeting Connectivity Rule','Decrease in BW Rule'))
master_output=consolidate_dups('master_output_new',master_output,c('Meeting-not Meeting Affordability Rule','Increase in $/BW Rule'))
#for tableau
#ucd=consolidate_dups('tableau_new',ucd,c('Meeting-not Meeting Connectivity Rule','Decrease in BW Rule'))
#ucd=consolidate_dups('tableau_new',ucd,c('Meeting-not Meeting Affordability Rule','Increase in $/BW Rule'))

master_output=master_output %>% filter(!(outlier_use_case_name %in% c('Meeting-not Meeting Connectivity Rule','Meeting-not Meeting Affordability Rule')))
#ucd=ucd %>% filter(!(outlier_use_case_name %in% c('Meeting-not Meeting Connectivity Rule','Meeting-not Meeting Affordability Rule')))

# export
write.csv(master_output, paste0("../data/export/master_output_", Sys.Date(), ".csv"), row.names = FALSE, append = FALSE)

# load into postgres
source("05_export_to_postgres.R")

