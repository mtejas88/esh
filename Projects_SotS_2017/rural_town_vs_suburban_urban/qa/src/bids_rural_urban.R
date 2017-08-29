## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/rural_town_vs_suburban_urban/qa/")

##**************************************************************************************************************************************************
## read in data

dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

## Form 470s
#form_470 <- read.csv("data/raw/form_470.csv", as.is=T, header=T, stringsAsFactors=F)

## BENs
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)

## FRNs
frns <- read.csv("data/raw/frns.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

## create an indicator for Rural/Small Town and Urban/Suburban
dd_2017$classify <- ifelse(dd_2017$locale %in% c('Rural', 'Town'), 'Rural/Town', ifelse(dd_2017$locale %in% c('Suburban', 'Urban'), 'Urban/Suburban', NA))

## subset to in universe
dd_2017 <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$district_type == 'Traditional'),]

## merge in BENs
dd_2017 <- merge(dd_2017, bens[,c('entity_id', 'ben')], by.x='esh_id', by.y='entity_id', all.x=T)

## subset frns to districts we care about
## merge in esh_id
frns <- merge(frns, dd_2017[,c('esh_id', 'ben')], by='ben', all.x=T)
frns <- frns[which(frns$ben %in% dd_2017$ben),]
frns <- frns[which(frns$num_bids_received < 1000),]

## aggregate the mean per district
agg.mean <- aggregate(frns$num_bids_received, by=list(frns$esh_id), FUN=mean, na.rm=T)
names(agg.mean) <- c('esh_id', 'avg_num_bids')
agg.mean <- merge(agg.mean, dd_2017[,c('esh_id', 'classify')], by='esh_id', all.x=T)


## Rural/Small Town
nrow(agg.mean[which(agg.mean$classify == 'Rural/Town'),])
mean(agg.mean$avg_num_bids[which(agg.mean$classify == 'Rural/Town')], na.rm=T)
median(agg.mean$avg_num_bids[which(agg.mean$classify == 'Rural/Town')], na.rm=T)
nrow(agg.mean[which(agg.mean$avg_num_bids == 0 & agg.mean$classify == 'Rural/Town'),])

## Urban/Suburban
nrow(agg.mean[which(agg.mean$classify == 'Urban/Suburban'),])
mean(agg.mean$avg_num_bids[which(agg.mean$classify == 'Urban/Suburban')], na.rm=T)
median(agg.mean$avg_num_bids[which(agg.mean$classify == 'Urban/Suburban')], na.rm=T)
nrow(agg.mean[which(agg.mean$avg_num_bids == 0 & agg.mean$classify == 'Urban/Suburban'),])

