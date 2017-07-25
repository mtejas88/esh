## ====================================================
##
## COMPARISON: MASTER AND FORKED DB
## For comparison of whether the logic was correctly
## implemented by the engineer in the DB.
##
## ====================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-88_92_93/")

##**************************************************************************************************************************************************
## READ IN DATA

## forked version
cck12_ds_qa <- read.csv("data/raw/fy2017_cck12_district_summary_qa.csv", as.is=T, header=T, stringsAsFactors=F)

## local version
cck12_ds <- read.csv("data/raw/fy2017_cck12_district_summary.csv", as.is=T, header=T, stringsAsFactors=F)

## deluxe districts
dd_2015 <- read.csv("data/raw/2015_districts_deluxe.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2017 <- read.csv("data/raw/2017_districts_deluxe.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## compare fields that were changed in both datasets

## needs_wifi
table(cck12_ds$needs_wifi)
table(cck12_ds_qa$needs_wifi)

## needs_wifi_reason
table(cck12_ds$needs_wifi_reason)
table(cck12_ds_qa$needs_wifi_reason)

## ia_total_monthly_cost
compare_total_cost <- merge(cck12_ds[,c('esh_id', 'ia_total_monthly_cost')], cck12_ds_qa[,c('esh_id', 'ia_total_monthly_cost')], by='esh_id', all=T)
compare_total_cost$diff <- compare_total_cost$ia_total_monthly_cost.x - compare_total_cost$ia_total_monthly_cost.y
table(compare_total_cost$diff)

##**************************************************************************************************************************************************
## look into districts with 0 prediscount budget in 2015

sub <- dd_2017[which(dd_2017$c2_prediscount_budget_15 == 0),]
sub.in.universe <- sub[which(sub$include_in_universe_of_districts == 't'),]
## create an indictor for whether the school is in 2015 data
sub$in.2015 <- ifelse(sub$esh_id %in% dd_2015$esh_id, TRUE, FALSE)
sub.2015 <- dd_2015[which(dd_2015$esh_id %in% sub.in.universe$esh_id),]
