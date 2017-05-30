## =========================================================================
##
## CAMPUSING ALGORITHM: #1
## GOAL: Calculate distance between all combinations of schools within a district
## Uses NCES latitude and longitude data to calculate distance between schools
##
## Time Warning: will take ~ 25 min to run the entire script
##
## =========================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("geosphere", "caTools", "dplyr", "gRbase", "dtplyr", "data.table")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(geosphere)
library(caTools)
library(dplyr)
library(gRbase) ## for combn function
library(dtplyr) 
library(data.table) ## for the as.data.table function

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##*********************************************************************************************************
## read in data

nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************

## correct ids using function
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)

## round 2017 lat/long coordinates to 4 decimal places to match last year's calcalation
## (since some campuses didn't stick due to the slight difference in calculation)
nces$latcode <- round(nces$latcode, digits=4)
nces$longcode <- round(nces$longcode, digits=4)

### FIND ALL POSSIBLE COMBINATIONS OF SCHOOLS WITHIN EACH DISTRICT
## subset to districts with more than 1 school
districts.dta <- data.frame(table(nces$leaid))
districts.sub <- districts.dta$Var1[districts.dta$Freq > 2]
dta <- NULL
## append all combinations of school pairings within a district (where a district has 3 or more schools)
## takes ~10 min to run the loop
system.time({
  for (i in 1:length(districts.sub)){
    print(i)
    dta.sub <- nces[nces$leaid == districts.sub[i],]
    dta <- rbind(dta, as.data.table(t(combnPrim(dta.sub$ncessch, 2))))
  }
})
names(dta) <- c("school1", "school2")
## merge in district and lat/long information for each school
dta <- merge(dta, nces[,c("ncessch", "leaid", "latcode", "longcode", "combined.addr")],
             by.x="school1", by.y="ncessch", all.x=T, allow.cartesian=T)
dta <- merge(dta, nces[,c("ncessch", "leaid", "latcode", "longcode", "combined.addr")],
             by.x="school2", by.y="ncessch", all.x=T, allow.cartesian=T)
names(dta) <- c("school1", "school2", "district1", "lat1", "long1", "combined.addr1",
                "district2", "lat2", "long2", "combined.addr2")
## only keep the combinations where the districts are the same
dta <- dta[dta$district1 == dta$district2,]

## append all combinations of school pairings within a district (where a district has 2 schools)
## this is split up to speed up computer processing time
dta.sub <- nces[nces$leaid %in% districts.dta$Var1[districts.dta$Freq == 2],]
dta.2 <- NULL
## takes ~5 sec to run
system.time({
  dta.2 <- rbind(dta.2, as.data.table(t(combnPrim(dta.sub$ncessch, 2))))
})
names(dta.2) <- c("school1", "school2")
## merge in district and lat/long information for each school
dta.2 <- merge(dta.2, nces[,c("ncessch", "leaid", "latcode", "longcode", "combined.addr")],
               by.x="school1", by.y="ncessch", all.x=T, allow.cartesian=T)
dta.2 <- merge(dta.2, nces[,c("ncessch", "leaid", "latcode", "longcode", "combined.addr")],
               by.x="school2", by.y="ncessch", all.x=T, allow.cartesian=T)
names(dta.2) <- c("school1", "school2", "district1", "lat1", "long1", "combined.addr1",
                  "district2", "lat2", "long2", "combined.addr2")
## only keep the combinations where the districts are the same
dta.2 <- dta.2[dta.2$district1 == dta.2$district2,]
## append to the overall dataset
dta <- rbind(dta, dta.2)

## calculate distances within all combinations of schools
## takes ~3 sec to run
system.time({
  dta[,distance_hav := distHaversine(matrix(c(dta$long1, dta$lat1), ncol = 2),
                                     matrix(c(dta$long2, dta$lat2), ncol = 2))]
  ## convert to miles
  dta$distance_hav <- dta$distance_hav * 0.000621371
})

## take out the schools that don't have lat/long info
dta <- dta[dta$lat1 != 0 & dta$long1 != 0,]

##*********************************************************************************************************
## write out the distances

write.csv(dta, "data/processed/nces_14-15_school_distances.csv", row.names=F)
