## =========================================
##
## Determining why "high cost"
##  categorizing high cost districts
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
#setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/gold_plating/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)

##imports
districts <- read.csv("data/interim/districts_clean_cats.csv")
frn_statuses <- read.csv("data/raw/frn_statuses.csv")
frn_statuses$num_bids_received_category <- ifelse( frn_statuses$num_bids_received == 1 | frn_statuses$num_bids_received == 0, 
                                                   frn_statuses$num_bids_received,
                                                   ifelse(is.null(frn_statuses$num_bids_received), 'unk', '2+'))

#count high cost districts that got 0 or 1 bids
high_cost <- filter(districts, category == 'high cost')
high_cost_frns <- inner_join(high_cost, frn_statuses, by = c("esh_id" = "recipient_id"))
dist_status <- group_by(high_cost_frns, esh_id, num_bids_received_category)
dist_status_ct <- summarize(dist_status, count=n())
dist_low_bids <- (dist_status_ct %>% filter(num_bids_received_category == '1' | num_bids_received_category == '0') 
                  %>% distinct(esh_id))
nrow(dist_low_bids)/nrow(high_cost)

#count high cost districts that are in rural areas
dist_rural <- select(filter(high_cost, locale == 'Rural'), esh_id)
nrow(dist_rural)/nrow(high_cost)

#overlap
overlap <- inner_join(dist_low_bids[,1], dist_rural, by = c("esh_id" = "esh_id"))
nrow(overlap)/nrow(high_cost)