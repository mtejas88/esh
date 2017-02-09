## =========================================================================
##
## AFFORDABILITY TARGET
## Created for Aha Card: SAT-2089
## Sprint 09/19/2016
## GOAL: examine the impact of changing the WAN flag to be based on campuses
##        instead of schools.
##
## Written by Adrianna Boghozian (AJB)
##
## =========================================================================

## Clearing memory
rm(list=ls())

setwd("~/Google Drive/Colocation/code/")

##*********************************************************************************************************
## READ IN FILES

## district-level data
dta <- read.csv("../data/fy2016.districts-2016-09-20.csv", as.is=T, header=T)
dta.wan <- read.csv("../data/endpoint.fy2016_districts_deluxe-2016-09-20.csv", as.is=T, header=T)

## campuses
dta.camp <- read.csv("../data/num_campuses_by_district.csv", as.is=T, header=T)

## schools
dta.sch <- read.csv("../data/fy2016_schools_demog_2016-08-30.csv", as.is=T, header=T)

##*********************************************************************************************************

## merge in number of wan lines
dta <- merge(dta, dta.wan[,c('esh_id', 'wan_lines')], by='esh_id', all.x=T)

## merge in number of campuses
dta$num_campuses <- NULL
dta <- merge(dta, dta.camp, by.x='esh_id', by.y='district_esh_id', all.x=T)

## calculate number of distinct addresses of schools for each district
agg.unique.addr <- aggregate(address ~ district_esh_id, dta.sch, function(x) length(unique(x)))
names(agg.unique.addr) <- c('esh_id', 'num_distinct_addresses')
## merge in the number of distinct addresses
dta <- merge(dta, agg.unique.addr, by='esh_id', all.x=T)

## Case 1: 2-5 schools
dta.sub.c1 <- dta[dta$num_distinct_addresses >= 2,]
dta.sub.c1 <- dta.sub.c1[dta.sub.c1$num_schools <= 5 & dta.sub.c1$num_schools >= 2,]
## create indicator for old algorithm
dta.sub.c1$old.alg <- ifelse(dta.sub.c1$wan_lines < (dta.sub.c1$num_distinct_addresses - 1), 1, 0)
table(dta.sub.c1$old.alg)
## subset to the current open wan flags
#dta.sub.c1 <- dta[grepl('missing_wan_small', dta$open_flag_labels),]
## create indicator for new algorithm
dta.sub.c1$new.alg <- ifelse(dta.sub.c1$wan_lines < (dta.sub.c1$num_campuses - 1), 1, 0)
table(dta.sub.c1$new.alg)
table(dta.sub.c1$old.alg, dta.sub.c1$new.alg)
#sub <- dta.sub.c1[dta.sub.c1$old.alg == 1 & dta.sub.c1$new.alg == 0,]
#sub <- sub[!is.na(sub$esh_id),]
#write.csv(sub, "../data/wan_small_flags_expected_to_close.csv", row.names=F)

## Case 2: 6+ schools
dta.sub.c2 <- dta[dta$num_schools >= 6,]
## create indicator for old algorithm
dta.sub.c2$old.alg <- ifelse(dta.sub.c2$wan_lines > 0 & (dta.sub.c2$wan_lines / dta.sub.c2$num_schools) < 0.75, 1, 0)
table(dta.sub.c2$old.alg)
## subset to the current open wan flags
#dta.sub.c2 <- dta[grepl('missing_wan_large', dta$open_flag_labels),]
## create indicator for new algorithm
dta.sub.c2$new.alg <- ifelse(dta.sub.c2$wan_lines > 0 & (dta.sub.c2$wan_lines < (dta.sub.c2$num_campuses - 1)), 1, 0)
table(dta.sub.c2$new.alg)
table(dta.sub.c2$old.alg, dta.sub.c2$new.alg)
#sub <- dta.sub.c2[dta.sub.c2$old.alg == 1 & dta.sub.c2$new.alg == 0,]
#sub <- sub[!is.na(sub$esh_id),]
#write.csv(sub, "../data/wan_large_flags_expected_to_close.csv", row.names=F)
#sub <- dta.sub.c2[dta.sub.c2$old.alg == 0 & dta.sub.c2$new.alg == 1,]
#sub <- sub[!is.na(sub$esh_id),]
#write.csv(sub, "../data/wan_large_flags_expected_to_open.csv", row.names=F)
