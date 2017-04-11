## ====================================================
##
## COMPARISON: R VS SQL LOGIC
## For internal comparison of whether the logic
## was correctly transformed into SQL by
## the analyst.
##
## ====================================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/interim/bandwidth_grouping.csv", as.is=T, header=T, stringsAsFactors=F)

## sql query
dta <- read.csv("data/raw/fy2016_cck12_district_summary.csv", as.is=T, header=T, stringsAsFactors=F)
#dta <- read.csv("data/raw/fy2016_compare_districts_info.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## compare districts

compare <- merge(dd.2016[,c('esh_id', 'ia_bandwidth_per_student_kbps_concurrency', 'group_concurrency')],
                  dta[,c('esh_id', 'ia_bandwidth_per_student_kbps_concurrency', 'bandwidth_ranking')],
                  by='esh_id', all=T)
compare$diff <- compare$group_concurrency - compare$bandwidth_ranking

table(compare$diff)
## subset to the districts that have a different grouping
sub <- compare[which(compare$diff != 0),]


