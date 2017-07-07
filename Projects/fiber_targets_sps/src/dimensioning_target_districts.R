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
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/fiber_targets_sps")

##load packages
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## Read in data
target.districts <- read.csv("data/raw/characteristics_of_target_districts.csv", as.is=T, header=T, stringsAsFactors=F)
districts <- read.csv("data/raw/characteristics_of_districts.csv", as.is=T, header=T, stringsAsFactors=F)

target.districts.count <- nrow(target.districts)
districts.count <- nrow(districts)

#Dimension by locale - fiber targets
locale.target.districts <- group_by(target.districts, locale) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/target.districts.count)

png('figures/locale.png')
ggplot(locale.target.districts, aes(x = locale, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by locale") +
  labs(x = 'Locale', y = '% Districts') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by locale - all
locale.districts <- group_by(districts, locale) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/districts.count)

png('figures/locale_all.png')
ggplot(locale.districts, aes(x = locale, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Districts by locale") +
  labs(x = 'Locale', y = '% Districts')+ 
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by size - fiber targets
size.target.districts <- group_by(target.districts, district_size) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/target.districts.count)

png('figures/district_size.png')
ggplot(size.target.districts, aes(x = district_size, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by district size") +
  labs(x = 'District size', y = '% Districts') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by size - all
size.districts <- group_by(districts, district_size) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/districts.count)

png('figures/district_size_all.png')
ggplot(size.districts, aes(x = district_size, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Districts by district size") +
  labs(x = 'District size', y = '% Districts') +
  ylim(0, 1) +
  theme_grey()
dev.off()


#Dimension by number of fiber providers in 477 - fiber targets
providers.target.districts <- group_by(target.districts, nproviders) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/target.districts.count)

png('figures/fiber_providers.png')
ggplot(providers.target.districts, aes(x = nproviders, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Fiber target districts by number of fiber providers in 477") +
  labs(x = 'Number of Fiber Providers', y = '% Districts') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by number of fiber providers in 477 - all
providers.districts <- group_by(districts, nproviders) %>%
  summarise(num.districts = n(),
            pct.districts = num.districts/districts.count)

png('figures/fiber_providers_all.png')
ggplot(providers.districts, aes(x = nproviders, y = pct.districts)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Districts by number of fiber providers in 477") +
  labs(x = 'Number of Fiber Providers', y = '% Districts') +
  ylim(0, 1) +
  theme_grey()
dev.off()

