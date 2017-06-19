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
dd_mn_16 <- dd_union[which(dd_union$year == 2016 & dd_union$postal_cd == 'MN'),]

## Define the metric. for some metrics this may also include calculations to group underlying data.
## e.g. putting % funding remaing into 4 different groups
dd_mn_16$metric <- dd_mn_16$meeting_2014_goal_no_oversub

## Define the group.
dd_mn_16$group <- dd_mn_16$locale

## Subset to the sample population. for some metrics and/or groups this may just be removing nulls.
## for others like fiber_target_status you will also need to remove Potential Targets and No Datas
## if you pick a group subset that has values we should exclude then you will need to create two different data subsets
## one for metric_overall and one for metric_group (where you will exclude relevant group values)
dd_mn_16_sub <- dd_mn_16[which(dd_mn_16$metric >= 0),]

mn_goal_meeting_overall <- metric_overall(dd_mn_16,dd_mn_16_sub)
mn_goal_meeting_group <- metric_group(dd_mn_16,dd_mn_16_sub)



#write.csv(mn_goal_meeting, "data/qa.csv", row.names = FALSE)


