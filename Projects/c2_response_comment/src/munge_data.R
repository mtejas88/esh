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

##**************************************************************************************************************************************************
## LIST OF DISTRICTS TO POSSIBLY SURVEY

spend.all.wifi <- filter(wifi, round(c2_postdiscount_remaining_17, 0) == 0)
spend.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0))
over.75.perc.left <- filter(wifi, c2_prediscount_remaining_17 >= .75 * c2_prediscount_budget_15)
less.25.perc.left <- filter(wifi, c2_prediscount_remaining_17 < .25 * c2_prediscount_budget_15)
needs.wifi <- filter(wifi, needs_wifi ==T)
needs.wifi.and.spent.all.wifi <- filter(wifi, round(c2_postdiscount_remaining_17, 0) == 0 & needs_wifi ==T)
needs.wifi.and.spent.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0) & needs_wifi ==T)
has.wifi.and.spent.no.wifi <- filter(wifi, round(c2_prediscount_remaining_17, 0) == round(c2_prediscount_budget_15, 0) & needs_wifi ==F)

all <- rbind(spend.all.wifi, spend.no.wifi, over.75.perc.left, less.25.perc.left, needs.wifi, needs.wifi.and.spent.all.wifi, needs.wifi.and.spent.no.wifi, has.wifi.and.spent.no.wifi) %>%
  select(esh_id) %>% unique()

print('these lists consist of')
nrow(all)
print('districts')

##**************************************************************************************************************************************************
## TOP STATES BY % OF DISTRICTS THAT REQUESTED FUNDING
wifi$requested_funding <- !(round(wifi$c2_prediscount_remaining_17, 0) == round(wifi$c2_prediscount_budget_15, 0))
top.states <- group_by(wifi, postal_cd) %>%
                summarise(num_districts = n(),
                          requested_funding = sum(requested_funding))
top.states$perc_requested_funding <- top.states$requested_funding / top.states$num_districts
top.states <- top.states[order(-top.states$perc_requested_funding),]
##**************************************************************************************************************************************************
## LARGER URBAN DIstrICTS vs. SMALLER RURAL DISTRICTS
wifi$locale_adj = ifelse(wifi$locale %in% c('Urban', 'Suburban'), 'Urban/Suburban', 'Rural/Town')
by.locale_adj = group_by(wifi, locale_adj) %>%
                  summarise(num_districts = n(),
                            c2_prediscount_budget_15 = sum(c2_prediscount_budget_15),
                            c2_prediscount_remaining_17 = sum(c2_prediscount_remaining_17))
by.locale_adj$perc_remaining <- by.locale_adj$c2_prediscount_remaining_17 / by.locale_adj$c2_prediscount_budget_15
print(paste0('urban / suburban districts have ', 
             filter(by.locale_adj, locale_adj == 'Urban/Suburban')['perc_remaining'] %>% round(2) * 100,
             '% of their funding remaining'))
print(paste0('rural / town ', 
             filter(by.locale_adj, locale_adj == 'Rural/Town')['perc_remaining'] %>% round(2) * 100,
             '% of their funding remaining'))

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
