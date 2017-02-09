## ==============================================================================================================================
##
## SERVICE PROVIDER SWITCHER ANALYSIS
##
## Analysis looking into Switchers, Upgrades, and Goal Status
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Org-wide Projects/Progress Tracking/MASTER_MASTER/code/")

##**************************************************************************************************************************************************
## READ IN FILES

## master
dta.dom <- read.csv("../data/service_provider_master.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## SUBSETS -- TO DO

## Rural
## Take out State Networks -- probably do this at the line item level but make sure we include this BW when calculating who is the primary

##**************************************************************************************************************************************************
## ANALYSIS

## OVERALL POPULATION:
nrow(dta.dom)
## Defined as the districts that were clean in both 2015 and 2016 data
## AND those districts that we could define a primary service provider for.

##========================================================================================================================================
## 1) SERVICE PROVIDER SWITCHERS:

## the overall population who changed service providers:
table(dta.dom$sp_change)
round(nrow(dta.dom[which(dta.dom$sp_change == 1),]) / nrow(dta.dom), 2)
## Where did it happen most? Calculate percentage of switches for each state
tab.switch <- aggregate(dta.dom$sp_change, by=list(dta.dom$postal_cd), FUN=mean)
names(tab.switch) <- c('postal_cd', 'percent_switched')
tab.switch$percent_switched <- round(tab.switch$percent_switched*100, 0)
tab.switch <- tab.switch[order(tab.switch$percent_switched, decreasing=T),]

##----------------------------------------------------------------
## SWITCHERS -> UPGRADES

## OF THE DISTRICTS THAT SWITCHED:
sub.switchers <- dta.dom[which(dta.dom$sp_change == 1),]
nrow(sub.switchers)
round(nrow(sub.switchers) / nrow(dta.dom), 2)
write.csv(sub.switchers, "../data/service_provider_switchers.csv", row.names=F)
  ## Upgraded
  table(sub.switchers$upgrade)
  round(nrow(sub.switchers[which(sub.switchers$upgrade == TRUE),]) / nrow(sub.switchers), 2)
  sub.switchers.upgrade <- sub.switchers[which(sub.switchers$upgrade == TRUE),]
    ## OF THE SWITCHERS WHO UPGRADED:
    ## HAD THE SAME IA PURPOSE ACROSS YEARS (Subset to eligible for cost analysis)
    sub.switchers.upgrade.cost <- sub.switchers.upgrade[which(!is.na(sub.switchers.upgrade$eligible_for_cost_per_mbps)),]
    round(nrow(sub.switchers.upgrade.cost) / nrow(sub.switchers.upgrade), 2)
    ## Mean, Median % total MRC change
    sub.switchers.upgrade.cost.mean <- sub.switchers.upgrade.cost[!is.infinite(sub.switchers.upgrade.cost$total.cost.change.perc),]
    median(sub.switchers.upgrade.cost.mean$total.cost.change.perc, na.rm=T)
    mean(sub.switchers.upgrade.cost.mean$total.cost.change.perc, na.rm=T)
    ## How many kept the same total monthly (recurring) cost
    table(sub.switchers.upgrade.cost$total_monthly_cost_2015 == sub.switchers.upgrade.cost$total_monthly_cost_2016)
    round(table(sub.switchers.upgrade.cost$total_monthly_cost_2015 == sub.switchers.upgrade.cost$total_monthly_cost_2016)[2] / nrow(sub.switchers.upgrade.cost), 2)
  ## how many had the same price (total cost)
  ## Did Not Upgrade
  switchers.no.up <- sub.switchers[which(sub.switchers$upgrade == FALSE),]
  nrow(switchers.no.up)
  round(nrow(switchers.no.up) / nrow(sub.switchers), 2)
    ## OF THE SWITCHERS WHO DID NOT UPGRADE:
    ## HAD THE SAME IA PURPOSE ACROSS YEARS (Subset to eligible for cost analysis)
    switchers.no.up.cost <- switchers.no.up[!is.na(switchers.no.up$eligible_for_cost_per_mbps),]
    nrow(switchers.no.up.cost)
    round(nrow(switchers.no.up.cost) / nrow(switchers.no.up), 2)
    ## Lowered Cost/Mbps
    table(switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2015 > switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2016)
    round(table(switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2015 > switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(switchers.no.up.cost), 2)
    ## How many kept the same total monthly (recurring) cost
    table(switchers.no.up.cost$total_monthly_cost_2015 == switchers.no.up.cost$total_monthly_cost_2016)
    round(table(switchers.no.up.cost$total_monthly_cost_2015 == switchers.no.up.cost$total_monthly_cost_2016)[2] / nrow(switchers.no.up.cost), 2)
    ## How many lowered the total monthly (recurring) cost?
    table(switchers.no.up.cost$total_monthly_cost_2015 > switchers.no.up.cost$total_monthly_cost_2016)
    round(table(switchers.no.up.cost$total_monthly_cost_2015 > switchers.no.up.cost$total_monthly_cost_2016)[2] / nrow(switchers.no.up.cost), 2)
    ##**RESEARCH STREAM: Why do they switch and not "upgrade" and didn't lower cost??
  
## OF THE DISTRICTS THAT DID NOT SWITCH:
sub.no.switchers <- dta.dom[dta.dom$sp_change == 0,]
nrow(sub.no.switchers)
round(nrow(sub.no.switchers) / nrow(dta.dom), 2)
  ## Upgraded 
  table(sub.no.switchers$upgrade)
  round(nrow(sub.switchers[sub.no.switchers$upgrade == TRUE,]) / nrow(sub.no.switchers), 2)
  sub.no.switchers.upgrade <- sub.no.switchers[which(sub.no.switchers$upgrade == TRUE),]
  ## OF THE NON-SWITCHERS WHO UPGRADED:
  ## HAD THE SAME IA PURPOSE ACROSS YEARS (Subset to eligible for cost analysis)
  sub.no.switchers.upgrade.cost <- sub.no.switchers.upgrade[which(!is.na(sub.no.switchers.upgrade$eligible_for_cost_per_mbps)),]
  round(nrow(sub.no.switchers.upgrade.cost) / nrow(sub.no.switchers.upgrade), 2)
  ## Mean, Median % total MRC change
  sub.no.switchers.upgrade.cost.mean <- sub.no.switchers.upgrade.cost[!is.infinite(sub.no.switchers.upgrade.cost$total.cost.change.perc),]
  median(sub.no.switchers.upgrade.cost.mean$total.cost.change.perc, na.rm=T)
  mean(sub.no.switchers.upgrade.cost.mean$total.cost.change.perc, na.rm=T)
  ## Did Not Upgrade
  no.switchers.no.up <- sub.no.switchers[sub.no.switchers$upgrade == FALSE,]
  nrow(no.switchers.no.up)
  round(nrow(no.switchers.no.up) / nrow(sub.no.switchers), 2)
    ## OF THE NON-SWITCHERS WHO DID NOT UPGRADE:
    ## HAD THE SAME IA PURPOSE ACROSS YEARS (Subset to eligible for cost analysis)
    no.switchers.no.up.cost <- no.switchers.no.up[!is.na(no.switchers.no.up$eligible_for_cost_per_mbps),]
    nrow(no.switchers.no.up.cost)
    round(nrow(no.switchers.no.up.cost) / nrow(no.switchers.no.up), 2)
    ## Lowered Cost/Mbps
    table(no.switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2015 > no.switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2016)
    round(table(no.switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2015 > no.switchers.no.up.cost$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(no.switchers.no.up.cost), 2)
      

##----------------------------------------------------------------
## SWITCHERS -> CONNECTIVITY

## OF THE DISTRICTS THAT SWITCHED:
sub.switchers <- dta.dom[dta.dom$sp_change == 1,]
nrow(sub.switchers)
round(nrow(sub.switchers) / nrow(dta.dom), 2)
  ## GOALS: Connectivity
    table(sub.switchers$meeting_goals_2015, sub.switchers$meeting_goals_2016)
    ## Were Meeting Connectivity Goals in 2015
    table(sub.switchers$meeting_goals_2015)
    round(nrow(sub.switchers[sub.switchers$meeting_goals_2015 == TRUE,]) / nrow(sub.switchers), 2)
    ## Were NOT Meeting Connectivity Goals in 2015
    table(sub.switchers$meeting_goals_2015)
    round(nrow(sub.switchers[sub.switchers$meeting_goals_2015 == FALSE,]) / nrow(sub.switchers), 2)
      ## OF THE SWITCHERS THAT WERE NOT MEETING CONNECTIVITY GOALS IN 2015:
      sub.switchers.no.2015.goals <- sub.switchers[sub.switchers$meeting_goals_2015 == FALSE,]
      sub.switchers.no.2015.goals <- sub.switchers.no.2015.goals[!is.na(sub.switchers.no.2015.goals$meeting_goals_2015),]
      ## Are Meeting Connectivity Goals in 2016
      table(sub.switchers.no.2015.goals$meeting_goals_2016)
      round(nrow(sub.switchers.no.2015.goals[sub.switchers.no.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.switchers.no.2015.goals), 2)
    
## OF THE DISTRICTS THAT DID NOT SWITCH:
sub.no.switchers <- dta.dom[dta.dom$sp_change == 0,]
nrow(sub.no.switchers)
round(nrow(sub.no.switchers) / nrow(dta.dom), 2)
  ## GOALS: Connectivity
    table(sub.no.switchers$meeting_goals_2015, sub.no.switchers$meeting_goals_2016)
    ## Were Meeting Connectivity Goals in 2015
    table(sub.no.switchers$meeting_goals_2015)
    round(nrow(sub.no.switchers[sub.no.switchers$meeting_goals_2015 == TRUE,]) / nrow(sub.no.switchers), 2)
    ## Were NOT Meeting Connectivity Goals in 2015
    table(sub.no.switchers$meeting_goals_2015)
    round(nrow(sub.no.switchers[sub.no.switchers$meeting_goals_2015 == FALSE,]) / nrow(sub.no.switchers), 2)
      ## OF THE SWITCHERS THAT WERE NOT MEETING CONNECTIVITY GOALS IN 2015:
      sub.no.switchers.no.2015.goals <- sub.no.switchers[sub.no.switchers$meeting_goals_2015 == FALSE,]
      sub.no.switchers.no.2015.goals <- sub.no.switchers.no.2015.goals[!is.na(sub.no.switchers.no.2015.goals$meeting_goals_2015),]
      ## Are Meeting Connectivity Goals in 2016
      table(sub.no.switchers.no.2015.goals$meeting_goals_2016)
      round(nrow(sub.no.switchers.no.2015.goals[sub.no.switchers.no.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.no.switchers.no.2015.goals), 2)
      

##----------------------------------------------------------------
## SWITCHERS -> AFFORDABILITY
      
## OF THE DISTRICTS THAT SWITCHED:
sub.switchers <- dta.dom[dta.dom$sp_change == 1,]
nrow(sub.switchers)
round(nrow(sub.switchers) / nrow(dta.dom), 2)
  ## GOALS: Affordability
    table(sub.switchers$affordability_goal_knapsack_2015, sub.switchers$affordability_goal_knapsack_2016)
    ## Were Meeting Affordability Goals in 2015
    table(sub.switchers$affordability_goal_knapsack_2015)
    round(nrow(sub.switchers[sub.switchers$affordability_goal_knapsack_2015 == TRUE,]) / nrow(sub.switchers), 2)
    ## Were NOT Meeting Affordability Goals in 2015
    table(sub.switchers$affordability_goal_knapsack_2015)
    round(nrow(sub.switchers[sub.switchers$affordability_goal_knapsack_2015 == FALSE,]) / nrow(sub.switchers), 2)
      ## OF THE SWITCHERS THAT WERE NOT MEETING Affordability GOALS IN 2015:
      sub.switchers.no.2015.goals <- sub.switchers[sub.switchers$affordability_goal_knapsack_2015 == FALSE,]
      sub.switchers.no.2015.goals <- sub.switchers.no.2015.goals[!is.na(sub.switchers.no.2015.goals$affordability_goal_knapsack_2015),]
      ## Are Meeting Affordability Goals in 2016
      table(sub.switchers.no.2015.goals$affordability_goal_knapsack_2016)
      round(nrow(sub.switchers.no.2015.goals[sub.switchers.no.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.switchers.no.2015.goals), 2)
      
## OF THE DISTRICTS THAT DID NOT SWITCH:
sub.no.switchers <- dta.dom[dta.dom$sp_change == 0,]
nrow(sub.no.switchers)
round(nrow(sub.no.switchers) / nrow(dta.dom), 2)
  ## GOALS: Affordability
    table(sub.no.switchers$affordability_goal_knapsack_2015, sub.no.switchers$affordability_goal_knapsack_2016)
    ## Were Meeting Affordability Goals in 2015
    table(sub.no.switchers$affordability_goal_knapsack_2015)
    round(nrow(sub.no.switchers[sub.no.switchers$affordability_goal_knapsack_2015 == TRUE,]) / nrow(sub.no.switchers), 2)
    ## Were NOT Meeting Affordability Goals in 2015
    table(sub.no.switchers$affordability_goal_knapsack_2015)
    round(nrow(sub.no.switchers[sub.no.switchers$affordability_goal_knapsack_2015 == FALSE,]) / nrow(sub.no.switchers), 2)
      ## OF THE SWITCHERS THAT WERE NOT MEETING Affordability GOALS IN 2015:
      sub.no.switchers.no.2015.goals <- sub.no.switchers[sub.no.switchers$affordability_goal_knapsack_2015 == FALSE,]
      sub.no.switchers.no.2015.goals <- sub.no.switchers.no.2015.goals[!is.na(sub.no.switchers.no.2015.goals$affordability_goal_knapsack_2015),]
      ## Are Meeting Affordability Goals in 2016
      table(sub.no.switchers.no.2015.goals$affordability_goal_knapsack_2016)
      round(nrow(sub.no.switchers.no.2015.goals[sub.no.switchers.no.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.no.switchers.no.2015.goals), 2)

      
##----------------------------------------------------------------
## SWITCHERS -> TOTAL RECURRING COST & COST PER MBPS

## OF THE OVERALL POPULATION:
nrow(dta.dom)
## SUBSET TO DISTRICTS THAT HAD THE SAME IA PURPOSE ACROSS YEARS (ELIGIBLE FOR COST ANALYSIS)
dta.dom.cost <- dta.dom[dta.dom$eligible_for_cost_per_mbps == 1 & !is.na(dta.dom$eligible_for_cost_per_mbps),]
nrow(dta.dom.cost)
round(nrow(dta.dom.cost) / nrow(dta.dom), 2)
## TOTAL POPULATION THAT LOWERED TOTAL MONTHLY (RECURRING) COST
table(dta.dom.cost$total_monthly_cost_2015 > dta.dom.cost$total_monthly_cost_2016)
round(table(dta.dom.cost$total_monthly_cost_2015 > dta.dom.cost$total_monthly_cost_2016)[2] / nrow(dta.dom.cost), 2)
## median % decrease
median(dta.dom.cost$total.cost.change.perc[dta.dom.cost$total_monthly_cost_2015 > dta.dom.cost$total_monthly_cost_2016 &
                                             !is.infinite(dta.dom.cost$total.cost.change.perc)])
## mean % decrease
round(mean(dta.dom.cost$total.cost.change.perc[dta.dom.cost$total_monthly_cost_2015 > dta.dom.cost$total_monthly_cost_2016 &
                                             !is.infinite(dta.dom.cost$total.cost.change.perc)]), 2)
## TOTAL POPULATION THAT LOWERED COST PER MBPS
table(dta.dom.cost$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost$sp_ia_monthly_cost_per_mbps_2016)
round(table(dta.dom.cost$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost), 2)
## median % decrease
median(dta.dom.cost$cost.per.mbps.change.perc[dta.dom.cost$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost$sp_ia_monthly_cost_per_mbps_2016 &
                                           !is.infinite(dta.dom.cost$cost.per.mbps.change.perc)])
## mean % decrease
round(mean(dta.dom.cost$cost.per.mbps.change.perc[dta.dom.cost$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost$sp_ia_monthly_cost_per_mbps_2016 &
                                                !is.infinite(dta.dom.cost$cost.per.mbps.change.perc)]), 2)
  
  ## OF THE DISTRICTS THAT SWITCHED:
  sub.switchers <- dta.dom[dta.dom$sp_change == 1,]
  nrow(sub.switchers)
  round(nrow(sub.switchers) / nrow(dta.dom), 2)
  ## eligible for cost analysis
  dta.dom.cost.switch <- dta.dom.cost[dta.dom.cost$sp_change == 1,]
  nrow(dta.dom.cost.switch)
  round(nrow(dta.dom.cost.switch) / nrow(sub.switchers), 2)
  ## THAT LOWERED TOTAL MONTHLY (RECURRING) COST
  table(dta.dom.cost.switch$total_monthly_cost_2015 > dta.dom.cost.switch$total_monthly_cost_2016)
  round(table(dta.dom.cost.switch$total_monthly_cost_2015 > dta.dom.cost.switch$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.switch), 2)
  ## median % decrease
  median(dta.dom.cost.switch$total.cost.change.perc[dta.dom.cost.switch$total_monthly_cost_2015 > dta.dom.cost.switch$total_monthly_cost_2016 &
                                                      !is.infinite(dta.dom.cost.switch$total.cost.change.perc)])
  ## mean % decrease
  round(mean(dta.dom.cost.switch$total.cost.change.perc[dta.dom.cost.switch$total_monthly_cost_2015 > dta.dom.cost.switch$total_monthly_cost_2016 &
                                                      !is.infinite(dta.dom.cost.switch$total.cost.change.perc)]), 2)
  ## THAT LOWERED COST PER MBPS
  table(dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2016)
  round(table(dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.switch), 2)
  ## median % decrease
  median(dta.dom.cost.switch$cost.per.mbps.change.perc[dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2016 &
                                                    !is.infinite(dta.dom.cost.switch$cost.per.mbps.change.perc)])
  ## mean % decrease
  round(mean(dta.dom.cost.switch$cost.per.mbps.change.perc[dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch$sp_ia_monthly_cost_per_mbps_2016 &
                                                         !is.infinite(dta.dom.cost.switch$cost.per.mbps.change.perc)]), 2)
    
    ## OF SWITCHERS WHO UPGRADED:
    sub.switchers.upgrade <- sub.switchers[sub.switchers$upgrade == TRUE,]
    nrow(sub.switchers.upgrade)
    round(nrow(sub.switchers.upgrade) / nrow(sub.switchers), 2)
    ## eligible for cost analysis
    dta.dom.cost.switch.upgrade <- dta.dom.cost.switch[dta.dom.cost.switch$upgrade == TRUE,]
    nrow(dta.dom.cost.switch.upgrade)
    round(nrow(dta.dom.cost.switch.upgrade) / nrow(sub.switchers.upgrade), 2)
    ## THAT LOWERED TOTAL MONTHLY (RECURRING) COST
    table(dta.dom.cost.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.upgrade$total_monthly_cost_2016)
    round(table(dta.dom.cost.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.upgrade$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.switch.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.switch.upgrade$total.cost.change.perc[dta.dom.cost.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.upgrade$total_monthly_cost_2016 &
                                                                !is.infinite(dta.dom.cost.switch.upgrade$total.cost.change.perc)])
    ## mean % decrease
    round(mean(dta.dom.cost.switch.upgrade$total.cost.change.perc[dta.dom.cost.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.upgrade$total_monthly_cost_2016 &
                                                                !is.infinite(dta.dom.cost.switch.upgrade$total.cost.change.perc)]), 2)
    ## THAT LOWERED COST PER MBPS
    table(dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016)
    round(table(dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.switch.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.switch.upgrade$cost.per.mbps.change[dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                              !is.infinite(dta.dom.cost.switch.upgrade$cost.per.mbps.change)])
    ## mean % decrease
    round(mean(dta.dom.cost.switch.upgrade$cost.per.mbps.change[dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                              !is.infinite(dta.dom.cost.switch.upgrade$cost.per.mbps.change)]), 2)
    
    ## OF SWITCHERS WHO DIDN'T UPGRADE:
    sub.switchers.no.upgrade <- sub.switchers[sub.switchers$upgrade == FALSE,]
    nrow(sub.switchers.no.upgrade)
    round(nrow(sub.switchers.no.upgrade) / nrow(sub.switchers), 2)
    ## eligible for cost analysis
    dta.dom.cost.switch.no.upgrade <- dta.dom.cost.switch[dta.dom.cost.switch$upgrade == FALSE,]
    nrow(dta.dom.cost.switch.no.upgrade)
    round(nrow(dta.dom.cost.switch.no.upgrade) / nrow(sub.switchers.no.upgrade), 2)
    ## THAT LOWERED TOTAL MONTHLY (RECURRING) COST
    table(dta.dom.cost.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.no.upgrade$total_monthly_cost_2016)
    round(table(dta.dom.cost.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.no.upgrade$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.switch.no.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.switch.no.upgrade$total.cost.change.perc[dta.dom.cost.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.no.upgrade$total_monthly_cost_2016 &
                                                                   !is.infinite(dta.dom.cost.switch.no.upgrade$total.cost.change.perc)])
    ## mean % decrease
    round(mean(dta.dom.cost.switch.no.upgrade$total.cost.change.perc[dta.dom.cost.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.switch.no.upgrade$total_monthly_cost_2016 &
                                                                   !is.infinite(dta.dom.cost.switch.no.upgrade$total.cost.change.perc)]), 2)
    ## THAT LOWERED COST PER MBPS
    table(dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016)
    round(table(dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.switch.no.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.switch.no.upgrade$cost.per.mbps.change[dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                 !is.infinite(dta.dom.cost.switch.no.upgrade$cost.per.mbps.change)])
    ## mean % decrease
    round(mean(dta.dom.cost.switch.no.upgrade$cost.per.mbps.change[dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                 !is.infinite(dta.dom.cost.switch.no.upgrade$cost.per.mbps.change)]), 2)
    
  ## OF THE DISTRICTS THAT DID NOT SWITCH:
  sub.no.switch <- dta.dom[dta.dom$sp_change == 0,]
  nrow(sub.no.switch)
  round(nrow(sub.no.switch) / nrow(dta.dom), 2)
  ## eligible for cost analysis
  dta.dom.cost.no.switch <- dta.dom.cost[dta.dom.cost$sp_change == 0,]
  nrow(dta.dom.cost.no.switch)
  round(nrow(dta.dom.cost.no.switch) / nrow(sub.no.switch), 2)
  ## NON-SWITCHERS THAT LOWERED TOTAL MONTHLY (RECURRING) COST
  table(dta.dom.cost.no.switch$total_monthly_cost_2015 > dta.dom.cost.no.switch$total_monthly_cost_2016)
  round(table(dta.dom.cost.no.switch$total_monthly_cost_2015 > dta.dom.cost.no.switch$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.no.switch), 2)
  ## median % decrease
  median(dta.dom.cost.no.switch$total.cost.change.perc[dta.dom.cost.no.switch$total_monthly_cost_2015 > dta.dom.cost.no.switch$total_monthly_cost_2016 &
                                                         !is.infinite(dta.dom.cost.no.switch$total.cost.change.perc)])
  ## mean % decrease
  round(mean(dta.dom.cost.no.switch$total.cost.change.perc[dta.dom.cost.no.switch$total_monthly_cost_2015 > dta.dom.cost.no.switch$total_monthly_cost_2016 &
                                                         !is.infinite(dta.dom.cost.no.switch$total.cost.change.perc)]), 2)
  ## THAT LOWERED COST PER MBPS
  table(dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2016)
  round(table(dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.no.switch), 2)
  ## median % decrease
  median(dta.dom.cost.no.switch$cost.per.mbps.change[dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2016 &
                                                       !is.infinite(dta.dom.cost.no.switch$cost.per.mbps.change)])
  ## mean % decrease
  round(mean(dta.dom.cost.no.switch$cost.per.mbps.change[dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch$sp_ia_monthly_cost_per_mbps_2016 &
                                                       !is.infinite(dta.dom.cost.no.switch$cost.per.mbps.change)]), 2)
  
    ## OF THE NON-SWITCHERS WHO UPGRADED:
    sub.no.switch.upgrade <- sub.no.switch[sub.no.switch$upgrade == TRUE,]
    nrow(sub.no.switch.upgrade)
    round(nrow(sub.no.switch.upgrade) / nrow(sub.no.switch), 2)
    ## eligible for cost analysis
    dta.dom.cost.no.switch.upgrade <- dta.dom.cost.no.switch[dta.dom.cost.no.switch$upgrade == TRUE,]
    nrow(dta.dom.cost.no.switch.upgrade)
    round(nrow(dta.dom.cost.no.switch.upgrade) / nrow(sub.no.switch.upgrade), 2)
    ## THAT LOWERED TOTAL MONTHLY (RECURRING) COST
    table(dta.dom.cost.no.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.upgrade$total_monthly_cost_2016)
    round(table(dta.dom.cost.no.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.upgrade$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.no.switch.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.no.switch.upgrade$total.cost.change.perc[dta.dom.cost.no.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.upgrade$total_monthly_cost_2016 &
                                                                   !is.infinite(dta.dom.cost.no.switch.upgrade$total.cost.change.perc)])
    ## mean % decrease
    round(mean(dta.dom.cost.no.switch.upgrade$total.cost.change.perc[dta.dom.cost.no.switch.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.upgrade$total_monthly_cost_2016 &
                                                                   !is.infinite(dta.dom.cost.no.switch.upgrade$total.cost.change.perc)]), 2)
    ## THAT LOWERED COST PER MBPS
    table(dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016)
    round(table(dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.no.switch.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.no.switch.upgrade$cost.per.mbps.change[dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                 !is.infinite(dta.dom.cost.no.switch.upgrade$cost.per.mbps.change)])
    ## mean % decrease
    round(mean(dta.dom.cost.no.switch.upgrade$cost.per.mbps.change[dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                 !is.infinite(dta.dom.cost.no.switch.upgrade$cost.per.mbps.change)]), 2)
    
    
    ## OF THE NON-SWITCHERS WHO DIDN'T UPGRADE:
    sub.no.switch.no.upgrade <- sub.no.switch[sub.no.switch$upgrade == FALSE,]
    nrow(sub.no.switch.no.upgrade)
    round(nrow(sub.no.switch.no.upgrade) / nrow(sub.no.switch), 2)
    ## eligible for cost analysis
    dta.dom.cost.no.switch.no.upgrade <- dta.dom.cost.no.switch[dta.dom.cost.no.switch$upgrade == FALSE,]
    nrow(dta.dom.cost.no.switch.no.upgrade)
    round(nrow(dta.dom.cost.no.switch.no.upgrade) / nrow(sub.no.switch.no.upgrade), 2)
    ## THAT LOWERED TOTAL MONTHLY (RECURRING) COST
    table(dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2016)
    round(table(dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2016)[2] / nrow(dta.dom.cost.no.switch.no.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.no.switch.no.upgrade$total.cost.change.perc[dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2016 &
                                                                      !is.infinite(dta.dom.cost.no.switch.no.upgrade$total.cost.change.perc)])
    ## mean % decrease
    round(mean(dta.dom.cost.no.switch.no.upgrade$total.cost.change.perc[dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2015 > dta.dom.cost.no.switch.no.upgrade$total_monthly_cost_2016 &
                                                                      !is.infinite(dta.dom.cost.no.switch.no.upgrade$total.cost.change.perc)]), 2)
    ## THAT LOWERED COST PER MBPS
    table(dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016)
    round(table(dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(dta.dom.cost.no.switch.no.upgrade), 2)
    ## median % decrease
    median(dta.dom.cost.no.switch.no.upgrade$cost.per.mbps.change[dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                    !is.infinite(dta.dom.cost.no.switch.no.upgrade$cost.per.mbps.change)])
    ## mean % decrease
    round(mean(dta.dom.cost.no.switch.no.upgrade$cost.per.mbps.change[dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2015 > dta.dom.cost.no.switch.no.upgrade$sp_ia_monthly_cost_per_mbps_2016 &
                                                                    !is.infinite(dta.dom.cost.no.switch.no.upgrade$cost.per.mbps.change)]), 2)
    
    
##========================================================================================================================================
## 2) UPGRADES:
    
## the overall population who upgraded:
table(dta.dom$upgrade)
round(nrow(dta.dom[dta.dom$upgrade == TRUE,]) / nrow(dta.dom), 2)
## Where did it happen most? Calculate percentage of switches for each state
dta.dom$counter <- ifelse(dta.dom$upgrade == TRUE, 1, 0)
tab.upgrade <- aggregate(dta.dom$counter, by=list(dta.dom$postal_cd), FUN=mean)
names(tab.upgrade) <- c('postal_cd', 'percent_upgraded')
tab.upgrade$percent_upgraded <- round(tab.upgrade$percent_upgraded*100, 0)
tab.upgrade <- tab.upgrade[order(tab.upgrade$percent_upgraded, decreasing=T),]

##----------------------------------------------------------------
## UPGRADES -> SWITCHERS

## OVERALL MAGNITUDE OF UPGRADERS:
median(dta.dom$bw.change, na.rm=T)
mean(dta.dom$bw.change, na.rm=T)

## OF THE DISTRICTS THAT UPGRADED:
sub.upgraders <- dta.dom[dta.dom$upgrade == TRUE,]
nrow(sub.upgraders)
round(nrow(sub.upgraders) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.upgraders$sp_change)
  round(nrow(sub.upgraders[sub.upgraders$sp_change == 1,]) / nrow(sub.upgraders), 2)
    ## OF THE UPGRADERS WHO SWITCHED:
    sub.upgraders.switch <- sub.upgraders[sub.upgraders$sp_change == 1,]
    ## What was the median BW change?
    median(sub.upgraders.switch$bw.change, na.rm=T)
    mean(sub.upgraders.switch$bw.change, na.rm=T)
  ## Non-Switchers
  table(sub.upgraders$sp_change)
  round(nrow(sub.upgraders[sub.upgraders$sp_change == 0,]) / nrow(sub.upgraders), 2)
    ## OF THE UPGRADERS WHO DID NOT SWITCH:
    sub.upgraders.no.switch <- sub.upgraders[sub.upgraders$sp_change == 0,]
    ## What was the median BW change?
    median(sub.upgraders.no.switch$bw.change, na.rm=T)
    mean(sub.upgraders.no.switch$bw.change, na.rm=T)

## OF THE DISTRICTS THAT DID NOT UPGRADE:
sub.no.upgraders <- dta.dom[dta.dom$upgrade == FALSE,]
nrow(sub.no.upgraders)
round(nrow(sub.no.upgraders) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.no.upgraders$sp_change)
  round(nrow(sub.no.upgraders[sub.no.upgraders$sp_change == 1,]) / nrow(sub.no.upgraders), 2)

    
##----------------------------------------------------------------
## UPGRADES -> SWITCHERS -> CONNECTIVITY

## OF THE DISTRICTS THAT UPGRADED:
sub.upgraders <- dta.dom[dta.dom$upgrade == TRUE,]
nrow(sub.upgraders)
round(nrow(sub.upgraders) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.upgraders$sp_change)
  round(nrow(sub.upgraders[sub.upgraders$sp_change == 1,]) / nrow(sub.upgraders), 2)
    ## OF THE DISTRICTS THAT UPGRADED AND SWITCHED:
    sub.upgraders.switch <- sub.upgraders[sub.upgraders$sp_change == 1,]
      ## GOALS: Connectivity
      table(sub.upgraders.switch$meeting_goals_2015, sub.upgraders.switch$meeting_goals_2016)
      ## Were Meeting Connectivity Goals in 2015
      table(sub.upgraders.switch$meeting_goals_2015)
      round(nrow(sub.upgraders.switch[sub.upgraders.switch$meeting_goals_2015 == TRUE,]) / nrow(sub.upgraders.switch), 2)
        ## OF THE UPGRADER-SWITCHERS THAT WERE MEETING CONNECTIVITY GOALS IN 2015:
        sub.upgraders.switch.2015.goals <- sub.upgraders.switch[sub.upgraders.switch$meeting_goals_2015 == TRUE,]
        sub.upgraders.switch.2015.goals <- sub.upgraders.switch.2015.goals[!is.na(sub.upgraders.switch.2015.goals$meeting_goals_2015),]
        ## Are Meeting Connectivity Goals in 2016
        table(sub.upgraders.switch.2015.goals$meeting_goals_2016)
        round(nrow(sub.upgraders.switch.2015.goals[sub.upgraders.switch.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.upgraders.switch.2015.goals), 2)
      ## Were NOT Meeting Connectivity Goals in 2015
      table(sub.upgraders.switch$meeting_goals_2015)
      round(nrow(sub.upgraders.switch[sub.upgraders.switch$meeting_goals_2015 == FALSE,]) / nrow(sub.upgraders.switch), 2)
        ## OF THE UPGRADER-SWITCHERS THAT WERE NOT MEETING CONNECTIVITY GOALS IN 2015:
        sub.upgraders.switch.no.2015.goals <- sub.upgraders.switch[sub.upgraders.switch$meeting_goals_2015 == FALSE,]
        sub.upgraders.switch.no.2015.goals <- sub.upgraders.switch.no.2015.goals[!is.na(sub.upgraders.switch.no.2015.goals$meeting_goals_2015),]
        ## Are Meeting Connectivity Goals in 2016
        table(sub.upgraders.switch.no.2015.goals$meeting_goals_2016)
        round(nrow(sub.upgraders.switch.no.2015.goals[sub.upgraders.switch.no.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.upgraders.switch.no.2015.goals), 2)
  
    ## OF THE DISTRICTS WHO UPGRADED AND DID NOT SWITCH:
    sub.upgraders.no.switch <- sub.upgraders[sub.upgraders$sp_change == 0,]
      ## GOALS: Connectivity
      table(sub.upgraders.no.switch$meeting_goals_2015, sub.upgraders.no.switch$meeting_goals_2016)
      ## Were Meeting Connectivity Goals in 2015
      table(sub.upgraders.no.switch$meeting_goals_2015)
      round(nrow(sub.upgraders.no.switch[sub.upgraders.no.switch$meeting_goals_2015 == TRUE,]) / nrow(sub.upgraders.no.switch), 2)
        ## OF THE UPGRADER-SWITCHERS THAT WERE MEETING CONNECTIVITY GOALS IN 2015:
        sub.upgraders.no.switch.2015.goals <- sub.upgraders.no.switch[sub.upgraders.no.switch$meeting_goals_2015 == TRUE,]
        sub.upgraders.no.switch.2015.goals <- sub.upgraders.no.switch.2015.goals[!is.na(sub.upgraders.no.switch.2015.goals$meeting_goals_2015),]
        ## Are Meeting Connectivity Goals in 2016
        table(sub.upgraders.no.switch.2015.goals$meeting_goals_2016)
        round(nrow(sub.upgraders.no.switch.2015.goals[sub.upgraders.no.switch.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.upgraders.no.switch.2015.goals), 2)
    ## Were NOT Meeting Connectivity Goals in 2015
    table(sub.upgraders.no.switch$meeting_goals_2015)
    round(nrow(sub.upgraders.no.switch[sub.upgraders.no.switch$meeting_goals_2015 == FALSE,]) / nrow(sub.upgraders.no.switch), 2)
      ## OF THE UPGRADER-SWITCHERS THAT WERE NOT MEETING CONNECTIVITY GOALS IN 2015:
      sub.upgraders.no.switch.no.2015.goals <- sub.upgraders.no.switch[sub.upgraders.no.switch$meeting_goals_2015 == FALSE,]
      sub.upgraders.no.switch.no.2015.goals <- sub.upgraders.no.switch.no.2015.goals[!is.na(sub.upgraders.no.switch.no.2015.goals$meeting_goals_2015),]
      ## Are Meeting Connectivity Goals in 2016
      table(sub.upgraders.no.switch.no.2015.goals$meeting_goals_2016)
      round(nrow(sub.upgraders.no.switch.no.2015.goals[sub.upgraders.no.switch.no.2015.goals$meeting_goals_2016 == TRUE,]) / nrow(sub.upgraders.no.switch.no.2015.goals), 2)


##----------------------------------------------------------------
## UPGRADES -> SWITCHERS -> AFFORABILITY, take out NA values in denominator
      
## OF THE DISTRICTS THAT UPGRADED:
sub.upgraders <- dta.dom[dta.dom$upgrade == TRUE,]
nrow(sub.upgraders)
round(nrow(sub.upgraders) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.upgraders$sp_change)
  round(nrow(sub.upgraders[sub.upgraders$sp_change == 1,]) / nrow(sub.upgraders), 2)
    ## OF THE DISTRICTS THAT UPGRADED AND SWITCHED:
    sub.upgraders.switch <- sub.upgraders[sub.upgraders$sp_change == 1,]
      ## GOALS: Affordability
      table(sub.upgraders.switch$affordability_goal_knapsack_2015, sub.upgraders.switch$affordability_goal_knapsack_2016)
      ## Were Meeting Affordability Goals in 2015
      table(sub.upgraders.switch$affordability_goal_knapsack_2015)
      round(nrow(sub.upgraders.switch[sub.upgraders.switch$affordability_goal_knapsack_2015 == TRUE,]) / nrow(sub.upgraders.switch), 2)
        ## OF THE UPGRADER-SWITCHERS THAT WERE MEETING AFFORDABILITY GOALS IN 2015:
        sub.upgraders.switch.2015.goals <- sub.upgraders.switch[sub.upgraders.switch$affordability_goal_knapsack_2015 == TRUE,]
        sub.upgraders.switch.2015.goals <- sub.upgraders.switch.2015.goals[!is.na(sub.upgraders.switch.2015.goals$affordability_goal_knapsack_2015),]
        ## Are Meeting Affordability Goals in 2016
        table(sub.upgraders.switch.2015.goals$affordability_goal_knapsack_2016)
        round(nrow(sub.upgraders.switch.2015.goals[sub.upgraders.switch.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.upgraders.switch.2015.goals), 2)
      ## Were NOT Meeting Affordability Goals in 2015
      table(sub.upgraders.switch$affordability_goal_knapsack_2015)
      round(nrow(sub.upgraders.switch[sub.upgraders.switch$affordability_goal_knapsack_2015 == FALSE,]) / nrow(sub.upgraders.switch), 2)
        ## OF THE UPGRADER-SWITCHERS THAT WERE NOT MEETING AFFORDABILITY GOALS IN 2015:
        sub.upgraders.switch.no.2015.goals <- sub.upgraders.switch[sub.upgraders.switch$affordability_goal_knapsack_2015 == FALSE,]
        sub.upgraders.switch.no.2015.goals <- sub.upgraders.switch.no.2015.goals[!is.na(sub.upgraders.switch.no.2015.goals$affordability_goal_knapsack_2015),]
        ## Are Meeting Affordability Goals in 2016
        table(sub.upgraders.switch.no.2015.goals$affordability_goal_knapsack_2016)
        round(nrow(sub.upgraders.switch.no.2015.goals[sub.upgraders.switch.no.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.upgraders.switch.no.2015.goals), 2)
      
  ## OF THE DISTRICTS WHO UPGRADED AND DID NOT SWITCH:
  sub.upgraders.no.switch <- sub.upgraders[sub.upgraders$sp_change == 0,]
    ## GOALS: Affordability
    table(sub.upgraders.no.switch$affordability_goal_knapsack_2015, sub.upgraders.no.switch$affordability_goal_knapsack_2016)
    ## Were Meeting Affordability Goals in 2015
    table(sub.upgraders.no.switch$affordability_goal_knapsack_2015)
    round(nrow(sub.upgraders.no.switch[sub.upgraders.no.switch$affordability_goal_knapsack_2015 == TRUE,]) / nrow(sub.upgraders.no.switch), 2)
      ## OF THE UPGRADER-SWITCHERS THAT WERE MEETING AFFORDABILITY GOALS IN 2015:
      sub.upgraders.no.switch.2015.goals <- sub.upgraders.no.switch[sub.upgraders.no.switch$affordability_goal_knapsack_2015 == TRUE,]
      sub.upgraders.no.switch.2015.goals <- sub.upgraders.no.switch.2015.goals[!is.na(sub.upgraders.no.switch.2015.goals$affordability_goal_knapsack_2015),]
      ## Are Meeting Affordability Goals in 2016
      table(sub.upgraders.no.switch.2015.goals$affordability_goal_knapsack_2016)
      round(nrow(sub.upgraders.no.switch.2015.goals[sub.upgraders.no.switch.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.upgraders.no.switch.2015.goals), 2)
    ## Were NOT Meeting Affordability Goals in 2015
    table(sub.upgraders.no.switch$affordability_goal_knapsack_2015)
    round(nrow(sub.upgraders.no.switch[sub.upgraders.no.switch$affordability_goal_knapsack_2015 == FALSE,]) / nrow(sub.upgraders.no.switch), 2)
      ## OF THE UPGRADER-SWITCHERS THAT WERE NOT MEETING AFFORDABILITY GOALS IN 2015:
      sub.upgraders.no.switch.no.2015.goals <- sub.upgraders.no.switch[sub.upgraders.no.switch$affordability_goal_knapsack_2015 == FALSE,]
      sub.upgraders.no.switch.no.2015.goals <- sub.upgraders.no.switch.no.2015.goals[!is.na(sub.upgraders.no.switch.no.2015.goals$affordability_goal_knapsack_2015),]
      ## Are Meeting Affordability Goals in 2016
      table(sub.upgraders.no.switch.no.2015.goals$affordability_goal_knapsack_2016)
      round(nrow(sub.upgraders.no.switch.no.2015.goals[sub.upgraders.no.switch.no.2015.goals$affordability_goal_knapsack_2016 == TRUE,]) / nrow(sub.upgraders.no.switch.no.2015.goals), 2)
      

##----------------------------------------------------------------
## UPGRADES -> SWITCHERS -> COST PER MBPS
      
## OF THE DISTRICTS THAT UPGRADED:
sub.upgraders <- dta.dom[dta.dom$upgrade == TRUE,]
nrow(sub.upgraders)
round(nrow(sub.upgraders) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.upgraders$sp_change)
  round(nrow(sub.upgraders[sub.upgraders$sp_change == 1,]) / nrow(sub.upgraders), 2)
  ## OF THE DISTRICTS THAT UPGRADED AND SWITCHED:
  sub.upgraders.switch <- sub.upgraders[sub.upgraders$sp_change == 1,]
    ## HAD THE SAME IA PURPOSE ACROSS YEARS
    sub.upgraders.switch.same.ia <- sub.upgraders.switch[!is.na(sub.upgraders.switch$sp_ia_monthly_cost_per_mbps_2015),]
    nrow(sub.upgraders.switch.same.ia)
    round(nrow(sub.upgraders.switch.same.ia) / nrow(sub.upgraders.switch), 2)
    ## had strictly lower cost per mbps in 2016
    table(sub.upgraders.switch.same.ia$sp_ia_monthly_cost_per_mbps_2015 > sub.upgraders.switch.same.ia$sp_ia_monthly_cost_per_mbps_2016)
    round(table(sub.upgraders.switch.same.ia$sp_ia_monthly_cost_per_mbps_2015 > sub.upgraders.switch.same.ia$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(sub.upgraders.switch.same.ia), 2)

  ## OF THE DISTRICTS THAT UPGRADED AND DID NOT SWITCH:
  sub.upgraders.no.switch <- sub.upgraders[sub.upgraders$sp_change == 0,]
    ## HAD THE SAME IA PURPOSE ACROSS YEARS
    sub.upgraders.no.switch.same.ia <- sub.upgraders.no.switch[!is.na(sub.upgraders.no.switch$sp_ia_monthly_cost_per_mbps_2015),]
    nrow(sub.upgraders.no.switch.same.ia)
    round(nrow(sub.upgraders.no.switch.same.ia) / nrow(sub.upgraders.no.switch), 2)
    ## had strictly lower cost per mbps in 2016
    table(sub.upgraders.no.switch.same.ia$sp_ia_monthly_cost_per_mbps_2015 > sub.upgraders.no.switch.same.ia$sp_ia_monthly_cost_per_mbps_2016)
    round(table(sub.upgraders.no.switch.same.ia$sp_ia_monthly_cost_per_mbps_2015 > sub.upgraders.no.switch.same.ia$sp_ia_monthly_cost_per_mbps_2016)[2] / nrow(sub.upgraders.no.switch.same.ia), 2)
    
##========================================================================================================================================
## 3) CONNECTIVITY:
    
## the overall population who changed were meeting 2015 connectivity goals:
table(dta.dom$meeting_goals_2015)
round(nrow(dta.dom[dta.dom$meeting_goals_2015 == TRUE,]) / nrow(dta.dom), 2)
## Where did it happen most? Calculate percentage of switches for each state
dta.dom$counter <- ifelse(dta.dom$meeting_goals_2015 == TRUE, 1, 0)
tab.connect <- aggregate(dta.dom$counter, by=list(dta.dom$postal_cd), FUN=mean)
names(tab.connect) <- c('postal_cd', 'percent_connected')
tab.connect$percent_switched <- round(tab.connect$percent_connected*100, 0)
tab.connect <- tab.connect[order(tab.connect$percent_connected, decreasing=T),]

##----------------------------------------------------------------
## CONNECTIVITY -> SWITCHERS

## OF THE DISTRICTS THAT WERE MEETING CONNECTIVITY GOALS IN 2015:
sub.connected <- dta.dom[dta.dom$meeting_goals_2015 == TRUE,]
nrow(sub.connected)
round(nrow(sub.connected) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.connected$sp_change)
  round(nrow(sub.connected[sub.connected$sp_change == 1,]) / nrow(sub.connected), 2)

## OF THE DISTRICTS THAT WERE NOT MEETING CONNECTIVITY GOALS IN 2015:
sub.not.connected <- dta.dom[dta.dom$meeting_goals_2015 == FALSE,]
nrow(sub.not.connected)
round(nrow(sub.not.connected) / nrow(dta.dom), 2)
  ## Switchers
  table(sub.not.connected$sp_change)
  round(nrow(sub.not.connected[sub.not.connected$sp_change == 1,]) / nrow(sub.not.connected), 2)


##----------------------------------------------------------------
## AFFORDABILITY -> SWITCHERS
  
## OF THE DISTRICTS THAT WERE MEETING AFFORDABILITY GOALS IN 2015:
sub.affordable <- dta.dom[dta.dom$affordability_goal_knapsack_2015 == TRUE,]
sub.affordable <- sub.affordable[!is.na(sub.affordable$affordability_goal_knapsack_2015),]
nrow(sub.affordable)
round(nrow(sub.affordable) / nrow(dta.dom[!is.na(dta.dom$affordability_goal_knapsack_2015),]), 2)
  ## Switchers
  table(sub.affordable$sp_change)
  round(nrow(sub.affordable[sub.affordable$sp_change == 1,]) / nrow(sub.affordable), 2)
  
## OF THE DISTRICTS THAT WERE NOT MEETING AFFORDABILITY GOALS IN 2015:
sub.not.affordable <- dta.dom[dta.dom$affordability_goal_knapsack_2015 == FALSE,]
sub.not.affordable <- sub.not.affordable[!is.na(sub.not.affordable$affordability_goal_knapsack_2015),]
nrow(sub.not.affordable)
round(nrow(sub.not.affordable) / nrow(dta.dom[!is.na(dta.dom$affordability_goal_knapsack_2015),]), 2)
  ## Switchers
  table(sub.not.affordable$sp_change)
  round(nrow(sub.not.affordable[sub.not.affordable$sp_change == 1,]) / nrow(sub.not.affordable), 2)


##----------------------------------------------------------------
## CONTRACT END DATE -> SWITCHERS
  
## HAD A CONTRACT END DATE IN 2016
sub.contract.end <- dta.dom[dta.dom$contract_ended_between_years == TRUE & !is.na(dta.dom$contract_ended_between_years),]
nrow(sub.contract.end)
round(nrow(sub.contract.end) / nrow(dta.dom[!is.na(dta.dom$contract_ended_between_years),]), 2)
  ## Switchers
  table(sub.contract.end$sp_change)
  round(nrow(sub.contract.end[sub.contract.end$sp_change == 1,]) / nrow(sub.contract.end), 2)
  
## HAD A CONTRACT END DATE IN 2016
sub.contract.no.end <- dta.dom[dta.dom$contract_ended_between_years == FALSE  & !is.na(dta.dom$contract_ended_between_years),]
nrow(sub.contract.no.end)
round(nrow(sub.contract.no.end) / nrow(dta.dom[!is.na(dta.dom$contract_ended_between_years),]), 2)
  ## Switchers
  table(sub.contract.no.end$sp_change)
  round(nrow(sub.contract.no.end[sub.contract.no.end$sp_change == 1,]) / nrow(sub.contract.no.end), 2)
  
