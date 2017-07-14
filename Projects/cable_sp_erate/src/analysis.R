## =========================================
##
## ANALYSIS
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/cable_sp_erate/")

##**************************************************************************************************************************************************
## READ IN DATA

sp.cable <- read.csv("data/raw/line_item_cost_cable_sp.csv")
sp.all <- read.csv("data/raw/line_item_cost_sp.csv")

##**************************************************************************************************************************************************
## MUNGE DATA

sp.cable$erate <- sp.cable$line_item_district_cost * sp.cable$discount_rate_c1_matrix
sp.all$erate <- sp.all$line_item_district_cost * sp.all$discount_rate_c1_matrix







##**************************************************************************************************************************************************
## write out the datasets

write.csv(sp.cable, "data/raw/line_item_cost_cable_sp.csv", row.names=F)
