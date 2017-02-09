## ==============================================================================================================================
##
## AFFORDABILITY: Students that would meet FCC goal if the affordability targets were achieved
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

## set current directory as the working directory
wd <- setwd(".")
setwd(wd)

##*********************************************************************************************************
## READ IN FILES

## Deluxe Districts files
dd.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/deluxe_districts/"
dd.files <- list.files(dd.directory)
dd.2015.files <- dd.files[grepl("2015-districts-deluxe", dd.files)]
dd.2016.files <- dd.files[grepl("2016-districts-deluxe", dd.files)]
ds.2016.files <- dd.files[grepl("2016-schools-deluxe", dd.files)]
## read in deluxe districts
dd.2015 <- read.csv(paste(dd.directory, dd.2015.files[length(dd.2015.files)], sep=''), as.is=T, header=T, stringsAsFactors=FALSE)
dd.2016 <- read.csv(paste(dd.directory, dd.2016.files[length(dd.2016.files)], sep=''), as.is=T, header=T, stringsAsFactors=FALSE)

## read in cost reference data
cost <- read.csv("../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/cost_lookup.csv", as.is=T, header=T)
cost$cost_per_circuit <- cost$circuit_size_mbps * cost$cost_per_mbps

##*********************************************************************************************************
## CALCULATE METRICS BY SOURCING FUNCTIONS

## make sure to subset to include_in_universe_of_districts first for 2016
dd.2016 <- dd.2016[dd.2016$include_in_universe_of_districts == TRUE,]
dd.2016 <- dd.2016[!dd.2016$district_type %in% c("BIE", "Charter"),]
dd.2016 <- dd.2016[!duplicated(dd.2016$esh_id),]
## take out DC in both years
dd.2016 <- dd.2016[dd.2016$postal_cd != 'DC',]

## keep all population
dd.2016.all <- dd.2016
## subset to districts "fit for analysis"
dd.2015 <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]

## fix dd.2015 monthly_ia_cost_per_mbps
dd.2015$ia_monthly_cost_per_mbps <- suppressWarnings(as.numeric(dd.2015$monthly_ia_cost_per_mbps, na.rm=T))
dd.2016$ia_monthly_cost_per_mbps <- as.numeric(dd.2016$ia_monthly_cost_per_mbps, na.rm=T)
## take out NA values for ia_monthly_cost_total
dd.2016.sub <- dd.2016[!is.na(dd.2016$ia_monthly_cost_total),]
dd.2015.sub <- dd.2015[!is.na(dd.2015$ia_monthly_cost_total),]

## function for solving bandwidth budget 'knapsack' problem
bw_knapsack <- function(ia_budget){
  ia_bw <- 0
  while (ia_budget > 0) {
    ## do something
    if (length(which(cost$cost_per_circuit <= ia_budget)) == 0) {
      break
    } else {
      ## maximum circuit cost that a district can afford within the budget
      index <- max(which(cost$cost_per_circuit <= ia_budget))
      ## add bandwidth
      ia_bw <- ia_bw + cost$circuit_size_mbps[index]
      ## subtract from budget
      ia_budget <- ia_budget - cost$cost_per_circuit[index]
    }
  }
  return(ia_bw)
}

## Function to apply Knapsack / SotS Affordability Goal 
three_datasets_for_real <- function(input){
  ## create target_bandwidth variable
  input$target_bandwidth <- sapply(input$ia_monthly_cost_total, function(x){bw_knapsack(x)})
  ## convert ia_monthly_cost_per_mbps to numeric
  #input$ia_monthly_cost_per_mbps <- as.numeric(input$ia_monthly_cost_per_mbps, na.rm = TRUE)
  
  ## are districts meeting $3 per Mbps Goal?
  input$affordability_goal_sots <- ifelse(input$ia_monthly_cost_per_mbps <= 3, 1, 0)
  
  ## are districts meeting the new Affordability Goal?
  input$affordability_goal_knapsack <- ifelse(input$ia_bw_mbps_total >= input$target_bandwidth, 1, 0)
  
  ## for districts spending less than $700,
  ## the standard is whether they are paying less than or equal to $14 per Mbps
  small <- which(input$ia_monthly_cost_total < 700) 
  input[small,]$affordability_goal_knapsack <- ifelse(input[small,]$ia_monthly_cost_per_mbps <= 14, 1, 0)
  
  ## give free credit
  free_ia <- which(input$exclude_from_ia_analysis == FALSE &
                     input$exclude_from_ia_cost_analysis == FALSE &
                     input$ia_monthly_cost_total == 0 &
                     input$ia_bw_mbps_total > 0)
  input$affordability_goal_knapsack[free_ia] <- 1
  
  restricted_cost <- which(input$exclude_from_ia_analysis == FALSE &
                             input$exclude_from_ia_cost_analysis == TRUE &
                             input$ia_monthly_cost_total == 0)
  input$affordability_goal_knapsack[restricted_cost] <- NA
  
  output <- input
  return(output)
}

dd.2015.sub <- three_datasets_for_real(dd.2015.sub)
dd.2016.sub <- three_datasets_for_real(dd.2016.sub)

dd.2015 <- dd.2015.sub
dd.2016 <- dd.2016.sub

dd.2016$knapsack_bw <- ifelse(dd.2016$ia_bw_mbps_total < dd.2016$target_bandwidth, dd.2016$target_bandwidth, dd.2016$ia_bw_mbps_total)
dd.2016$knapsack_bw_per_student <- (dd.2016$target_bandwidth*1000) / dd.2016$num_students
dd.2016$knapsack_meeting_goal_2014 <- ifelse(dd.2016$knapsack_bw_per_student >= 100, 1, 0)
dd.2016$knapsack_meeting_goal_2018 <- ifelse((dd.2016$ia_oversub_ratio * dd.2016$knapsack_bw_per_student) >= 1000, 1, 0)

dd.2016$num_students_knapsack_meeting_goal_2014 <- dd.2016$knapsack_meeting_goal_2014 * dd.2016$num_students
dd.2016$num_students_knapsack_meeting_goal_2018 <- dd.2016$knapsack_meeting_goal_2018 * dd.2016$num_students

dd.2016$currently_meeting_connectivity_2014 <- ifelse(dd.2016$ia_bandwidth_per_student_kbps >= 100, 1, 0)
## have to add concurrency factor for 2018
dd.2016$currently_meeting_connectivity_2018 <- ifelse((dd.2016$ia_oversub_ratio * dd.2016$ia_bandwidth_per_student_kbps) >= 1000, 1, 0)
dd.2016$students_currently_meeting_2014 <- dd.2016$currently_meeting_connectivity_2014 * dd.2016$num_students
dd.2016$students_currently_meeting_2018 <- dd.2016$currently_meeting_connectivity_2018 * dd.2016$num_students

## 2014 GOAL
## subset to districts not currently meeting the 2014 goal
dd.2016.sub.not.currently.meeting.2014 <- dd.2016[dd.2016$currently_meeting_connectivity_2014 == 0,]
sum(dd.2016.sub.not.currently.meeting.2014$num_students, na.rm=T)
## OF THOSE, how many students would be meeting the goal with the target bandwidth?
sum(dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014, na.rm=T)
## how many are still not?
sum(dd.2016.sub.not.currently.meeting.2014$num_students[dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014 == 0], na.rm=T)
nrow(dd.2016.sub.not.currently.meeting.2014[dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014 == 0,])
round(nrow(dd.2016.sub.not.currently.meeting.2014[dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014 == 0,]) /
  nrow(dd.2016.sub.not.currently.meeting.2014), 2)
## what percentage is that?
round(sum(dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014, na.rm=T) /
        sum(dd.2016.sub.not.currently.meeting.2014$num_students, na.rm=T), 2)
## apply the percentage to the extrapolated number of students not meeting goals
## in Ultimate Master: 7.4 M
11534180 * .64
## percentage still not?
sum(dd.2016.sub.not.currently.meeting.2014$num_students[dd.2016.sub.not.currently.meeting.2014$num_students_knapsack_meeting_goal_2014 == 0], na.rm=T) / sum(dd.2016.sub.not.currently.meeting.2014$num_students, na.rm=T)

## write out the data that do not switch to meeting
dd.2016.sub.not.meeting.either <- dd.2016.sub.not.currently.meeting.2014[which(dd.2016.sub.not.currently.meeting.2014$knapsack_meeting_goal_2014 == 0),]
write.csv(dd.2016.sub.not.meeting.either, "../data/2016_districts_not_currently_meeting_2014_goal_or_knapsack.csv", row.names=F)

## 2018 GOAL
## subset to districts not currently meeting the 2018 goal
dd.2016.sub.not.currently.meeting.2018 <- dd.2016[dd.2016$currently_meeting_connectivity_2018 == 0,]
sum(dd.2016.sub.not.currently.meeting.2018$num_students, na.rm=T)
## OF THOSE, how many students would be meeting the goal with the target bandwidth?
sum(dd.2016.sub.not.currently.meeting.2018$num_students_knapsack_meeting_goal_2018, na.rm=T)
## how many are still not?
sum(dd.2016.sub.not.currently.meeting.2018$num_students[dd.2016.sub.not.currently.meeting.2018$num_students_knapsack_meeting_goal_2018 == 0], na.rm=T)
## what percentage is that?
sum(dd.2016.sub.not.currently.meeting.2018$num_students_knapsack_meeting_goal_2018, na.rm=T) / sum(dd.2016.sub.not.currently.meeting.2018$num_students, na.rm=T)
## percentage still not?
sum(dd.2016.sub.not.currently.meeting.2018$num_students[dd.2016.sub.not.currently.meeting.2018$num_students_knapsack_meeting_goal_2018 == 0], na.rm=T)/ sum(dd.2016.sub.not.currently.meeting.2018$num_students, na.rm=T)
