# clear the console
cat("\014")

# remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "ggplot2", "maps", "reshape2", "scales")

#this installs packages only if you don't have them
for (i in 1:length(lib)){
  if (!lib[i] %in% rownames(installed.packages())){
    install.packages(lib[i])
  }
}
library(dplyr)
library(ggplot2)
library(maps)
library(reshape2)
library(scales)


# set up workding directory -- it is currently set up to the folder which contains all scripts
#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '/Users/sdelosreyes/GitHub/ficher/Projects/'
setwd(paste(github_path, 'outlier_detection', sep=''))

# initiate export data table
export_data <- c()

# export services received table from mode
# note that the credentials are pointed to the live ONYX database as of 1/17/2017
# check regularly to see that credentials are accurate since they may change periodically
# raw mode data is saved in the data/mode folder with the data pull date added to the suffix
source('scripts/01_get_tables.R')

# let's apply general filters
# this stage is about getting the data fit for analysis in a very general sense.
# for instance, we almost always want to exclude non E-rate line items regardless of which type of outlier we want to identify
# we also want to look for outliers only within clean data since 
# identifying outliers within dirty and clean data may lead to conversations such as 
# "well, that's because that line item is dirty and has the purpose wrong. duh."
source("scripts/02_apply_general_filters.R")

# now, we have the line item-level data fit for analysis
# it's time to apply filters for your custom case
# for instance, you may want to look for super expensive lit fiber Internet circuits
# cost distribution varies significantly by purpose, circuit size, and technology among other things
# to shy away from looking at line item prices across those dimensions
# please refer to the spreadsheet below for other suggestions from 
# https://docs.google.com/a/educationsuperhighway.org/spreadsheets/d/1SthiXVF1XaGg_Sr9AjKD-k-KnYIw6o2fNokMquO9DIY/edit?usp=drive_web


#Create empty data frame

master_output <- data.frame(outlier_use_case_name=character(),
                            outlier_use_case_cd=character(),
                            outlier_use_case_parameters=character(),
                            outlier_test_parameters=character(),
                            outlier_unique_id=numeric(),
                            outlier_value=numeric(),
                            R=numeric(),
                            lam=numeric())


# identify outliers
source("scripts/03_use_cases.R")

###
# run use case 1
###
analysis_data <- use_case_cost_per_mbps_li(c(100), c("Lit Fiber"), c("WAN"))
# run outlier test

###
# run use case 2
###
analysis_data <- use_case_total_bw_d(c("Urban"), c("Tiny"))
analysis_data <- use_case_total_bw_d(c("Urban"), c("Small"))
analysis_data <- use_case_total_bw_d(c("Urban"), c("Medium"))
analysis_data <- use_case_total_bw_d(c("Urban"), c("Large"))
analysis_data <- use_case_total_bw_d(c("Urban"), c("Mega"))

analysis_data <- use_case_total_bw_d(c("Suburban"), c("Tiny"))
analysis_data <- use_case_total_bw_d(c("Suburban"), c("Small"))
analysis_data <- use_case_total_bw_d(c("Suburban"), c("Medium"))
analysis_data <- use_case_total_bw_d(c("Suburban"), c("Large"))
analysis_data <- use_case_total_bw_d(c("Suburban"), c("Mega"))

analysis_data <- use_case_total_bw_d(c("Town"), c("Tiny"))
analysis_data <- use_case_total_bw_d(c("Town"), c("Small"))
analysis_data <- use_case_total_bw_d(c("Town"), c("Medium"))
analysis_data <- use_case_total_bw_d(c("Town"), c("Large"))
analysis_data <- use_case_total_bw_d(c("Town"), c("Mega"))

analysis_data <- use_case_total_bw_d2(c("Rural"), c("Tiny"))
analysis_data <- use_case_total_bw_d2(c("Rural"), c("Small"))
analysis_data <- use_case_total_bw_d(c("Rural"), c("Medium"))
analysis_data <- use_case_total_bw_d(c("Rural"), c("Large"))
analysis_data <- use_case_total_bw_d(c("Rural"), c("Mega"))


# export
write.csv(analysis_data, paste0("data/export/outlier_export_", Sys.Date(), ".csv"), row.names = FALSE, append = TRUE)
write.csv(master_output, paste0("data/export/master_output_", Sys.Date(), ".csv"), row.names = FALSE, append = TRUE)
