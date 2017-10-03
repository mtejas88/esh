## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

# installing packages
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA AND CLEANING DATA
wifi <- read.csv('data/raw/wifi.csv', as.is = T, header = T, stringsAsFactors = F)
source('../../General_Resources/common_functions/correct_dataset.R')
wifi <- correct.dataset(wifi, 0 , 0)

spend.all.wifi <- filter(wifi, round(c2_postdiscount_remaining_17, 0) == 0)
spend.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0))
over.75.perc.left <- filter(wifi, c2_prediscount_remaining_17 >= .75 * c2_prediscount_budget_15)
less.25.perc.left <- filter(wifi, c2_prediscount_remaining_17 < .25 * c2_prediscount_budget_15)
needs.wifi <- filter(wifi, needs_wifi ==T)
needs.wifi.and.spent.all.wifi <- filter(wifi, round(c2_postdiscount_remaining_17, 0) == 0 & needs_wifi ==T)
needs.wifi.and.spent.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0) & needs_wifi ==T)
has.wifi.and.spent.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0) & needs_wifi ==F)

##**************************************************************************************************************************************************
##WRITE TO CSV
write.csv(spend.all.wifi, 'data/interim/spent_all_wifi.csv', row.names = F)
write.csv(spend.no.wifi, 'data/interim/spent_no_wifi.csv', row.names = F)
write.csv(over.75.perc.left, 'data/interim/over_75_perc_left.csv', row.names = F)
write.csv(less.25.perc.left, 'data/interim/less_25_perc_left.csv', row.names = F)
write.csv(needs.wifi, 'data/interim/insuff_wifi.csv', row.names = F)
write.csv(needs.wifi.and.spent.all.wifi, 'data/interim/insuff_wifi_and_spent_all.csv', row.names = F)
write.csv(needs.wifi.and.spent.no.wifi, 'data/interim/insuff_wifi_and_spent_none.csv', row.names = F)
write.csv(has.wifi.and.spent.no.wifi, 'data/interim/suff_wifi_and_spent_none.csv', row.names = F)
