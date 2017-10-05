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
suff.state <- read.csv('data/raw/suff_state.csv', as.is = T, header = T, stringsAsFactors = F)
remaining.hist <- read.csv('data/raw/remaining_hist.csv', as.is = T, header = T, stringsAsFactors = F)
all.make.17 <- read.csv('data/raw/all_make_17.csv', as.is = T, header = T, stringsAsFactors = F)
make.17.districts <- read.csv('data/raw/make_17_districts.csv', as.is = T, header = T, stringsAsFactors = F)
source('../../General_Resources/common_functions/correct_dataset.R')
wifi <- correct.dataset(wifi, 0 , 0)
suff.state <- correct.dataset(suff.state, 0 , 0)
all.make.17 <- correct.dataset(all.make.17, 0 , 0)
make.17.districts <- correct.dataset(make.17.districts, 0 , 0)

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
                          requested_funding = sum(requested_funding),
                          c2_prediscount_budget_15 = sum(c2_prediscount_budget_15),
                          c2_prediscount_remaining_17 = sum(c2_prediscount_remaining_17),
                          c2_percent_remaining = sum(c2_prediscount_remaining_17) / sum(c2_prediscount_budget_15),
                          c2_postdiscount_remaining_17 = sum(c2_postdiscount_remaining_17))
top.states$perc_requested_funding <- top.states$requested_funding / top.states$num_districts

top.states <- merge(top.states, suff.state, by = 'postal_cd')
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

by.size = group_by(wifi, district_size) %>%
  summarise(num_districts = n(),
            c2_prediscount_budget_15 = sum(c2_prediscount_budget_15),
            c2_prediscount_remaining_17 = sum(c2_prediscount_remaining_17))
by.size$perc_remaining <- by.size$c2_prediscount_remaining_17 / by.size$c2_prediscount_budget_15
by.size <- select(by.size, district_size, perc_remaining)
by.size

##**************************************************************************************************************************************************
## CHICAGO vs. IL
wifi$chicago <- wifi$esh_id == '901027'
chicago = filter(wifi, postal_cd == 'IL') %>%
            group_by(chicago) %>%
            summarise(total_districts = n(),
                      num_students = sum(num_students),
                      c2_prediscount_budget_15 = sum(c2_prediscount_budget_15),
                      c2_prediscount_remaining_17 = sum(c2_prediscount_remaining_17),
                      c2_postdiscount_remaining_17 = sum(c2_postdiscount_remaining_17))
chicago$perc_students = chicago$num_students / sum(chicago$num_students)
chicago$perc_remaining = chicago$c2_postdiscount_remaining_17 / sum(chicago$c2_postdiscount_remaining_17)
print(paste0('Chicago has ', round(chicago$perc_remaining[2] * 100, 2), '% of the remaining Wi-Fi funds in IL'))
print(paste0('Chicago has ', round(chicago$perc_students[2] * 100, 2), '% of the students in IL'))

##**************************************************************************************************************************************************
## HISTOGRAM OF REMAINING FUNDS

remaining.hist$perc_remaining <- remaining.hist$c2_prediscount_remaining_17 / remaining.hist$c2_prediscount_budget_15

#histogram of funds remaining
pdf('figures/district_budget_remaining.pdf', width = 11, height = 8)
ggplot(remaining.hist, aes(c2_postdiscount_remaining_17)) +
  geom_histogram(binwidth = 100000) +
  xlim(-100000,2000000) +
  labs(x = 'Budget Remaining 2017', y = 'Number of Districts', 
       title = 'Remaining C2 Budget Histogram',
       subtitle = 'Note: removed the 156 districts who each have over $2M left') +
  theme_bw() +
  theme(text = element_text(size = 12))

ggplot(remaining.hist, aes(perc_remaining)) +
  geom_histogram(binwidth = .05) +
  labs(x = '% Budget Remaining 2017', y = 'Number of Districts', 
       title = '% Remaining C2 Budget Histogram') +
  theme_bw() +
  theme(text = element_text(size = 12))
dev.off()

remaining.hist$group <- ifelse(remaining.hist$perc_remaining < .05, '0-.05',
                          ifelse(remaining.hist$perc_remaining < .1, '.05-.1',
                          ifelse(remaining.hist$perc_remaining < .15, '.1-.15',
                          ifelse(remaining.hist$perc_remaining < .2, '.15-.2',
                          ifelse(remaining.hist$perc_remaining < .25, '.2-.25',
                          ifelse(remaining.hist$perc_remaining < .3, '.25-.3',
                          ifelse(remaining.hist$perc_remaining < .35, '.3-.35',
                          ifelse(remaining.hist$perc_remaining < .4, '.35-.4',
                          ifelse(remaining.hist$perc_remaining < .45, '.4-.45',
                          ifelse(remaining.hist$perc_remaining < .5, '.45-.5',
                          ifelse(remaining.hist$perc_remaining < .55, '.5-.55',
                          ifelse(remaining.hist$perc_remaining < .6, '.55-.6',
                          ifelse(remaining.hist$perc_remaining < .65, '.6-.65',
                          ifelse(remaining.hist$perc_remaining < .7, '.65-.7',
                          ifelse(remaining.hist$perc_remaining < .75, '.7-.75',
                          ifelse(remaining.hist$perc_remaining < .8, '.75-.8',
                          ifelse(remaining.hist$perc_remaining < .85, '.8-.85',
                          ifelse(remaining.hist$perc_remaining < .9, '.85-.9',
                          ifelse(remaining.hist$perc_remaining < .95, '.9-.95', '.95-1')))))))))))))))))))

remaining.hist.summ <- group_by(remaining.hist, group) %>%
                          summarise(num_districts = n(),
                                    post_discount_remaining_funds = sum(c2_postdiscount_remaining_17))

##**************************************************************************************************************************************************
low.perc.remaining <- filter(remaining.hist, perc_remaining < .15)
low.perc.remaining <- select(low.perc.remaining, esh_id, name, city, 
                             postal_cd, district_size, locale, 
                             num_students, discount_rate_c2, outreach_status__c)

high.perc.remaining <- filter(remaining.hist, perc_remaining >= .85)
high.perc.remaining <- select(high.perc.remaining, esh_id, name, city, 
                             postal_cd, district_size, locale, 
                             num_students, discount_rate_c2, outreach_status__c)

##**************************************************************************************************************************************************
## TOP VARs & MAKE

##ALL VARs of C2 (not just received by districts in our universe)
var.only <- filter(all.make.17, !is.na(service_provider_name))
var.only <- filter(var.only, !(service_provider_name == ''))
var.only <- group_by(var.only, service_provider_name) %>%
  summarise(total_cost = sum(total_cost, na.rm = T)) %>% as.data.frame()
var.only <- var.only[order(-var.only$total_cost),]

##ALL MAKE of C2 (not just received by districts in our universe)
make.only <- filter(all.make.17, !is.na(make))
make.only <- group_by(make.only, make) %>%
                summarise(total_cost = sum(total_cost, na.rm = T)) %>% as.data.frame()
make.only <- make.only[order(-make.only$total_cost),]

##ALL VARs of C2 RECEIVED by districts in our universe
head(make.17.districts)
var.only.districts <- filter(make.17.districts, !is.na(service_provider_name))
var.only.districts <- filter(var.only.districts, !(service_provider_name == ''))
var.only.districts <- group_by(var.only.districts, service_provider_name) %>%
                        summarise(total_cost = sum(amount, na.rm = T)) %>% as.data.frame()

##ALL VARs of C2 RECEIVED by districts in our universe


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
write.csv(top.states, 'data/interim/state_summaries.csv', row.names = F)
write.csv(remaining.hist.summ, 'data/interim/hist_summaries.csv', row.names = F)
write.csv(low.perc.remaining, 'data/interim/low_remaining.csv', row.names = F)
write.csv(high.perc.remaining, 'data/interim/high_remaining.csv', row.names = F)
