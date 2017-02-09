## =========================================================================
##
## INVESTIGATE FINAL CAMPUSES
## Examine the results of the campusing algorithm
## and compare to the original results
## 
## Questions Answered:
## 1) What is the percentage of campuses that have more than 1 unique address?
## 2) What are the number of campuses in each district?
##
## Written by Adrianna Boghozian (AJB)
##
## =========================================================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("~/Google Drive/Colocation/code/")

##*********************************************************************************************************
## READ IN FILES

dta <- read.csv("../data/final_campus_groupings_2016-08-31_school_level.csv", as.is=T, header=T)
dta.campus <- read.csv("../data/final_campus_groupings_2016-08-31.csv", as.is=T, header=T)
real.schools <- read.csv("../data/fy2016_schools_demog_2016-08-30.csv", as.is=T, header=T)
nces.raw <- read.csv("../data/sc131a.csv", as.is=T, header=T)

##*********************************************************************************************************

## create the combined address field
real.schools$combined.addr <- paste(real.schools$address, real.schools$city,
                                    real.schools$postal_cd, real.schools$zip, sep=' ')

## merge in address info to campus
dta <- merge(dta, real.schools[,c("school_esh_id", "combined.addr", "district_esh_id")], by="school_esh_id")

## merge in number of schools in each campus
dta.campus$campus.id <- paste("campus_", dta.campus$campus.id, sep='')
dta <- merge(dta, dta.campus[,c("campus.id", "num.schools")], by.x="campus_id", by.y="campus.id", all.x=T)
## subset to only campuses with more than 1 school
dta <- dta[dta$num.schools > 1,]

## aggregate number of unique addresses by campus id
dta.store <- data.frame(campus_id = unique(dta$campus_id))

for (i in 1:nrow(dta.store)){
  dta.sub <- dta[dta$campus_id == dta.store$campus_id[i],]
  dta.store$unq.add[i] <- length(unique(dta.sub$combined.addr))
}

table(dta.store$unq.add)
## percentage of campuses with more than 1 unique id
## 45% of campuses have more than one unique address
nrow(dta.store[dta.store$unq.add > 1,]) / nrow(dta.store)

## sample from these to see if we need to regularize addresses
sample.camp.ids <- sample(dta.store$campus_id[dta.store$unq.add > 1], 10, replace=F)

sub <- dta[dta$campus_id == sample.camp.ids[4],]


## grab unique combinations of campuses and district ids
dta.sub <- unique(dta[,c("campus_id", "district_esh_id")])
dta.sub$counter <- 1
## aggregate the number of campuses by district id
dta.agg <- aggregate(dta.sub$counter, by=list(dta.sub$district_esh_id), FUN=sum)
## rename columns
names(dta.agg) <- c("district_esh_id", "num_campuses")

## write out csv
write.csv(dta.agg, "../data/num_campuses_by_district.csv", row.names=F)

## read in all combinations of schools
dta <- read.csv("../data/all_distances_2016-08-31.csv", as.is=T, header=T)

## subset data to where distance does not equal 0
dta <- dta[dta$distance_hav > 0,]

## create indicator for less than a mile distance
dta$less.mile <- ifelse(dta$distance_hav <= 1, 1, 0)
table(dta$less.mile)
sub <- dta[dta$less.mile == 1,]

