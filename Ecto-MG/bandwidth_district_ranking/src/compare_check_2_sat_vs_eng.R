## ====================================================
##
## COMPARISON: LOCAL AND FORKED DB
## For comparison of whether the logic was correctly
## implemented by the engineer in the DB.
##
## ====================================================

## Clearing memory
rm(list=ls())

## source functions
source("src/bandwidth_ranking.R")

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/processed/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)

## forked db
dta.eng.cck12.ds <- read.csv("data/processed/fy2016_cck12_district_summary.csv", as.is=T, header=T, stringsAsFactors=F)
dta.eng.compare.di <- read.csv("data/processed/fy2016_compare_districts_info.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

## send deluxe districts through local function to define rankings
dd.2016 <- bandwidth_ranking(dd.2016)

compare.cck12 <- merge(dd.2016[,c('esh_id', 'group_concurrency', 'ia_bandwidth_per_student_kbps_concurrency')],
                       dta.eng.cck12.ds[,c('esh_id', 'bandwidth_ranking', 'ia_bandwidth_per_student_kbps_concurrency')],
                       by='esh_id', all=T)
compare.cck12$diff.ranking <- compare.cck12$group_concurrency - compare.cck12$bandwidth_ranking
table(compare.cck12$diff.ranking)

compare.cck12$diff.bw <- compare.cck12$ia_bandwidth_per_student_kbps_concurrency.x - compare.cck12$ia_bandwidth_per_student_kbps_concurrency.y
## many small differences (decimals to the >-10 place)
table(compare.cck12$diff.bw)
## only one difference is significant
table(compare.cck12$diff.bw > 0.1)
sub <- compare.cck12[which(compare.cck12$diff.bw > 0.1),]
