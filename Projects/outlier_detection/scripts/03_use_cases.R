source("04_identify_outliers.R")

## ===========================================================================================================
##
## Modifications by Sierra Costanza (2017)
##
## 1) 3 new arguments (used for testing the best/final approach):
##    -data_17: the 2017 data frame
##    -with_16: 0 or 1 - whether or not to include the 2016 outliers when introducing the 2017 datapoints
##    -n_17_at_time: 0 to 5 - number of 2017 datapoints to introduce at a time
##
## 2) Methodology: Keep using the ESD algorithm as used for 2016, but introduce 2017 data points (= districts or line items) 
## 'n_17_at_time' on top of the 2016 data for each use case as if they are a part of the 2016 data. Re-run 
## the algorithm for each 2017 datapoint(s) in attempt to catch all 2017 outliers 'n_17_at_time' if the algorithm
## flags them as such (i.e., they lie sufficiently outside the 2016 data distribution)
##
## 3) Use cases: 7 total metrics we are testing outliers on:
##    -for line items: cost per circuit [at various combinations of bandwidth, connect category and purpose]
##    -for districts: change in total bandwidth (total and %), change in monthly cost per mbps (total and %), 
##    monthly cost per mbps, bandwidth per student [at all combinations district size and locale]
## ===========================================================================================================


###
# Helper function to loop through outlier identification, introducing 2017 data
###

identify_outliers_loop <- function(o_16,output,significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time) {
  # 1. flag 2016 outliers (JUST the 2016 data)
  outliers_2016=identify_outliers(output[output$year==2016,], significance_level,cost_column,unique_id,use_case_name,with_16=1,n_17_at_time=0 )
  #2.a. if we are removing the 2016 outliers first
  if (with_16==0) {
    #remove the the 2016 outliers identified in line 14 above
    output16=output[output$year==2016,]
    output16=output16[!(output16[[unique_id]] %in% outliers_2016$outlier_unique_id),]
    output=rbind(output16,output[output$year==2017,])
    frm=dim(output[output$year==2016,])[1]
    #introduce the 2017 datapoints 'n_17_at_time' - the for loop defines how that is indexed. Since the filtered data (in 'output') is stacked (2016 then 2017),
    #the starting index for the 2017 data is the size of 2016 filtered data without outliers + 1
    for(i in seq(from=frm, to=(nrow(output) + n_17_at_time), by=n_17_at_time)){
      #if-else conditions below to catch cases when n_17_at_a_time isn't a perfect interval to cover all points
      if (i+n_17_at_time < nrow(output)) {
      master_output=rbind(master_output,
      identify_outliers(output[c(1:frm,(i+1):(i+n_17_at_time)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }
      else if ((i+n_17_at_time) == nrow(output)) {
      master_output=rbind(master_output,
      identify_outliers(output[c(1:frm,nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }
      else if ((i < nrow(output)) & (i+n_17_at_time > nrow(output))) {
      master_output=rbind(master_output,
        identify_outliers(output[c(1:o_16,(i+1):nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }  
    }
  }
  #2.b. if we are NOT removing the 2016 outliers first (keeping 2016 data intact)
  else {
    if (n_17_at_time > 0) {
    #the starting index for the 2017 data is o_16 (=size of 2016 filtered data, including outliers) 
    for(i in seq(from=o_16, to=(nrow(output) + n_17_at_time), by=n_17_at_time)){
      #if-else conditions below to catch cases when n_17_at_a_time isn't a perfect interval to cover all points
      if (i+n_17_at_time < nrow(output)) {
        master_output=rbind(master_output,
        identify_outliers(output[c(1:o_16,(i+1):(i+n_17_at_time)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }     
      else if ((i+n_17_at_time) == nrow(output)) {
        master_output=rbind(master_output,
        identify_outliers(output[c(1:o_16,nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }    
      else if ((i < nrow(output)) & (i+n_17_at_time > nrow(output))) {
        master_output=rbind(master_output,
        identify_outliers(output[c(1:o_16,(i+1):nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }  
    } 
    } else {return(outliers_2016)} #for if we are just identifying 2016 data outliers
  }
  #3. append to master output
  assign('master_output',master_output,envir=.GlobalEnv)
}  

###
# use case #1 
# identify cost outliers on line item-level data
###

use_case_cost_per_mbps_li <- function (data, data_17, circuit_size, technology, line_item_purpose, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      bandwidth_in_mbps %in% circuit_size,
      connect_category %in% technology,
      purpose %in% line_item_purpose
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
  output17 <- data_17 %>%
    filter(
      round(bandwidth_in_mbps,digits=1) %in% circuit_size,
      connect_category %in% technology,
      purpose %in% line_item_purpose
    ) 
  #combine filtered outputs
  output=rbind(output16,output17) }
  else {
    output=output16  
  }
str1 <- paste0("\"circuit_size_in_mbps\" => \"", circuit_size,"\"")
str2 <- paste0("\"technology\" => \"", technology,  "\"")
str3 <- paste0("\"purpose\" => \"", line_item_purpose, "\"")

use_case_parameters <- paste(str1, str2, str3, sep = ", ")
output <- cbind(use_case_parameters, output)
identify_outliers_loop(o_16,output,0.05,"monthly_cost_per_circuit", "line_item_id","Cost per Mbps",with_16,n_17_at_time)
}

###
# use case #2
# identify change in total bandwidth outliers based on district-level data
###

use_case_total_bw <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(change_in_bw_tot)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
  output17 <- data_17 %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(change_in_bw_tot)
    )
  #combine filtered outputs
  output=rbind(output16,output17) }
    else {
    output=output16  
    }
str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
str2 <- paste0("\"district_size\" => \"", size,"\"")

use_case_parameters <- paste(str1, str2, sep = ",")
output <- cbind(use_case_parameters, output)
identify_outliers_loop(o_16,output,0.05,"change_in_bw_tot", "esh_id","Change in Total BW",with_16,n_17_at_time)  
}

###
# use case #3
# identify % change in bandwidth outliers based on district-level data
###

use_case_pct_bw <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(change_in_bw_pct)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
    output17 <- data_17 %>%
      filter(
        locale %in% district_locale,
        district_size %in% size,
        !is.na(change_in_bw_pct)
      )
    #combine filtered outputs
    output=rbind(output16,output17) }
  else {
    output=output16  
  }
  str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
  str2 <- paste0("\"district_size\" => \"", size,"\"")
  
  use_case_parameters <- paste(str1, str2, sep = ",")
  output <- cbind(use_case_parameters, output)
  identify_outliers_loop(o_16,output,0.05,"change_in_bw_pct", "esh_id","% Change in BW",with_16,n_17_at_time)  
}

###
# use case #4
# identify change in total monthly cost outliers based on district-level data
###

use_case_total_cost <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(change_in_cost_tot)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
    output17 <- data_17 %>%
      filter(
        locale %in% district_locale,
        district_size %in% size,
        !is.na(change_in_cost_tot)
      )
    #combine filtered outputs
    output=rbind(output16,output17) }
  else {
    output=output16  
  }
  str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
  str2 <- paste0("\"district_size\" => \"", size,"\"")
  
  use_case_parameters <- paste(str1, str2, sep = ",")
  output <- cbind(use_case_parameters, output)
  identify_outliers_loop(o_16,output,0.05,"change_in_cost_tot", "esh_id","Change in Total Monthly Cost",with_16,n_17_at_time)  
}

###
# use case #5
# identify % change in monthly cost outliers based on district-level data
###

use_case_pct_cost <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(change_in_cost_pct)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
    output17 <- data_17 %>%
      filter(
        locale %in% district_locale,
        district_size %in% size,
        !is.na(change_in_cost_pct)
      )
    #combine filtered outputs
    output=rbind(output16,output17) }
  else {
    output=output16  
  }
  str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
  str2 <- paste0("\"district_size\" => \"", size,"\"")
  
  use_case_parameters <- paste(str1, str2, sep = ",")
  output <- cbind(use_case_parameters, output)
  identify_outliers_loop(o_16,output,0.05,"change_in_cost_pct", "esh_id","% Change in Monthly Cost",with_16,n_17_at_time)  
}

###
# use case #6
# identify monthly cost outliers based on district-level data
###

use_case_cost <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(ia_monthly_cost_per_mbps)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
    output17 <- data_17 %>%
      filter(
        locale %in% district_locale,
        district_size %in% size,
        !is.na(ia_monthly_cost_per_mbps)
      )
    #combine filtered outputs
    output=rbind(output16,output17) }
  else {
    output=output16  
  }
  str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
  str2 <- paste0("\"district_size\" => \"", size,"\"")
  
  use_case_parameters <- paste(str1, str2, sep = ",")
  output <- cbind(use_case_parameters, output)
  identify_outliers_loop(o_16,output,0.05,"ia_monthly_cost_per_mbps", "esh_id","Monthly Cost",with_16,n_17_at_time)  
}

###
# use case #7
# identify bandwidth per student outliers based on district-level data
###

use_case_bw_per_student <- function (data, data_17, district_locale, size, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  data_17["year"]=2017
  data_17=as.data.frame(data_17)
  #filter for 2016 data use cases
  output16 <- data %>%
    filter(
      locale %in% district_locale,
      district_size %in% size,
      !is.na(ia_bandwidth_per_student_kbps)
    )
  o_16=nrow(output16)
  #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
  if (dim(data_17)[1] > 1) {
    output17 <- data_17 %>%
      filter(
        locale %in% district_locale,
        district_size %in% size,
        !is.na(ia_bandwidth_per_student_kbps)
      )
    #combine filtered outputs
    output=rbind(output16,output17) }
  else {
    output=output16  
  }
  str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
  str2 <- paste0("\"district_size\" => \"", size,"\"")
  
  use_case_parameters <- paste(str1, str2, sep = ",")
  output <- cbind(use_case_parameters, output)
  identify_outliers_loop(o_16,output,0.05,"ia_bandwidth_per_student_kbps", "esh_id","BW per Student",with_16,n_17_at_time)  
}

