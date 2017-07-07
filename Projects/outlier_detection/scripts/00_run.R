# clear the console
cat("\014")

# remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr")

#this installs packages only if you don't have them
#for (i in 1:length(lib)){
#  if (!lib[i] %in% rownames(installed.packages())){
#    install.packages(lib[i], repos="http://cran.us.r-project.org")
#  }
#}
library(dplyr)

# set up workding directory -- it is currently set up to the folder which contains all scripts
#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/sat_r_programs/R_database_access/'

# initiate export data table
export_data <- c()

# export services received table from mode
# note that the credentials are pointed to the live ONYX database as of 1/17/2017
# check regularly to see that credentials are accurate since they may change periodically
# raw mode data is saved in the data/mode folder with the data pull date added to the suffix
source("01_get_tables.R")

# let's apply general filters
# this stage is about getting the data fit for analysis in a very general sense.
# for instance, we almost always want to exclude non E-rate line items regardless of which type of outlier we want to identify
# we also want to look for outliers only within clean data since 
# identifying outliers within dirty and clean data may lead to conversations such as 
# "well, that's because that line item is dirty and has the purpose wrong. duh."
source("02_apply_general_filters.R")

# now, we have the line item-level data fit for analysis
# it's time to apply filters for your custom case
# for instance, you may want to look for super expensive lit fiber Internet circuits
# cost distribution varies significantly by purpose, circuit size, and technology among other things
# to shy away from looking at line item prices across those dimensions
# please refer to the spreadsheet below for other suggestions from 
# https://docs.google.com/a/educationsuperhighway.org/spreadsheets/d/1SthiXVF1XaGg_Sr9AjKD-k-KnYIw6o2fNokMquO9DIY/edit?usp=drive_web


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

#Remove from National if outlier shows up in National AND State for the same use case
  #for master output
df1=master_output %>% filter(outlier_use_case_name != 'Cost per Circuit') %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count==1)
dfg1=master_output %>% filter(outlier_use_case_name != 'Cost per Circuit') %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count>1)
uniques=master_output[(master_output$outlier_unique_id %in% df1$outlier_unique_id),]
doubles=master_output[(master_output$outlier_unique_id %in% dfg1$outlier_unique_id) & !grepl('National',master_output$outlier_use_case_parameters) ,]
master_output=unique(rbind(master_output[master_output$outlier_use_case_name=='Cost per Circuit',],uniques,doubles))
  #for tableau
df1=ucd %>% filter(outlier_flag==1) %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count==1)
dfg1=ucd %>% filter(outlier_flag==1) %>% group_by(outlier_unique_id,outlier_use_case_name) %>% summarise(count=n()) %>% filter(count>1)
uniques=ucd[(ucd$outlier_unique_id %in% df1$outlier_unique_id) & ucd$outlier_flag==1,]
doubles=ucd[(ucd$outlier_unique_id %in% dfg1$outlier_unique_id) & ucd$state!='National' & ucd$outlier_flag==1,]
ucd=unique(rbind(ucd[ucd$outlier_flag==0,],uniques,doubles))

# export
write.csv(master_output, paste0("../data/export/master_output_", Sys.Date(), ".csv"), row.names = FALSE, append = FALSE)

# load into postgres
source("05_export_to_postgres.R")

