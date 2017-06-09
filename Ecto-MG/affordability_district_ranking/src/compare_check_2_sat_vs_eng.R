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
source("src/affordability_ranking.R")

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/processed/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)

## forked db
dta.eng.cck12.ds <- read.csv("data/processed/fy2016_cck12_district_summary.csv", as.is=T, header=T, stringsAsFactors=F)
dta.eng.compare.di <- read.csv("data/processed/fy2016_compare_districts_info.csv", as.is=T, header=T, stringsAsFactors=F)

## cost reference data
cost <- read.csv("../../General_Resources/datasets/cost_lookup.csv", as.is=T, header=T)
cost$cost_per_circuit <- cost$circuit_size_mbps * cost$cost_per_mbps

##**************************************************************************************************************************************************

## send deluxe districts through local function to define rankings
dd.2016 <- affordability_ranking(dd.2016, cost)

compare.cck12 <- merge(dd.2016[,c('esh_id', 'group', 'target_bandwidth', 'ia_bw_mbps_total',
                                  'ia_monthly_cost_total', 'ia_monthly_cost_per_mbps', 'cost.per.mbps.normalized')],
                       dta.eng.cck12.ds[,c('esh_id', 'affordability_ranking',
                                           'knapsack_bandwidth', 'ia_monthly_cost_per_mbps')],
                       by='esh_id', all=T)
compare.cck12$diff.ranking <- compare.cck12$group - compare.cck12$affordability_ranking
## 0 differences
table(compare.cck12$diff.ranking)

compare.cck12$diff.bw <- compare.cck12$target_bandwidth - compare.cck12$knapsack_bandwidth
## 0 differences
table(compare.cck12$diff.bw)

