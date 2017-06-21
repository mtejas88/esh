## =========================================
##
## Dimension fiber target districts
##    Locale, district size, number of
##    alternative fiber service providers
##
## =========================================

## Clearing memory
rm(list=ls())

## Setting working directory -- needs to be changed
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/high_cost_profiling")

##load packages
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

target.districts <- read.csv("data/raw/characteristics_of_target_districts.csv", as.is=T, header=T, stringsAsFactors=F)

num.districts <- unique(target.districts$district_esh_id) %>% length()
print(paste0('There are ', num.districts, ' fiber target districts'))

#Dimension by locale
locale.target.districts <- group_by(target.districts, locale) %>%
  summarise(num.districts = n())

pdf('figures/locale.pdf', width = 7, height = 5)
ggplot(locale.target.districts, aes(x = locale, y = num.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by locale") +
  labs(x = 'Locale', y = 'Number of Districts') +
  theme_grey()
dev.off()

#Dimension by size
size.target.districts <- group_by(target.districts, district_size) %>%
  summarise(num.districts = n())

pdf('figures/district_size.pdf', width = 7, height = 5)
ggplot(size.target.districts, aes(x = district_size, y = num.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by district size") +
  labs(x = 'District size', y = 'Number of Districts') +
  theme_grey()
dev.off()

#Dimension by number of fiber providers in 477
providers.target.districts <- group_by(target.districts, nproviders) %>%
  summarise(num.districts = n())

pdf('figures/fiber_providers.pdf', width = 7, height = 5)
ggplot(providers.target.districts, aes(x = nproviders, y = num.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by number of fiber providers in 477") +
  labs(x = 'Number of Fiber Providers', y = 'Number of Districts') +
  theme_grey()
dev.off()
