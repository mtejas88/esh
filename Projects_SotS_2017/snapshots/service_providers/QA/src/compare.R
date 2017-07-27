## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/snapshots/service_providers/QA/")

##**************************************************************************************************************************************************
## READ DATA

## Districts Deluxe
dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv")

## Services Received
sr_2017 <- read.csv("data/raw/2017_services_received.csv")

## Dominant SP
sp_2017 <- read.csv("data/raw/2017_service_providers.csv")

## Top 5 SPs
top_2017 <- read.csv("data/raw/2017_top_5_sp.csv")

##**************************************************************************************************************************************************
## find the top SP's with students not meeting goals in each state

## create subset
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$district_type == 'Traditional'),]

## create indicator for students not meeting goals for each district
dd_2017$not_meeting_goals <- ifelse(dd_2017$ia_bandwidth_per_student_kbps < 100, 1, 0)
