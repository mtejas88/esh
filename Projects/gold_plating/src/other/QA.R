## =========================================
##
## GOLD PLATING QA
## 
## OBJECTIVES:
##    1) Match % of districts and % of cost received for each bucket on slide 5 of deck
##    2) Match % of high cost districts for the reasons given on slide 7
##    3) Match % of gold plates districts for the reasons given on slide 8
##
## Powerpoint: https://drive.google.com/open?id=0B2PePR0b1KuuNkRkX0hJd1ZNdTQ
## QA Doc: https://docs.google.com/document/d/1ZDWeum-4GYkeR8rNMVO6x132ayPvSklnfN3F06X3P5g
##
## QAing Analyst: Adrianna
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

##**************************************************************************************************************************************************
## read in data

districts <- read.csv("data/interim/districts_clean_cats.csv")
districts.summary <- read.csv("data/interim/districts_clean_cats_summary.csv")
frn_statuses <- read.csv("data/raw/frn_statuses.csv")
negative_barriers <- read.csv("data/raw/negative_barriers.csv")

##**************************************************************************************************************************************************

## 1) Overall % of Districts and % of Costs Received

table(districts$category)

## percentage of districts gold-plating: 7% (published)
round((nrow(districts[which(districts$category == "gold-plated"),]) / nrow(districts))*100, 0)
## percentage of costs gold-plating: 4% (published)
round((districts.summary$sum_cost[districts.summary$category == 'gold-plated'] / sum(districts.summary$sum_cost))*100, 0)

## percentage of districts high cost: 28% (published)
round((nrow(districts[which(districts$category == "high cost"),]) / nrow(districts))*100, 0)
## percentage of costs high cost: 35% (published)
## I get 34%.
round((districts.summary$sum_cost[districts.summary$category == 'high cost'] / sum(districts.summary$sum_cost))*100, 0)

## percentage of districts high bw: 6% (published)
round((nrow(districts[which(districts$category == "high bw"),]) / nrow(districts))*100, 0)
## percentage of costs high cost: 2% (published)
round((districts.summary$sum_cost[districts.summary$category == 'high bw'] / sum(districts.summary$sum_cost))*100, 0)



## 2) High Cost categorization

## aggregate number of FRN bids by recipient id
#agg.frns <- aggregate(frn_statuses$num_bids_received, by=list(frn_statuses$recipient_id), FUN=sum, na.rm=T)
#names(agg.frns) <- c('recipient_id', 'num_bids_received')

## create indicator whether a district has 0 or 1 bids for a requested service
recipients.with.0.or.1.bids <- unique(frn_statuses$recipient_id[which(frn_statuses$num_bids_received == 1 | frn_statuses$num_bids_received == 0)])
districts$low.bids.AB <- ifelse(districts$esh_id %in% recipients.with.0.or.1.bids, TRUE, NA)

## WIP BELOW
agg.recipients <- select(filter(frn_statuses, num_bids_received == 1 | num_bids_received == 0), recipient_id) %>% distinct(recipient_id)
agg.recipients$low.bids <- TRUE

## merge in with districts
districts <- merge(districts, agg.recipients, by.x='esh_id', by.y='recipient_id', all.x=T)

## make sure the indicators are the same
districts$same <- ifelse(districts$low.bids == districts$low.bids.AB, TRUE, FALSE)

## create indicator for less than 2 bids
districts$less.than.2.bids <- ifelse(is.na(districts$low.bids), FALSE, districts$low.bids)
## create indicator for rural
districts$rural <- ifelse(districts$locale == "Rural", TRUE, FALSE)
## subset to high cost districts
sub.high.cost <- districts[which(districts$category == 'high cost'),]
## look at percentage breakdown of less than 2 bids and Rural
table(sub.high.cost$less.than.2.bids, sub.high.cost$rural)
n <- nrow(sub.high.cost)
## percentage just due to 0 or 1 bids
## just less than 2 bids: 14% (published)
## I get 3%.
round((nrow(sub.high.cost[which(sub.high.cost$less.than.2.bids == TRUE & sub.high.cost$rural == FALSE),]) / n)*100, 0)
## both less than 2 bids and Rural: 37% (published)
## I get 11%.
round((nrow(sub.high.cost[which(sub.high.cost$less.than.2.bids == TRUE & sub.high.cost$rural == TRUE),]) / n)*100, 0)
## just Rural: 32% (published)
## I get 61%.
round((nrow(sub.high.cost[which(sub.high.cost$less.than.2.bids == FALSE & sub.high.cost$rural == TRUE),]) / n)*100, 0)
## neither: 17% (published)
## I get 25%.
round((nrow(sub.high.cost[which(sub.high.cost$less.than.2.bids == FALSE & sub.high.cost$rural == FALSE),]) / n)*100, 0)

## 3) Gold Plates Categorization

table(frn_statuses$frn_status)

## aggregate whether a recipient id ever had a 'Cancelled' or 'Denied' status
frn_statuses$cancelled <- ifelse(frn_statuses$frn_status == 'Cancelled', 1, 0)
frn_statuses$denied <- ifelse(frn_statuses$frn_status == 'Denied', 1, 0)
## aggregate both cancelled and denied
agg.cancelled <- aggregate(frn_statuses$cancelled, by=list(frn_statuses$recipient_id), FUN=sum, na.rm=T)
names(agg.cancelled) <- c('recipient_id', 'num_bids_cancelled')
## if a recipient has at least one cancelled bid, mark as cancelled
agg.cancelled$cancelled_bid <- ifelse(agg.cancelled$num_bids_cancelled > 0, TRUE, FALSE)
## merge in with districts
districts <- merge(districts, agg.cancelled, by.x='esh_id', by.y='recipient_id', all.x=T)
agg.denied <- aggregate(frn_statuses$denied, by=list(frn_statuses$recipient_id), FUN=sum, na.rm=T)
names(agg.denied) <- c('recipient_id', 'num_bids_denied')
## if a recipient has at least one cancelled bid, mark as cancelled
agg.denied$denied_bid <- ifelse(agg.denied$num_bids_denied > 0, TRUE, FALSE)
## merge in with districts
districts <- merge(districts, agg.denied, by.x='esh_id', by.y='recipient_id', all.x=T)

## define "barriers"
negative_barriers$has.barriers <- ifelse(negative_barriers$barriers != 0, TRUE, FALSE)
## merge into districts
districts <- merge(districts, negative_barriers, by.x='esh_id', by.y='entity_id', all.x=T)

## create a subset of just gold plating
sub.gold.plate <- districts[which(districts$category == 'gold-plated'),]
n <- nrow(sub.gold.plate)
## denied funding: 4% (published)
## I get 5%.
round((nrow(sub.gold.plate[which(sub.gold.plate$denied_bid == TRUE),]) / n)*100, 0)

## cancelled funding: 3% (published)
## I get 4%.
round((nrow(sub.gold.plate[which(sub.gold.plate$cancelled_bid == TRUE),]) / n)*100, 0)

## percentage with some barriers: 51% (published)
## I get 52%.
round((nrow(sub.gold.plate[which(sub.gold.plate$has.barriers == TRUE),]) / n)*100, 0)

