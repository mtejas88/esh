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
##    3.1) For all of the metrics and use cases described above (starting with districts, 6/12/17), we are doing 
##    them at the national level AND the state level
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
    outliers=NULL
    #introduce the 2017 datapoints 'n_17_at_time' - the for loop defines how that is indexed. Since the filtered data (in 'output') is stacked (2016 then 2017),
    #the starting index for the 2017 data is the size of 2016 filtered data without outliers + 1
    for(i in seq(from=frm, to=(nrow(output) + n_17_at_time), by=n_17_at_time)){
      #if-else conditions below to catch cases when n_17_at_a_time isn't a perfect interval to cover all points
      if (i+n_17_at_time < nrow(output)) {
        outliers=rbind(outliers,
                       identify_outliers(output[c(1:frm,(i+1):(i+n_17_at_time)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }
      else if ((i+n_17_at_time) == nrow(output)) {
        outliers=rbind(outliers,
                       identify_outliers(output[c(1:frm,nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
      }
      else if ((i < nrow(output)) & (i+n_17_at_time > nrow(output))) {
        outliers=rbind(outliers,
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
          outliers=rbind(outliers,
                         identify_outliers(output[c(1:o_16,(i+1):(i+n_17_at_time)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
        }     
        else if ((i+n_17_at_time) == nrow(output)) {
          outliers=rbind(outliers,
                         identify_outliers(output[c(1:o_16,nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
        }    
        else if ((i < nrow(output)) & (i+n_17_at_time > nrow(output))) {
          outliers=rbind(outliers,
                         identify_outliers(output[c(1:o_16,(i+1):nrow(output)),],significance_level,cost_column,unique_id,use_case_name,with_16,n_17_at_time ))
        }  
      } 
    } else {output16=outliers_2016
    return(output16)} #for if we are just identifying 2016 data outliers
  }
  #3. append to master output
  master_output=rbind(master_output,outliers)
  assign('master_output',master_output,envir=.GlobalEnv)
  #4. return relevant distributions for visualization
  outputlist = list("outliers_2017" = outliers[,c("outlier_unique_id","outlier_value","outlier_use_case_name")], "base_2016" = output16)
  return(outputlist)
}  

###
# use case type #1 
# identify outliers on line item-level data
###

use_case_li <- function (data, data_17, metric, circuit_size, technology, line_item_purpose, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
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
    data_17=as.data.frame(data_17)
    data_17["year"]=2017
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
  
  #define the column based on input metric - will modify this as new use cases come up
  if (metric=="Cost per Circuit"){
    column='monthly_cost_per_circuit'
  }
  
  outputlist=identify_outliers_loop(o_16,output,0.05,column, "line_item_id",metric,with_16,n_17_at_time)
  
  #combine 2016 "normal data" distribution and 2017 outliers in order to visualize
  distribution=outputlist$base_2016[,c("line_item_id",column)]
  distribution[,"metric"]=metric
  names(distribution)=c("outlier_unique_id", "outlier_value","outlier_use_case_name")
  distribution[,"outlier_flag"]=0
  
  outliers_2017=as.data.frame(outputlist$outliers_2017)
  if (nrow(outliers_2017) > 0) {
    outliers_2017[,"outlier_flag"]=1
    distribution=rbind(distribution,outliers_2017)
  }
  #add in separate columns for the parameters 
  distribution[,"bandwidth_in_mbps"]=circuit_size
  distribution[,"connect_category"]=technology
  distribution[,"purpose"]=line_item_purpose
  distribution[,"id"]=c(1:nrow(distribution))
  
  return(distribution)
}

###
# use case type #2
# identify outliers based on district-level data, state and national level
###

##function for optimized locale and size filtering
filter_opt=function(n=-1,data,state,district_locale,size,column) {
  locales=c('Rural','Town','Suburban','Urban')
  sizes=c('Tiny','Small','Medium','Large','Mega')
  l_ind=match(district_locale,locales)
  s_ind=match(size,sizes)
  es=0
  base_filter=function(data,state,district_locale,size,column) {
    if (state!='National') {
      output16 <- data %>%
        filter(
          postal_cd %in% state,
          locale %in% district_locale,
          district_size %in% size)  %>% 
        filter_(paste('!is.na(', column, ')'))
    } else {
      output16 <- data %>%
        filter(
          locale %in% district_locale,
          district_size %in% size) %>% 
        filter_(paste('!is.na(', column, ')'))
    }
    return(output16)
  }
  while(n <= 25) {
    if(n==-1) {
      output16=base_filter(data,state,district_locale,size,column)
      n=ifelse(nrow(output16) >= 0, nrow(output16), 0)
    }else{
      if(district_locale !='Urban') {
        for (l in l_ind:length(locales)) {
          locales_check=locales[l_ind:l]
          output16=base_filter(data,state,locales_check,size,column)
          n=nrow(output16)
          if(n > 25){
            break
          }
        }
      }
      for (s in s_ind:length(sizes)) {
        if(n > 25){
          break
        }
        sizes_check=sizes[s_ind:s]
        if (exists("locales_check")) {
          output16=base_filter(data,state,locales_check,sizes_check,column)}
        else{
          output16=base_filter(data,state,district_locale,sizes_check,column)}
        n=nrow(output16)
        es=s
        if(n > 25){
          break
        }
      }
    }
    if(es == length(sizes) & n <= 25){
      return(base_filter(data,state,district_locale,size,column))
      break
    }
  }
  return(output16)
} 

use_case_district <- function (data, data_17, metric, district_locale, size, state, with_16,n_17_at_time) {
  #column that flags the year in both the 2016 and 2017 data
  data["year"]=2016
  
  #define the column based on input metric - will modify this as new use cases come up
  if (metric=="Change in Total BW"){
    column='change_in_bw_tot'
  } else if (metric=="% Change in BW") {
    column='change_in_bw_pct'
  } else if (metric=="Change in Total Monthly Cost") {
    column='change_in_cost_tot'
  } else if (metric=="% Change in Monthly Cost") {
    column='change_in_cost_pct'
  } else if (metric=="Monthly Cost per Mbps") {
    column='ia_monthly_cost_per_mbps'
  } else if (metric=="BW per Student") {
    column='ia_bandwidth_per_student_kbps'
  }
  
  #filter for 2016 data use cases
  output16=filter_opt(n=-1,data,state,district_locale,size,column)
  o_16=nrow(output16)
  #sample size check
  if (o_16 >= 25) {
    #filter for 2017 data use cases - have to separately because they need to be stacked in order to construct the loop
    if (dim(data_17)[1] > 1) {
      data_17=as.data.frame(data_17)
      data_17["year"]=2017
      if (state!='National') {
        output17 <- data_17 %>%
          filter(
            postal_cd %in% state,
            locale %in% district_locale,
            district_size %in% size) %>% 
          filter_(paste('!is.na(', column, ')'))  %>%
          select (-c(meeting_to_not_meeting_connectivity, meeting_to_not_meeting_affordability,change_in_cost_tot_nb))
      } else {
        output17 <- data_17 %>%
          filter(
            locale %in% district_locale,
            district_size %in% size) %>% 
          filter_(paste('!is.na(', column, ')')) %>%
          select (-c(meeting_to_not_meeting_connectivity, meeting_to_not_meeting_affordability,change_in_cost_tot_nb))
      }
      #combine filtered outputs
      output=rbind(output16,output17) }
    else {
      output=output16  
    }
    str1 <- paste0("\"district_locale\" => \"", district_locale,"\"")
    str2 <- paste0("\"district_size\" => \"", size,"\"")
    str3 <- paste0("\"district_state\" => \"", state,"\"")
    
    use_case_parameters <- paste(str1, str2, str3, sep = ",")
    output <- cbind(use_case_parameters, output)
    outputlist=identify_outliers_loop(o_16,output,0.05,column, "esh_id",metric,with_16,n_17_at_time)  
    #combine 2016 "normal data" distribution and 2017 outliers in order to visualize
    distribution=outputlist$base_2016[,c("esh_id",column)]
    distribution[,"metric"]=metric
    names(distribution)=c("outlier_unique_id", "outlier_value","outlier_use_case_name")
    distribution[,"outlier_flag"]=0
    
    outliers_2017=as.data.frame(outputlist$outliers_2017)
    if (nrow(outliers_2017) > 0) {
      outliers_2017[,"outlier_flag"]=1
      distribution=rbind(distribution,outliers_2017)
    }
    
    #add in separate columns for the parameters 
    distribution[,"locale"]=district_locale
    distribution[,"district_size"]=size
    distribution[,"state"]=state
    distribution[,"id"]=c(1:nrow(distribution))
  } else {
    distribution=NULL
  }
  return(distribution)
}

###
# use case type #3
# identify outliers based on rules
###

use_case_rule <- function(current_year,rule_type){
  #Make a string to add to the eventual script for inserting NULL values
  n='NULL'
  if(rule_type == 'meeting_to_not_meeting_connectivity' && current_year =='2017'){  
    uc13 <- filter(d_17,meeting_to_not_meeting_connectivity==TRUE)
    if (dim(uc13)[1] > 1) { #if there are any districts meeting this, insert into master_output
    uc13_formatted <- data.frame('Meeting-not Meeting Connectivity Rule','mtg_not_mtg_connectivity_rule','','',uc13$esh_id,n,n,n)
    colnames(uc13_formatted) <-c('outlier_use_case_name','outlier_use_case_cd','outlier_use_case_parameters','outlier_test_parameters','outlier_unique_id','outlier_value','R','lam')
    master_output <- rbind(master_output,uc13_formatted) 
    assign('master_output',master_output,envir=.GlobalEnv)} 
  }else if(rule_type == 'meeting_to_not_meeting_affordability' && current_year =='2017'){
    uc14 <- filter(d_17,meeting_to_not_meeting_affordability==TRUE)
    if (dim(uc14)[1] > 1) { #if there are any districts meeting this, insert into master_output
    uc14_formatted <- data.frame('Meeting-not Meeting Affordability Rule','mtg_not_mtg_affordability_rule','','',uc14$esh_id,n,n,n)
    colnames(uc14_formatted) <-c('outlier_use_case_name','outlier_use_case_cd','outlier_use_case_parameters','outlier_test_parameters','outlier_unique_id','outlier_value','R','lam')
    master_output <- rbind(master_output,uc14_formatted)
    assign('master_output',master_output,envir=.GlobalEnv)}
  }else if(rule_type == 'decrease_in_bw' && current_year =='2017'){
    uc15 <- filter(d_17,change_in_bw_tot<0)
    uc15_formatted <- data.frame('Decrease in Bandwidth Rule','decrease_in_bw_rule','','',uc15$esh_id,as.numeric(uc15$change_in_bw_tot),n,n)
    colnames(uc15_formatted) <-c('outlier_use_case_name','outlier_use_case_cd','outlier_use_case_parameters','outlier_test_parameters','outlier_unique_id','outlier_value','R','lam')
    master_output <- rbind(master_output,uc15_formatted) 
    assign('master_output',master_output,envir=.GlobalEnv)
  }else if(rule_type == 'increase_in_cost' && current_year =='2017'){
    uc16 <- filter(d_17,change_in_cost_tot_nb >= 1)
    uc16_formatted <- data.frame('Increase in $/BW Rule','increase_cost_mbps_rule','','',uc16$esh_id,as.numeric(uc16$change_in_cost_tot),n,n)
    colnames(uc16_formatted) <-c('outlier_use_case_name','outlier_use_case_cd','outlier_use_case_parameters','outlier_test_parameters','outlier_unique_id','outlier_value','R','lam')
    master_output <- rbind(master_output,uc16_formatted)  
    assign('master_output',master_output,envir=.GlobalEnv)
  }
  
}
