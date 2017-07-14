## clear memory
rm(list=ls())

## read in data
setwd("~/GitHub/ficher/Projects/nassd")

## source functions
source("src/functions_1.R")

## read in data
dd_union <- read.csv("data/dd_union.csv", as.is=T, header=T, stringsAsFactors=F)

## load packages (if not already in the environment) 
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv","dplyr","secr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)
library(dplyr)
library(secr)

## EXAMPLE/WALKTHROUGH

## Define population: filter dd_union, need to at least pick year 
#dd_mn_16 <- dd_union[which(dd_union$year == 2016 & dd_union$postal_cd == 'MN'),]
#dd_17 <- dd_union[which(dd_union$year == 2017),]

## Define the metric. This might be a TRUE/FALSE grouping (meeting vs. not meeting), calculated metric ($/Mbps),
## or grouping defined (putting % funding remaining into 4 different groups)
#dd_mn_16$metric <- dd_mn_16$meeting_2014_goal_no_oversub

## OR for calculating weighted averages define the numerator and denominator metrics
#dd_mn_16$metric_numer <- dd_mn_16$ia_monthly_cost_total
#dd_mn_16$metric_denom <- dd_mn_16$ia_bw_mbps_total_efc

## Define the group
#dd_mn_16$group <- dd_mn_16$locale

## Subset to the sample population. for some metrics and/or groups this may just be removing nulls.
## for others like fiber_target_status you will also need to remove Potential Targets and No Datas
## if you pick a group subset that has values we should exclude then you will need to create two different data subsets
## one for metric_overall and one for metric_group (where you will exclude relevant group values)
#dd_mn_16_sub <- dd_mn_16[which(dd_mn_16$exclude_from_ia_analysis == 1 & dd_mn_16$exclude_from_ia_cost_analysis==1),]
#dd_mn_15_sub <- dd_mn_16[which(dd_mn_16$meeting_2014_goal_no_oversub >= 0),]



## Creating general subsets

dd_all <- dd_union
dd_15 <- dd_union[which(dd_union$year == 2015),]
dd_16 <- dd_union[which(dd_union$year == 2016),]
dd_17 <- dd_union[which(dd_union$year == 2017),]


## 1. CONNECTIVITY 

  ## 1. A. TOP LEFT/TITLE METRICS
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric <- filter$meeting_2014_goal_no_oversub
      filter_s <- filter[which(filter$metric>=0),]
    
      connectivity_a <- metric_overall(filter,filter_s)
    
    ## - Total students meeting minimum connectivity goal of 100 kbps per student
    connectivity_a[2,"extrap_students"]
    ## - Percent of students meeting
    connectivity_a[2,"percent_students"]
    ## - Percent of districts meeting
    connectivity_a[2,"percent_districts"]
  
  ## 1. B. GRAPH
      dd_all$group <- dd_all$year
      dd_all$metric <- dd_all$meeting_2014_goal_no_oversub
      dd_all_s <- dd_all[which(dd_all$metric >= 0),]
      
      connectivity_b1 <- metric_group(dd_all,dd_all_s)
    
    ## - All of the SotS numbers are hard coded in/copied from previous reports
    ## -  Current 2015, Current 2016, Current 2017
    connectivity_b1[which(connectivity_b1$metric == 1),c("group","percent_districts","extrap_districts","population_districts","sample_districts")]
    
  ## 1. C. MEETING 100 KBPS/STUDENT GOAL
    
      filter1 <- dd_all
      filter1$metric <- filter1$meeting_2014_goal_no_oversub
      filter1$group <- filter1$year
      filter1_s <- filter1[which(filter1$metric>=0),]
      
      filter2 <- dd_union[which(dd_union$year == 2017),]
      filter2$metric <- filter2$meeting_2014_goal_no_oversub
      filter2$group <- filter2$locale
      fitler2_s <- filter2[which(filter2$metric>=0),]
      
      
      connectivity_c1 <- metric_group(filter1,filter1_s)  
      connectivity_c2 <- metric_group(filter2,fitler2_s)
    
    ## - 100 kbps Goal Meeting Status Overall
    connectivity_c1[which(connectivity_c1$metric == 1),]
    
    ## - 100 kbps Goal Meeting Status by Group 
    connectivity_c2[which(connectivity_c2$metric == 1),]
  
  ## 1. D. MEETING 1 MBPS/STUDENT GOAL
    filter1 <- dd_all
    filter1$metric <- filter1$meeting_2018_goal_oversub
    filter1$group <- filter1$year
    filter1_s <- filter1[which(filter1$metric>=0),]
    
    filter2 <- dd_union[which(dd_union$year == 2017),]
    filter2$metric <- filter2$meeting_2018_goal_oversub
    filter2$group <- filter2$discount_rate_c1
    fitler2_s <- filter2[which(filter2$metric>=0),]
    
    
    connectivity_d1 <- metric_group(filter1,filter1_s)  
    connectivity_d2 <- metric_group(filter2,fitler2_s)
    
    ## - 1 Mbps Goal Meeting Status Overall 
    connectivity_d1[which(connectivity_d1$metric == 1),]
    
    ## - 1 Mbps Goal Meeting Status by Group (district size)
    connectivity_d2[which(connectivity_d2$metric == 1),]
  
  ## 1. E. UPGRADED TO MEET 100 KBPS/STUDENT GOAL
      filter1 <- dd_all[which(dd_all$year == 2016 | dd_all$year == 2017),]
      filter1$metric <- filter1$upgraded_to_meet_2014_goal
      filter1$group <- filter1$year
      filter1_s <- filter1[which(filter1$metric>=0),]
      
      filter2 <- dd_union[which(dd_union$year == 2017),]
      filter2$metric <- filter2$upgraded_to_meet_2014_goal
      filter2$group <- filter2$district_size
      fitler2_s <- filter2[which(filter2$metric>=0),]
      
      connectivity_e1 <- metric_group(filter1,filter1_s)  
      connectivity_e2 <- metric_group(filter2,fitler2_s)
  
      ## - Upgraded to meet the 100 kbps Goal Overall 
      connectivity_e1[which(connectivity_e1$metric == 1),]
      
      ## - Upgraded to meet the 100 kbps Goal by Group (locale)
      connectivity_e2[which(connectivity_e2$metric == 1),] 

## 2. FIBER 
      
  ## 2. A. TOP LEFT/TITLE METRICS
      filter <- dd_union[which(dd_union$year == 2017),]
      
      total_campuses <- sum(filter$num_campuses,na.rm = TRUE)
      total_unscalable_campuses <- sum(filter$unscalable_campuses,na.rm = TRUE)
      total_fiber_campuses <- total_campuses - total_unscalable_campuses
      
      ## - Schools that do not have fiber connections - percent
      total_fiber_campuses/total_campuses
      
      ## - Schools that do not have fiber - #
      total_unscalable_campuses
      
  ## 2. B. GRAPHS
  
          total_campuses_16 <- sum(dd_16$num_campuses,na.rm = TRUE)
          total_unscalable_campuses_16 <- sum(dd_16$unscalable_campuses,na.rm = TRUE)
          total_fiber_campuses_16 <- total_campuses_16 - total_unscalable_campuses_16
        
          total_campuses_17 <- sum(dd_17$num_campuses,na.rm = TRUE)
          total_unscalable_campuses_17 <- sum(dd_17$unscalable_campuses,na.rm = TRUE)
          total_fiber_campuses_17 <- total_campuses_17 - total_unscalable_campuses_17
      
      ## - Schools on fiber %
      ## - Sots hard coded in/copied from report
      ## - Current 2016
      total_fiber_campuses_16/total_campuses_16
      ## - Current 2017
      total_fiber_campuses_17/total_campuses_17
      
      ## - Schools that do not have fiber connects - #
      ## - Sots hard coded in/copied from report    
      ## - Current 2016
      total_unscalable_campuses_16
     
      ## - Current 2017
      total_unscalable_campuses_17
      
  ## 2. C. FIBER TARGET V NOT TARGET
        filter <- dd_union[which(dd_union$year == 2017),]
        filter$metric <- filter$fiber_target_status
        filter$group <- filter$locale
        filter_s <- filter[which(filter$metric=="Target"|filter$metric=="Not Target"),]
        
      
        fiber_c1 <- metric_overall(filter,filter_s)
        fiber_c2 <- metric_group(filter,filter_s)
        
      ## - Overall
        fiber_c1
      
      ## - By Group
        fiber_c2
      
  ## 2. D. UNSCALABLE CAMPUSES
        filter <- dd_union[which(dd_union$year == 2017),]
        filter$group <- filter$fiber_target_status
        
        filter_total_unscalable_campuses <- sum(filter$unscalable_campuses,na.rm = TRUE)
        
        A <- aggregate(unscalable_campuses ~ group, data = filter, FUN = sum)
        B <- aggregate(num_campuses ~ group, data = filter, FUN = sum)
        C <- aggregate(esh_id ~ group, data = filter, FUN = length)
        
        fiber_d2 <- merge(A,B)
        fiber_d2 <- merge(fiber_d2,C)
        fiber_d2$percent_total_unscalable <- fiber_d2$unscalable_campuses/fiber_d2$num_campuses
        fiber_d2$percent_of_campuses <- fiber_d2$unscalable_campuses/filter_total_unscalable_campuses
        
      ## - Unscalable Campuses by Group
        fiber_d2
        
        
## 3.AFFORDABILITY 
        
    ## 3. A. TOP LEFT/TITLE METRICS
        
      ## - Students that would have the bandwidth they need if their districts received national benchmark pricing
      
         ##requires several steps in calculations, saving for later
    
      ## - Median cost per Mbps 
        
        filter <- dd_union[which(dd_union$year == 2017 & dd_union$ia_monthly_cost_per_mbps>0),]
        affordability_a1 <- median(filter$ia_monthly_cost_per_mbps)
        
      ## - Percent districts meeting Knapsack
        filter <- dd_union[which(dd_union$year == 2017),]
        a <- length(filter[which(filter$meeting_knapsack==1),"esh_id"])
        b <- length(filter[which(filter$meeting_knapsack>=0),"esh_id"])
        
        affordability_a2 <- a/b
        
    ## 3. B. GRAPH 
        
        dd_all$group <- dd_all$year
        dd_all$metric <- dd_all$ia_monthly_cost_per_mbps
        dd_all_s <- dd_all[which(dd_all$metric >= 0),]
        
        affordability_b1 <- metric_group_median(dd_all,dd_all_s)
              
      ## - Sots numbers are hard coded in/copied from last year
      ## - Current 2015, 2016, 2017
        affordability_b1
        
    ## 3. C. MEETING KNAPSACK

      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric <- filter$meeting_knapsack
      filter$group <- filter$locale
      filter_a <- filter[which(filter$metric >= 0),]      
      
      affordability_c1 <- metric_overall(filter,filter_a)
      affordability_c2 <- metric_group(filter,filter_a)
            
      ## - Affordabilty Overall
      affordability_c1[which(affordability_c1$metric == 1),c("percent_districts","extrap_districts")]

      ## - Affordability by Group (Locale)
      affordability_c2[which(affordability_c2$metric == 1),]
      
    ## 3. D. $/MBPS MEDIAN
      
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric <- filter$ia_monthly_cost_per_mbps
      filter$group <- filter$locale
      filter_a <- filter[which(filter$metric >= 0),]  

      affordability_d1 <- metric_overall_median(filter,filter_a)
      affordability_d2 <- metric_group_median(filter,filter_a)
      
      ## - Affordabilty Overall
      affordability_d1
      
      ## - Affordability by Group 
      affordability_d2
      
    ## 3. E. $/MBPS WEIGHTED AVERAGE
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric_numer <- filter$ia_monthly_cost_total
      filter$metric_denom <- filter$ia_bw_mbps_total_efc
      filter$group <- filter$locale
      filter_a <- filter[which(filter$exclude_from_ia_analysis==1 & filter$exclude_from_ia_cost_analysis==1),]  
      
      affordability_e1 <- metric_overall_weighted_average(filter,filter_a)
      affordability_e2 <- metric_group_weighted_average(filter,filter_a)
      
      ## - Affordabilty Overall
      affordability_e1
      
      ## - Affordability by Group (Locale)
      affordability_e2
        
    ## 3. F. IA $/STUDENT WEIGHTED AVERAGE
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric_numer <- filter$ia_monthly_cost_total
      filter$metric_denom <- filter$num_students
      filter$group <- filter$locale
      filter_a <- filter[which(filter$exclude_from_ia_analysis==1 & filter$exclude_from_ia_cost_analysis==1),] 
      
      affordability_f1 <- metric_overall_weighted_average(filter,filter_a)
      affordability_f2 <- metric_group_weighted_average(filter,filter_a)
      
      ## - Affordabilty Overall
      affordability_f1
      
      ## - Affordability by Group (Locale)
      affordability_f2
        
    ## 3. G. DISTRICT IA $/STUDENT WEIGHTED AVERAGE
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric_numer <- filter$ia_monthly_district_total
      filter$metric_denom <- filter$num_students
      filter$group <- filter$locale
      filter_a <- filter[which(filter$exclude_from_ia_analysis==1 & filter$exclude_from_ia_cost_analysis==1 & filter$ia_monthly_district_total >= 0),] 
      
      affordability_g1 <- metric_overall_weighted_average(filter,filter_a)
      affordability_g2 <- metric_group_weighted_average(filter,filter_a)
      
      ## - Affordabilty Overall
      affordability_g1
      
      ## - Affordability by Group (Locale)
      affordability_g2
        

## 4. WI-FI 
      
    ## 4. A. TOP LEFT/TITLE METRICS 
      filter <- dd_union[which(dd_union$year == 2017),]
      
      sufficient_wifi <- length(filter[which(filter$needs_wifi==0),"esh_id"])
      wifi_survey <- length(filter[which(filter$needs_wifi>=0),"esh_id"])
      budget_threshold <- .25
      districts_above_threshold <- length(filter[which(filter$percent_c2_budget_remaining>=budget_threshold & filter$percent_c2_budget_remaining<=1),"esh_id"])
      districts_funding_sample <- length(filter[which(filter$percent_c2_budget_remaining>=0 & filter$percent_c2_budget_remaining<=1),"esh_id"])
      districts_need_wifi_have_money <- length(filter[which(filter$percent_c2_budget_remaining>=0 & filter$percent_c2_budget_remaining<=1 & filter$needs_wifi==1),"esh_id"])
      
      ## - Percent Need Wi-fi
      sufficient_wifi/wifi_survey
      
      ## - Funding remaining
      sum(filter$c2_prediscount_remaining,na.rm=TRUE)
      
      ## - Districts with at least [budget_threshold] % remaining
      districts_above_threshold/districts_funding_sample
      
      ## - School districts that report insufficient wi-fi and have money left ## Note: this is not extrapolated and probably should be 
      districts_need_wifi_have_money
        
    ## 4. B. GRAPHS
      
    ## 4. C. WI-FI NEED - SOTS METHODOLOGY (exclude Nulls & No Datas & Extrapolate)
      filter <- dd_union[which(dd_union$year == 2017),]
      filter$metric <- filter$needs_wifi
      filter_s <- filter[which(filter$metric >= 0),]      
      
      wifi_c <- metric_overall(filter,filter_s)
      
      ## Note the school and student numbers should match what is in the dashboard but both are using a methodology we will likely not use
      
    ## 4. D. PERCENT FUNDING REMAINING (exclude Nulls & No Datas & Extrapolate)
      filter <- dd_union[which(dd_union$year == 2017),]
      budget_threshold <- .25
    
      for (i in 1:nrow(filter)){
        if(is.na(filter$percent_c2_budget_remaining[i]) == TRUE){
          filter$budget_group[i] <- NA
        } else if (filter$percent_c2_budget_remaining[i]==0){
          filter$budget_group[i] <- "0%"
        } else if (filter$percent_c2_budget_remaining[i]==1){
          filter$budget_group[i] <- "100%"
        } else if (filter$percent_c2_budget_remaining[i]< budget_threshold & filter$percent_c2_budget_remaining[i]>0){
          filter$budget_group[i] <- "< budget threshold"
        } else if (filter$percent_c2_budget_remaining[i]>= budget_threshold & filter$percent_c2_budget_remaining[i]<1){
          filter$budget_group[i] <- ">= budget threshold"
        } else {
          filter$budget_group[i] <- "error"
        }
      }
      
      filter$metric <- filter$budget_group
      filter_s <- filter[which(filter$percent_c2_budget_remaining >=0 & filter$percent_c2_budget_remaining <=1),] 
      
      wifi_d <- metric_overall(filter,filter_s)
      
    ## 4. E. WI-FI NEED x PERCENT FUNDING REMAINING
      filter <- dd_union[which(dd_union$year == 2017),]
      budget_threshold <- .25
      
      for (i in 1:nrow(filter)){
        if(is.na(filter$percent_c2_budget_remaining[i]) == TRUE){
          filter$budget_group[i] <- NA
        } else if (filter$percent_c2_budget_remaining[i]==0){
          filter$budget_group[i] <- "0%"
        } else if (filter$percent_c2_budget_remaining[i]==1){
          filter$budget_group[i] <- "100%"
        } else if (filter$percent_c2_budget_remaining[i]< budget_threshold & filter$percent_c2_budget_remaining[i]>0){
          filter$budget_group[i] <- "< budget threshold"
        } else if (filter$percent_c2_budget_remaining[i]>= budget_threshold & filter$percent_c2_budget_remaining[i]<1){
          filter$budget_group[i] <- ">= budget threshold"
        } else {
          filter$budget_group[i] <- "error"
        }
      }
      
      filter$metric <- filter$budget_group
      filter$group <- filter$needs_wifi
      filter_s <- filter[which(filter$percent_c2_budget_remaining >=0 & filter$percent_c2_budget_remaining <=1 & filter$needs_wifi >=0),] 
      
      wifi_d <- metric_group(filter,filter_s)
      ## since I removed nulls/NAs from both Needs Wi-fi & Percent Budget remaining the extrapolation isn't quite right. 
      ## the sum of population_districts for the two groups won't equal 13,117

      
      