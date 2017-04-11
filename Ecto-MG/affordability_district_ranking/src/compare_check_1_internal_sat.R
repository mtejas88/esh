## =========================================
##
## EXAMINE DATA: Affordability
## Look into cutoff points for bucketing
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/interim/affordability_grouping.csv", as.is=T, header=T, stringsAsFactors=F)

## sql query
dta <- read.csv("data/raw/fy2016_cck12_district_summary.csv", as.is=T, header=T, stringsAsFactors=F)
#dta <- read.csv("data/raw/fy2016_compare_districts_info.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## compare districts

dta$diff_target_actual_bandwidth_perc <- round(dta$diff_target_actual_bandwidth_perc, 2)
compare <- merge(dd.2016[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'diff.bw.perc',
                            'ia_monthly_cost_total', 'group')],
                  dta[,c('esh_id', 'knapsack_bandwidth', 'ia_bw_mbps_total', 'diff_target_actual_bandwidth_perc',
                         'ia_monthly_cost_total', 'affordability_ranking')],
                  by='esh_id', all=T)
compare$diff.ranking <- compare$group - compare$affordability_ranking
table(compare$diff.ranking)
## subset to the districts that have a different grouping
sub <- compare[which(compare$diff.ranking != 0),]

## compare all fields
## 0 differences
compare$diff.total.bw <- compare$ia_bw_mbps_total.x - compare$ia_bw_mbps_total.y
sub <- compare[which(compare$diff.total.bw != 0),]
## 0 differences
compare$diff.ia.monthly.cost <- compare$ia_monthly_cost_total.x - compare$ia_monthly_cost_total.y
sub <- compare[which(compare$diff.ia.monthly.cost != 0),]
## 12 differences
compare$diff.knapsack.bw <- compare$target_bandwidth - compare$knapsack_bandwidth
sub <- compare[which(compare$diff.knapsack.bw != 0),]
compare$diff.perc <- compare$diff.bw.perc - compare$diff_target_actual_bandwidth_perc
sub <- compare[which(compare$diff.perc != 0),]
