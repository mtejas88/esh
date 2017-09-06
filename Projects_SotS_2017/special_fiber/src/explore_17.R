## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

sf <- read.csv("data/raw/special_fiber_new_meth_17.csv", as.is=T, header=T, stringsAsFactors=F)
bids <- read.csv("data/raw/bids.csv", as.is=T, header=T, stringsAsFactors=F)
head(sf)

total.num.students = sum(sf$num_students)
total.num.schools = sum(sf$num_schools)
total.num.districts = nrow(sf)

by.locale <- group_by(sf, locale) %>% 
  summarise(districts = n(), 
            students = sum(num_students)) %>% as.data.frame()

by.size <- group_by(sf, district_size) %>% 
  summarise(districts = n(), 
            students = sum(num_students)) %>% as.data.frame()

by.discount <- group_by(sf, discount_rate_c1_matrix) %>% 
  summarise(districts = n(), 
            students = sum(num_students)) %>% as.data.frame()

by.size$district_size = factor(by.size$district_size, levels = c('Tiny','Small','Medium','Large','Mega'))

ggplot(by.size, aes(district_size, districts, label = districts)) +
    geom_bar(stat = 'identity', fill = '#fcd56a') +
    geom_text(size = 3.7, position = position_stack(vjust = .5)) +
    labs(x = '', y = '', title = 'Num districts with special fiber by size') +
    theme_classic()

ggplot(by.size, aes(district_size, students, label = paste(round(students/1000,1),'K'))) +
  geom_bar(stat = 'identity', fill = '#fcd56a') +
  geom_text(size = 3.7, position = position_stack(vjust = .5)) +
  labs(x = '', y = '', title = 'Num students with special fiber by size') +
  theme_classic() +
  theme(axis.text.y=element_blank(), axis.ticks.y=element_blank())


##**************************************************************************************************************************************************
##BIDS

head(bids)
no.bids.final.meth <- (bids$districts_0_bids + bids$spek_c_districts_more_than_0_bids + bids$no_fiber) / bids$total_districts
had.bids <- 1 - no.bids.final.meth
