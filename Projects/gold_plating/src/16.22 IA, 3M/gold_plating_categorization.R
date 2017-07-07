## =========================================
##
## Determining why "gold-plating"
##  categorizing gold-plated districts
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
#setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/gold_plating/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)

##imports
districts <- read.csv("data/interim/districts_clean_cats_2.csv")
frn_statuses <- read.csv("data/raw/frn_statuses.csv")
negative_barriers <- read.csv("data/raw/negative_barriers.csv")
# from https://github.com/educationsuperhighway/ficher/blob/master/Projects/redundant_circuits/src/redundant_ia.SQL
redundant_ia <- read.csv("data/raw/redundant_ia.csv")

#count gold plated districts that got denied funding
gold_plating <- filter(districts, category == 'gold-plated')
gold_plating_frns <- inner_join(gold_plating, frn_statuses, by = c("esh_id" = "recipient_id"))
dist_status <- group_by(gold_plating_frns, esh_id, frn_status)
dist_status_ct <- summarize(dist_status, count=n())
dist_denied <- (dist_status_ct %>% filter(frn_status == 'Denied') %>% distinct(esh_id))
nrow(dist_denied)/nrow(gold_plating)

dist_denied_canc <- (dist_status_ct %>% filter(frn_status == 'Denied' | frn_status == 'Cancelled') %>% distinct(esh_id))
nrow(dist_denied_canc)/nrow(gold_plating)

#count gold plated districts that have negative barriers
negative_barriers$indicator <- ifelse(negative_barriers$barriers > 0, TRUE, FALSE)
gold_plating_surveys <- inner_join(gold_plating, negative_barriers, by = c("esh_id" = "entity_id"))
dist_survey <- group_by(gold_plating_surveys, esh_id, indicator)
dist_survey_ct <- summarize(dist_survey, count=n())
dist_barriers <- (dist_survey_ct %>% filter(indicator == TRUE) %>% distinct(esh_id))
nrow(dist_barriers)/nrow(gold_plating)

#count gold plated districts that have redundant circuits
gold_plating_redundant <- inner_join(gold_plating, redundant_ia, by = c("esh_id" = "recipient_id"))
dist_survey <- group_by(gold_plating_redundant, esh_id)
dist_survey_ct <- summarize(dist_survey, count=n())
nrow(dist_survey_ct)/nrow(gold_plating)

#count gold plated districts that have redundant circuits
gold_plating_high_dr <- filter(gold_plating,discount_rate_c1>=.8)
nrow(gold_plating_high_dr)/nrow(gold_plating)

#overlap
overlap <- inner_join(gold_plating_high_dr, dist_barriers[,1], by = c("esh_id" = "esh_id"))
nrow(overlap)/nrow(gold_plating)
