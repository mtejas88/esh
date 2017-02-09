## =========================================================================
##
## INVESTIGATING CAMPUSING
## For Sprint 08/22/16: SAT-1958 (AJB)
##
## This script aims to answer the following questions:
## 1) Can we trust the NCES lat/long data if there are instances where the location street address is the exact same string,
##    but the algorithm is not capturing the schools correctly?
## 2) Why would the lat/long be different for two schools with the same address field?
## 3) Is it worth re-geocoding the address field through something like Google API?
##
## See Document ../docs/Campus_Sampling.rtf for summary
##
## =========================================================================

## Clearing memory
rm(list=ls())

setwd("~/Desktop/ficher/Tools/Colocation/code/")

library(geosphere)
library(caTools)
library(ggmap)
library(dplyr)
library(data.table) ## for the fread command
### the following dependencies may be necessary, install as follows:
### source("http://bioconductor.org/biocLite.R")
### biocLite("graph")
### biocLite("BiocGenerics")
### biocLite("RBGL")
library(gRbase) ## for the combnPrim command
#library(formattable)

##*********************************************************************************************************
## READ IN FILES

### Select all schools
#schools_query <- "
#select * 
#from schools
#"
#schools <- dbGetQuery(con, schools_query)
## takes ~ 22 secs to load
schools <- read.csv('../data/sc131a.csv')
## use "fread" since sc131a.csv is a large file
#schools <- fread("data/sc131a.csv")

## Variables of interest:
## NCESSCH_ADJ == school_id, unique
## LEAID == district_id
## LATCOD == Latitude
## LONCOD == Longitude

## FUNCTIONS
### Function to compute distance
#calc.distance <- function(lat1, long1, lat2, long2) {
#  distm(c(long1, lat1), c(long2, lat2), fun = distHaversine)
#}

##*********************************************************************************************************
## GOOGLE API: AIzaSyDJBVhprU8mbdID2xbALrwxQSvODrtGKUU

## first, create a combined address field
schools$combined.addr <- paste(schools$LSTREE, schools$LCITY, schools$LSTATE, schools$LZIP, sep=' ')
schools.sub <- schools[,c("NCESSCH_ADJ", "LEAID", "LEANM", "SCHNAM", "LSTREE", "LCITY", "LSTATE", "LZIP", "CONAME", "LATCOD", "LONCOD", "combined.addr")]
## take out the schools that don't have lat/long info for now
schools.sub <- schools.sub[schools.sub$LATCOD != 0 & schools.sub$LONCOD != 0,]
## sample 2,000 schools for API
#schools.geo.sample <- schools.sub[sample(1:nrow(schools.sub), 2000),]

## find schools that have the exact same address field
schools.duplicate.addr <- schools.sub[schools.sub$combined.addr %in% schools.sub$combined.addr[duplicated(schools.sub$combined.addr)],]
## sort by address
schools.duplicate.addr <- schools.duplicate.addr[order(schools.duplicate.addr$combined.addr),]
## collect unique addresses
addrs <- unique(schools.duplicate.addr$combined.addr)

## create a flag if lat/long does not match for each duplicated address
flag <- NULL
## takes ~ 9 sec to run
for (i in 1:length(addrs)){
  sub <- schools.duplicate.addr[schools.duplicate.addr$combined.addr == addrs[i],]
  if (length(unique(sub$LATCOD)) == 1 & length(unique(sub$LONCOD)) == 1){
    flag <- append(flag, rep(0, nrow(sub)))
  } else{
    flag <- append(flag, rep(1, nrow(sub)))
  }
}
## assign flag
schools.duplicate.addr$flag <- flag
## aggregate unique addresses by flag to see how many differ
agg.addr <- aggregate(schools.duplicate.addr$flag, by=list(schools.duplicate.addr$combined.addr), FUN=sum)
names(agg.addr) <- c("combined.addr", "num.flags")
table(agg.addr$num.flags > 0)

## subset to the addresses that do have matching lat/long, look at the distribution of how many schools per unique address
schools.duplicate.addr.match <- schools.duplicate.addr[schools.duplicate.addr$flag == 0,]
length(unique(schools.duplicate.addr.match$combined.addr))
schools.duplicate.addr.match$counter <- 1
agg.addr.match <- aggregate(schools.duplicate.addr.match$counter, by=list(schools.duplicate.addr.match$combined.addr), FUN=sum)
table(agg.addr.match$x)

## subset to the addresses that do not have matching lat/long
schools.duplicate.addr.no.match <- schools.duplicate.addr[schools.duplicate.addr$flag == 1,]
length(unique(schools.duplicate.addr.no.match$combined.addr))

## calculate distance of schools in the same district to see if they'd be captured by our algorithm anyway
### FIND ALL POSSIBLE COMBINATIONS OF SCHOOLS WITHIN EACH DISTRICT
schools.duplicate.addr.no.match$counter <- 1
## check distribution of schools to combined addresses
agg.addr.no.match <- aggregate(schools.duplicate.addr.no.match$counter, by=list(schools.duplicate.addr.no.match$combined.addr), FUN=sum)
table(agg.addr.no.match$x)
## keep only districts with 2 or more schools in subset
district.agg <- aggregate(schools.duplicate.addr.no.match$counter, by=list(schools.duplicate.addr.no.match$LEAID), FUN=sum)
## it appears that 357 districts only have one school in this subset, even though there are at least two schools with every matching address
## why would the district id (LEAID) be different for two schools with the same address??
sub <- schools.duplicate.addr.no.match[schools.duplicate.addr.no.match$LEAID %in% district.agg$Group.1[district.agg$x == 1],]
## for now, let's take out the districts with only 1 school, so we can run the combination code
schools.duplicate.addr.no.match <- schools.duplicate.addr.no.match[schools.duplicate.addr.no.match$LEAID %in% district.agg$Group.1[district.agg$x > 1],]
districts.addr.no.match <- unique(schools.duplicate.addr.no.match$LEAID)
## append all combinations of school pairings within a district
## takes ~ 5 sec to run the loop
system.time({
  dta <- NULL
  for (i in 1:length(districts.addr.no.match)){
    print(i)
    dta.sub <- schools.duplicate.addr.no.match[schools.duplicate.addr.no.match$LEAID == districts.addr.no.match[i],]
    dta <- rbind(dta, as.data.table(t(combnPrim(dta.sub$NCESSCH_ADJ, 2))))
  }
})
names(dta) <- c("school1", "school2")

## merge in district and lat/long information for each school
dta <- merge(dta, schools[,c("NCESSCH_ADJ", "LEAID", "SCHNAM", "combined.addr", "LATCOD", "LONCOD")], by.x="school1", by.y="NCESSCH_ADJ", all.x=T)
dta <- merge(dta, schools[,c("NCESSCH_ADJ", "LEAID", "SCHNAM", "combined.addr", "LATCOD", "LONCOD")], by.x="school2", by.y="NCESSCH_ADJ", all.x=T)
names(dta) <- c("school1", "school2", "district1", "school.name1", "combined.addr1", "lat1", "long1",
                "district2", "school.name2", "combined.addr2", "lat2", "long2")
## only keep the combinations with the same combined address
dta <- dta[dta$combined.addr1 == dta$combined.addr2,]

## calculate distance
dta[,distance := distHaversine(matrix(c(dta$long1, dta$lat1), ncol = 2),
                               matrix(c(dta$long2, dta$lat2), ncol = 2))]
## convert to miles
dta$distance <- dta$distance * 0.000621371

## make flag if it would meet our algorithm currently
dta$meet.algorithm <- ifelse(dta$distance < .1, 1, 0)
table(dta$meet.algorithm)

## sample from the addresses that do not meet the algorithm
dta.no.alg <- dta[dta$meet.algorithm == 0,]
## merge in locale to see if there's a pattern
dta.no.alg <- merge(dta.no.alg, schools[,c("NCESSCH_ADJ", "ULOCAL")], by.x="school1", by.y="NCESSCH_ADJ", all.x=T)
## calculate the mean distance of the addresses that do not meet the algorithm
mean(dta.no.alg$distance)
schools.sample.no.match <- dta.no.alg[sample(1:nrow(dta.no.alg), 100),]

dta.alg <- dta[dta$meet.algorithm == 1,]
## calculate the mean distance of the addresses that do meet the algorithm
mean(dta.alg$distance)

## alternatively,
## subset to the addresses that do have matching lat/long
schools.duplicate.addr.match <- schools.duplicate.addr[schools.duplicate.addr$flag == 0,]
## take a sample
schools.sample.match <- schools.duplicate.addr.match[schools.duplicate.addr.match$combined.addr %in%
                                                       sample(unique(schools.duplicate.addr.match$combined.addr), 100),]
## also sample from the addresses with 5 or more schools sharing the same address
schools.match.g4 <- schools.duplicate.addr.match[schools.duplicate.addr.match$combined.addr %in% agg.addr.match$Group.1[agg.addr.match$x > 4],]
## merge in the actual number of schools associated with each unique address so we can sort
schools.match.g4 <- merge(schools.match.g4, agg.addr.match, by.x="combined.addr", by.y="Group.1", all.x=T)
names(schools.match.g4)[names(schools.match.g4) == "x"] <- "num.schools"
## order based on number of schools, decreasing == T
schools.match.g4 <- schools.match.g4[order(schools.match.g4$num.schools, decreasing = TRUE),]
