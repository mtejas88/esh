## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##load packaged
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

unscalable.dd <- read.csv("data/raw/unscalable_districts.csv", as.is=T, header=T, stringsAsFactors=F)

source('../../General_Resources/common_functions/correct_dataset.R')
unscalable.dd <- correct.dataset(unscalable.dd, 0 , 0)

#filtering out districts with no unscalable campuses
unscalable.dd <- filter(unscalable.dd, num_unscalable_campuses > 0)

total.unscalable.schools <- sum(unscalable.dd$unscalable_schools) %>% round()
total.unscalable.campuses <- sum(unscalable.dd$num_unscalable_campuses) %>% round()

#filtering out districts with low discount rates
high.dd <- filter(unscalable.dd, discount_rate_c1_matrix >= 0.8, num_unscalable_campuses > 0)
num.high.dd <- nrow(high.dd)
num.high.dd.students <- sum(high.dd$unscalable_students) %>% round()
num.high.dd.schools <- sum(high.dd$unscalable_schools) %>% round()
num.high.dd.campuses <- sum(high.dd$num_unscalable_campuses) %>% round()

print(paste0('There are ',num.high.dd, ' districts that need fiber and have at least an 80% discount rate'))
print(paste0('This represents ',num.high.dd.students, ' students in ', num.high.dd.schools, ' schools'))
print(paste0('which is ', num.high.dd.campuses, ' campuses'))

pdf('figures/histogram.pdf', width = 7, height = 5)
ggplot(unscalable.dd, aes(x = discount_rate_c1_matrix)) + 
  geom_bar(fill = '#fdb913') + 
  ggtitle("Number of districts with unscalable campuses by discount rate") +
  labs(x = 'Discount Rate', y = 'Number of Districts') +
  theme_grey()
dev.off()

pdf('figures/locale.pdf', width = 7, height = 5)
ggplot(high.dd, aes(x = locale)) + 
  geom_bar(fill = '#fdb913') + 
  ggtitle("Number of districts with unscalable campuses and high discount rates") +
  labs(x = 'Locale', y = 'Number of Districts') +
  theme_grey()
dev.off()

pdf('figures/locale_students.pdf', width = 7, height = 5)
ggplot(high.dd, aes(x = locale, y = unscalable_students)) +
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Number of students with unscalable campuses and high discount rates") +
  labs(x = 'Locale', y = 'Number of Students') +
  theme_grey()
dev.off()


pdf('figures/size.pdf', width = 7, height = 5)
ggplot(high.dd, aes(x = district_size)) + 
  geom_bar(fill = '#fdb913') + 
  ggtitle("Number of districts with unscalable campuses and high discount rates") +
  labs(x = 'Locale', y = 'Number of Districts') +
  theme_grey()
dev.off()
