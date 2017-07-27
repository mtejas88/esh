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

## aggregate cable lines
sp.cable.agg.total <- aggregate(sp.cable$line_item_district_cost, by=list(sp.cable$connect_category), FUN=sum, na.rm=T)
sp.cable.agg.erate <- aggregate(sp.cable$erate, by=list(sp.cable$connect_category), FUN=sum, na.rm=T)

## aggregate all lines
sp.all.agg.total <- aggregate(sp.all$line_item_district_cost, by=list(sp.all$connect_category), FUN=sum, na.rm=T)
sp.all.agg.erate <- aggregate(sp.all$erate, by=list(sp.all$connect_category), FUN=sum, na.rm=T)



## CABLE LINE ITEMS
sum(sp.cable.agg.total$x[sp.cable.agg.total$Group.1 == 'Cable'])
sum(sp.cable.agg.erate$x[sp.cable.agg.erate$Group.1 == 'Cable'])

sum(sp.all.agg.total$x[sp.all.agg.total$Group.1 == 'Cable'])
sum(sp.all.agg.erate$x[sp.all.agg.erate$Group.1 == 'Cable'])


## NOT CABLE LINE ITEMS
sum(sp.cable.agg.total$x[sp.cable.agg.total$Group.1 != 'Cable'])
sum(sp.cable.agg.erate$x[sp.cable.agg.erate$Group.1 != 'Cable'])

sum(sp.all.agg.total$x[sp.all.agg.total$Group.1 != 'Cable'])
sum(sp.all.agg.erate$x[sp.all.agg.erate$Group.1 != 'Cable'])
