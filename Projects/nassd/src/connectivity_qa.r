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


## 1. CONNECTIVITY 

  ## 1. A. TOP LEFT/TITLE METRICS
      dd_17 <- dd_union[which(dd_union$year == 2017),]
      dd_17$metric <- dd_17$meeting_2014_goal_no_oversub
      dd_17_a <- dd_17[which(dd_17$metric>=0),]
    
      connectivity_a <- metric_overall(dd_17,dd_17_a)
    
    ## - Total students meeting minimum connectivity goal of 100 kbps per student
    connectivity_a[2,"extrap_students"]
    ## - Percent of students meeting
    connectivity_a[2,"percent_students"]
    ## - Percent of districts meeting
    connectivity_a[2,"percent_districts"]
  
  ## 1. B. GRAPH
      dd_union_a <- dd_union
      dd_union_a$metric <- dd_union_a$meeting_2014_goal_no_oversub
      dd_union_a$group <- dd_union_a$year
      dd_union_a_s <- dd_union_a[which(dd_union_a$metric >= 1),]
    
      connectivity_b1 <- metric_group(dd_union_a,dd_union_a_s)
    
    ## - All of the SotS numbers are hard coded in/copied from previous reports
    ## - Current 2015
    connectivity_b1[which(connectivity_b1$group == "2015" & connectivity_b1$metric == 1),"percent_districts"]
    ## - Current 2016
    connectivity_b1[which(connectivity_b1$group == "2016" & connectivity_b1$metric == 1),"percent_districts"]
    ## - Current 2017
    connectivity_b1[which(connectivity_b1$group == "2017" & connectivity_b1$metric == 1),"percent_districts"]
    
  ## 1. C. MEETING 100 KBPS/STUDENT GOAL
      dd_17 <- dd_union[which(dd_union$year == 2017),]
      dd_17$metric <- dd_17$meeting_2014_goal_no_oversub
      dd_17$group <- dd_17$locale
      dd_17_a <- dd_17[which(dd_17$metric>=0),]
      
      connectivity_c1 <- metric_overall(dd_17,dd_17_a)  
      connectivity_c2 <- metric_group(dd_17,dd_17_a)
    
    ## - 100 kbps Goal Meeting Status Overall
    connectivity_c1[which(connectivity_c1$metric == 1),]
    
    ## - 100 kbps Goal Meeting Status by Group (Locale) 
    connectivity_c1[which(connectivity_c1$metric == 1),]
  
  ## 1. D. MEETING 1 MBPS/STUDENT GOAL
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric <- dd_16$meeting_2018_goal_oversub
      dd_16$group <- dd_16$district_size  
      dd_16_a <- dd_16[which(dd_16$metric>=0),]
      
      connectivity_d1 <- metric_overall(dd_16,dd_16_a)
      connectivity_d2 <- metric_group(dd_16,dd_16_a)
    
    ## - 1 Mbps Goal Meeting Status Overall 
    connectivity_d1[which(connectivity_d1$metric == 1),]
    
    ## - 1 Mbps Goal Meeting Status by Group (district size)
    connectivity_d2[which(connectivity_d2$metric == 1),]
  
  ## 1. E. MEETING 1 MBPS/STUDENT GOAL
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric <- dd_16$upgraded_to_meet_2014_goal
      dd_16$group <- dd_16$locale
      dd_16_a <- dd_16[which(dd_16$metric >=0),]    
    
      connectivity_e1 <- metric_overall(dd_16,dd_16_a)
      connectivity_e2 <- metric_group(dd_16,dd_16_a)    
  
      ## - Upgraded to meet the 100 kbps Goal Overall 
      connectivity_d1[which(connectivity_d1$metric == 1),]
      
      ## - Upgraded to meet the 100 kbps Goal by Group (locale)
      connectivity_d2[which(connectivity_d2$metric == 1),]  

## 2. FIBER 
      
  ## 2. A. TOP LEFT/TITLE METRICS
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      
      ## - Schools that do not have fiber connections - percent
      (sum(dd_16$num_campuses) - sum(dd_16$unscalable_campuses))/sum(dd_16$num_campuses)
      
      ## - Schools that do not have fiber - #
      sum(dd_16$unscalable_campuses)
      
  ## 2. B. GRAPHS
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_17 <- dd_union[which(dd_union$year == 2017),]
      
      ## - All of the SotS numbers are hard coded in/copied from previous reports
      
      ## - Schools that do not have fiber connects - percent
      ## - Current 2016
      (sum(dd_16$num_campuses) - sum(dd_16$unscalable_campuses))/sum(dd_16$num_campuses)
      ## - Current 2017
      ## COME BACK LATER, CAN'T GET TO WORK 
      #(sum(dd_17$num_campuses) - sum(dd_17$unscalable_campuses))/sum(dd_17$num_campuses)
      
      ## - Schools that do not have fiber connects - #
      ## - Current 2016
      sum(dd_16$unscalable_campuses)
      ## - Current 2017
      ## COME BACK LATER, CAN'T GET TO WORK 
      sum(dd_17$unscalable_campuses)
      
  ## 2. C. FIBER TARGET V NOT TARGET
        dd_16 <- dd_union[which(dd_union$year == 2016),]
        dd_16$metric <- dd_16$fiber_target_status
        dd_16$group <- dd_16$locale
        dd_16_a <- dd_16[which(dd_16$metric == "Target"|dd_16$metric == "Not Target"),]      
      
        fiber_a1 <- metric_overall(dd_16,dd_16_a)
        fiber_a2 <- metric_group(dd_16,dd_16_a)
        
      ## - % Fiber Overall
        fiber_a1[,c("metric","percent_districts","extrap_districts")] 
      
      ## - % Fiber By Group (locale)
        fiber_a2[,c("group","metric","percent_districts","extrap_districts")]
      
  ## 2. D. UNSCALABLE CAMPUSES
        dd_17 <- dd_union[which(dd_union$year == 2017),]
        dd_16 <- dd_union[which(dd_union$year == 2016),]
        
        dd_17_total_unscalable <- sum(dd_17$unscalable_campuses, na.rm=TRUE)
        dd_16_total_unscalable <- sum(dd_16$unscalable_campuses)
  
        dd_17_total_campuses <- sum(dd_17$num_campuses)
        dd_16_total_campuses <- sum(dd_16$num_campuses)
        
        A <- aggregate(unscalable_campuses ~ locale, data = dd_17, FUN = sum)
        B <- aggregate(num_campuses ~ locale, data = dd_17, FUN = sum)
        unscalable_group_17 <- merge(A,B)
        unscalable_group_17$percent_total_unscalable <- unscalable_group$unscalable_campuses/dd_17_total_unscalable
        unscalable_group_17$percent_of_campuses <- unscalable_group$unscalable_campuses/unscalable_group$num_campuses
        
        A <- aggregate(unscalable_campuses ~ locale, data = dd_16, FUN = sum)
        B <- aggregate(num_campuses ~ locale, data = dd_16, FUN = sum)
        unscalable_group_16 <- merge(A,B)
        unscalable_group_16$percent_total_unscalable <- unscalable_group$unscalable_campuses/dd_16_total_unscalable
        unscalable_group_16$percent_of_campuses <- unscalable_group$unscalable_campuses/unscalable_group$num_campuses
        
      ## - Unscalable Campuses by Group (locale)
        ## - 2016 
        unscalable_group_16
        
        ## - 2017
        unscalable_group_17
        
        
## 3.AFFORDABILITY 
        
    ## 3. A. TOP LEFT/TITLE METRICS 
        
      ## - Students that would have the bandwidth they need if their districts received national benchmark pricing
      
      ## - Median cost per Mbps
        
      ## - Percent districts meeting Knapsack
        
    ## 3. B. GRAPH 
        
      dd_union_a <- dd_union
      dd_union_a$metric <- dd_union_a$ia_monthly_cost_per_mbps
      dd_union_a$group <- dd_union_a$year
      dd_union_a_s <- dd_union_a[which(dd_union_a$metric > 0),]
    
      affordability_b <-metric_group_median(dd_union_a,dd_union_a_s)
              
      ## - Sots numbers are hard coded in/copied from last year
        
      ## - Current 2015
      affordability_b[1,c("group","metric")]
      
      ## - Current 2016
      affordability_b[2,c("group","metric")]
      
      ## - Current 2017
      affordability_b[3,c("group","metric")]
        
    ## 3. C. MEETING KNAPSACK

      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric <- dd_16$meeting_knapsack
      dd_16$group <- dd_16$locale
      dd_16_a <- dd_16[which(dd_16$metric >= 0),]      
      
      affordability_c1 <- metric_overall(dd_16,dd_16_a)
      affordability_c2 <- metric_group(dd_16,dd_16_a)
            
      ## - Affordabilty Overall
      affordability_c1[which(affordability_c1$metric == 1),]

      ## - Affordability by Group (Locale)
      affordability_c2[which(affordability_c2$metric == 1),]
      
    ## 3. D. $/MBPS MEDIAN
      
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric <- dd_16$ia_monthly_cost_per_mbps
      dd_16$group <- dd_16$locale
      dd_16_a <- dd_16[which(dd_16$metric >= 0),]  

      affordability_d1 <- metric_overall_median(dd_16,dd_16_a)
      affordability_d2 <- metric_group_median(dd_16,dd_16_a)
      
      ## - Affordabilty Overall
      affordability_d1
      
      ## - Affordability by Group (Locale)
      affordability_d2
      
    ## 3. E. $/MBPS WEIGHTED AVERAGE
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric_numer <- dd_16$ia_monthly_cost_total
      dd_16$metric_denom <- dd_16$ia_bw_mbps_total_efc
      dd_16$group <- dd_16$locale
      dd_16_a <- dd_16[which(dd_16$metric_numer > 0 & dd_16$metric_denom > 0 ),]  
      
      affordability_e1 <- metric_overall_weighted_average(dd_16,dd_16_a)
      affordability_e2 <- metric_group_weighted_average(dd_16,dd_16_a)
      
      ## - Affordabilty Overall
      affordability_e1
      
      ## - Affordability by Group (Locale)
      affordability_e2
        
    ## 3. F. IA $/STUDENT WEIGHTED AVERAGE
    
      #come back to when i can actually use dashboard  
        
    ## 3. G. DISTRICT IA $/STUDENT WEIGHTED AVERAGE
      
      #come back to when i can actually use dashboard 
        

## 4. WI-FI 
      
    ## 4. A. TOP LEFT/TITLE METRICS 
      
      ## -      
        
    ## 4. B. GRAPHS
      
    ## 4. C. WI-FI NEED - SOTS METHODOLOGY (exclude Nulls & No Datas & Extrapolate)
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      dd_16$metric <- dd_16$needs_wifi
      dd_16_a <- dd_16[which(dd_16$metric >= 0),]      
      
      wifi_c <- metric_overall(dd_16,dd_16_a)
      
      ## Note the school and student numbers should match what is in the dashboard but both are using a methodology we will likely not use
      
    ## 4. D. PERCENT FUNDING REMAINING
      dd_16 <- dd_union[which(dd_union$year == 2016),]
      budget_threshold  
      
      dd_16$metric <- dd_16$percent_c2_budget_remaining
      dd_16_a <- dd_16[which(dd_16$metric >= 0),]   
      
    ## 4. E. WI-FI NEED x PERCENT FUNDING REMAINING
      
      
      
      