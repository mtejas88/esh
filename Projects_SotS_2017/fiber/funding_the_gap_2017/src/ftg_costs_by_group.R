## =========================================
##
## % of total by locale and discount pct
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2", "reshape2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)
library(reshape2)

##import
wan_costs <- read.csv("Projects_SotS_2017/fiber/funding_the_gap_2017/data/interim/campus_build_costs.csv")
ia_costs <- read.csv("Projects/funding_the_gap_2017/data/interim/district_build_costs.csv")

wan_costs <- 
  wan_costs %>% 
  mutate(locale = case_when(sample_campus_locale == 'Unknown' ~ as.character(district_locale),
                            sample_campus_locale != 'Unknown' ~ as.character(sample_campus_locale)))

wan_costs <- select(wan_costs, locale, c1_discount_rate_or_state_avg, build_fraction_wan, total_cost_median, total_district_funding_median)
ia_costs <- select(ia_costs, district_locale, c1_discount_rate_or_state_avg, build_fraction_ia, total_cost_ia, discount_erate_funding_ia)

names(wan_costs) <- c("locale", "discount", "builds", "cost", "oop")
names(ia_costs) <- c("locale", "discount", "builds", "cost", "oop")

costs <- rbind(wan_costs, ia_costs)

costs <- 
  costs %>% 
  mutate(locale = case_when(locale == 'Town' ~ "Rural",
                            locale == 'Suburban' ~ "Urban",
                            TRUE ~ as.character(locale)))
costs <- 
  costs %>% 
  mutate(discount = case_when(discount >= .8 ~ "free",
                              discount < .8 ~ "half free"))

discount <- 
  costs %>% 
  group_by(discount) %>% 
  summarise(pct_cost = sum(cost)/sum(costs$cost),
            avg_cost = sum(cost)/sum(builds),
            avg_oop = sum(oop)/sum(builds))

locale <- 
  costs %>% 
  group_by(locale) %>% 
  summarise(pct_cost = sum(cost)/sum(costs$cost),
            avg_cost = sum(cost)/sum(builds),
            avg_oop = sum(oop)/sum(builds))

locale_discount <- 
  costs %>% 
  group_by(locale, discount) %>% 
  summarise(pct_cost = sum(cost)/sum(costs$cost),
            avg_cost = sum(cost)/sum(builds),
            avg_oop = sum(oop)/sum(builds))

