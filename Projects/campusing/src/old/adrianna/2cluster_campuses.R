## =========================================================================
##
## CAMPUSING ALGORITHM: #2
## Cluster schools based on two criteria:
## 1) same combined address field, per the conclusion of investigating_campusing,
##    we want to campus schools with the same location address
## 2) distance calculated in CAMPUSING ALGORITHM #1 (threshold is currently 0.10 miles)
##
## Written by Adrianna Boghozian (AJB)
##
## Time Warning: will take ~ 10 min to run the entire script
##
## =========================================================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("~/Google Drive/Colocation/code/")

## load library
library(geosphere)
library(caTools)
library(ggmap)
library(dplyr)
library(data.table) ## for the fread command
library(gRbase) ## for combn function

## function to extend dataset to all combinations
all.combos <- function(dta){
  dta.ext <- dta[,c("school2", "school1")]
  names(dta.ext) <- c("school1", "school2")
  dta <- rbind(dta, dta.ext)
  return(dta)
}

## set threshold (in miles)
dist.threshold <- 0.10

## set date (for file naming)
date <- "TEST"

##*********************************************************************************************************
## READ IN FILES

## NCES raw school data
## takes ~ 22 secs to load
schools <- read.csv('../data/sc131a.csv')
schools$NCESSCH <- as.character(schools$NCESSCH)
## Variables of interest:
## NCESSCH_ADJ == school_id, unique
## LEAID == district_id
## LATCOD == Latitude
## LONCOD == Longitude

## get the school ids that we care about
real.schools <- read.csv("../data/fy2016_schools_demog_2016-08-30.csv", as.is=T, header=T)
## grab the district ids we care about
#district.ids <- unique(real.schools$nces_cd)
schools.ids <- unique(real.schools$school_nces_code)
## subset NCES raw data to the districts we care about
#schools <- schools[schools$LEAID %in% district.ids,]
schools <- schools[schools$NCESSCH %in% schools.ids,]

## distances calculated between schools
## takes about ~ 47 sec to read in
dta <- read.csv(paste("../data/all_distances_", date, ".csv", sep=""), header=T, as.is=T)

## compare with old version
dta.old <- read.csv("../data/old/all_distances_1_23.csv", as.is=T, header=T)


## reorder the columns
dta <- dta[,c("school1", "district1", "lat1", "long1", "combined.addr1", "school2",
              "district2", "lat2", "long2", "combined.addr2", "distance_hav")]

##*********************************************************************************************************
## Generate all combinations of schools that share the same address and append these combinations to the distance dataset
## as we want to force these schools to be campused no matter the distance threshold between them
## this is done without regard to the district id as some schools share the same combined address but are located in different districts

### COLLECT ALL OF THE UNIQUE ADDRESSES THAT ARE SHARED BY MORE THAN ONE SCHOOL
## create a combined address field
schools$combined.addr <- paste(schools$LSTREE, schools$LCITY, schools$LSTATE, schools$LZIP, sep=' ')
## collect all addresses that appear more than once in the dataset of schools
duplicated.addr <- schools$combined.addr[duplicated(schools$combined.addr)]
duplicated.addr <- unique(duplicated.addr)
## subset to those addresses
sub.duplicated <- schools[schools$combined.addr %in% duplicated.addr,]

### FOR EACH UNIQUE, DUPLICATED ADDRESS, FIND ALL PAIRWISE COMBINATIONS OF SCHOOLS
## takes ~ 5 min to run the loop
system.time({
  dta.same.addr.pairs <- NULL
  for (i in 1:length(duplicated.addr)){
    print(i)
    dta.sub <- schools[schools$combined.addr == duplicated.addr[i],]
    dta.same.addr.pairs <- rbind(dta.same.addr.pairs, as.data.table(t(combnPrim(dta.sub$NCESSCH_ADJ, 2))))
  }
})
## name the columns
names(dta.same.addr.pairs) <- c("school1", "school2")

## write out dataset (to save, but also due to a weird subsetting error in R)
write.csv(dta.same.addr.pairs, paste("../data/same_address_pairs_", date, ".csv", sep=""), row.names=F)
## read back in
dta.same.addr.pairs <- read.csv(paste("../data/same_address_pairs_", date, ".csv", sep=""), as.is=T, header=T)

##*********************************************************************************************************
## Generate all Campus groupings by combining pairs of schools
## for example, if A -> B, B -> C, then A, B, C are 1 campus

### COMBINE THE FORCED SCHOOL PAIRS (BY ADDRESS) WITH THE SCHOOL PAIRS THAT MEET THE DISTANCE THRESHOLD
## subset to the pairs that meet the distance threshold
dta.dist <- dta[dta$distance_hav <= dist.threshold,]
## subset the distance dataset to just be the school pairs
dta.dist <- dta.dist[,c("school1", "school2")]
## extend distance dataset to all combinations of the schools with the same address
## also so every school can be found in the first column
dta.dist <- all.combos(dta.dist)
## order the dataset by school1
dta.dist <- dta.dist[order(dta.dist$school1),]
## create a unique combination identifier
dta.dist$combo <- paste(dta.dist$school1, dta.dist$school2, sep=".")

## extend dataset to all combinations of the schools with the same address
dta.same.addr.pairs <- all.combos(dta.same.addr.pairs)
## order the dataset by school1
dta.same.addr.pairs <- dta.same.addr.pairs[order(dta.same.addr.pairs$school1),]
## create a unique combination identifier
dta.same.addr.pairs$combo <- paste(dta.same.addr.pairs$school1, dta.same.addr.pairs$school2, sep=".")
## subset to only the same address pairs that were not previously caught by the distance threshold
dta.same.addr.pairs <- dta.same.addr.pairs[!dta.same.addr.pairs$combo %in% dta.dist$combo,]
## rbind the remaining pairs
dta.dist <- rbind(dta.dist, dta.same.addr.pairs)
## get rid of combo value
dta.dist$combo <- NULL


### GENERATE CAMPUS GROUPINGS

## initialize lists and datasets
## master list of schools, schools will be removed from this list when they are made into a campus
master.sch.list <- unique(dta.dist$school1)
## this list will collect the matches for each campus
master.match.list <- NULL
## set the master groupings dataset so can subset to find matches
master <- dta.dist
## prep final dataset (note: the number of rows initialized will be MUCH more than needed)
final.campus <- data.frame(matrix(NA, nrow=nrow(schools), ncol=2))
names(final.campus) <- c("campus.id", "schools")

## takes ~ 3 min to run
system.time({
  i <- 1
  while (length(master.sch.list) != 0){
    print(i)
    master.match.list <- NULL
    match.list1 <- master.sch.list[1]
    master.match.list <- append(master.match.list, match.list1)
    match.list2 <- master$school2[master$school1 %in% match.list1]
    while (length(match.list2) != 0){
      master <- master[!master$school1 %in% match.list1 & !master$school2 %in% match.list1,]
      master.match.list <- append(master.match.list, match.list2)
      match.list1 <- match.list2
      master <- master[!master$school2 %in% match.list1,]
      match.list2 <- master$school2[master$school1 %in% match.list1]
    }
    final.campus$campus.id[i] <- i
    ## make sure master.match.list is unique (there are a few cases where the same schools were included twice in the same campus)
    master.match.list <- unique(master.match.list)
    final.campus$schools[i] <- paste(unlist(master.match.list), collapse=", ")
    master.sch.list <- master.sch.list[!master.sch.list %in% master.match.list]
    i <- i + 1
  }
})
## take out the NA rows
final.campus <- final.campus[!is.na(final.campus$campus.id),]

##*********************************************************************************************************
## Checks and Formatting

## run a few checks on the campuses:
## 1) every school should only be assigned to 1 campus
##    also collect number of schools in each campus
master.schools.check <- NULL
num.schools <- NULL
## takes ~ 2 sec to run
for (i in 1:nrow(final.campus)){
  master.schools.check <- append(master.schools.check, unlist(strsplit(final.campus$schools[i], split=", ")))
  num.schools <- append(num.schools, length(unlist(strsplit(final.campus$schools[i], split=", "))))
}
## check if the number of schools in the master list is equal to the number of unique schools
length(master.schools.check) == length(unique(master.schools.check))
## assign number of schools column to final.campus
final.campus$num.schools <- num.schools
## look at distribution of schools in campuses
table(final.campus$num.schools)

## add in the schools that were not campused (assign them a unique campus id)
schools.ids <- unique(as.character(schools$NCESSCH_ADJ))
schools.ids.no.campus <- schools.ids[!schools.ids %in% master.schools.check]
final.campus.no.campus <- data.frame(campus.id = seq(nrow(final.campus)+1, nrow(final.campus)+length(schools.ids.no.campus)), schools = schools.ids.no.campus)
final.campus.no.campus$num.schools <- 1
## rbind with master
final.campus <- rbind(final.campus, final.campus.no.campus)

## create a version of the final dataset that matches each school to a campus id, on the school level
final.campus.sch.level <- data.frame(school_id=c(master.schools.check, schools.ids.no.campus), campus_id=rep(final.campus$campus.id, final.campus$num.schools))
final.campus.sch.level$campus_id <- paste("campus_", final.campus.sch.level$campus_id, sep="")
## merge in the NCES school id (instead of the unique one we created)
final.campus.sch.level$school_id <- as.character(final.campus.sch.level$school_id)
dta <- schools[,c("NCESSCH_ADJ", "NCESSCH")]
dta$NCESSCH_ADJ <- as.character(dta$NCESSCH_ADJ)
## merge dta with real.schools to get the school_esh_id
dta <- merge(dta, real.schools[,c("school_nces_code", "school_esh_id")], by.x="NCESSCH", by.y="school_nces_code", all.x=T)
## drop NCESSCH
dta$NCESSCH <- NULL
final.campus.sch.level <- merge(final.campus.sch.level, dta, by.x='school_id', by.y="NCESSCH_ADJ", all.x=T)
## order based on campus grouping number
final.campus.sch.level <- final.campus.sch.level[order(final.campus.sch.level$school_esh_id),]
## take out school_id column
final.campus.sch.level$school_id <- NULL
final.campus.sch.level <- final.campus.sch.level[,c("school_esh_id", "campus_id")]

## 2) percentage of schools campused (>= 2 schools)
paste(round((length(master.schools.check) / nrow(schools))*100, 0), "%", sep="")
## percentage of schools campused (all)
paste(round((nrow(final.campus) / nrow(schools))*100, 0), "%", sep="")


## read in old campus data (from CF)
#dta.old.campus <- read.csv("../data/old/campuses_upload_1_27.csv", as.is=T, header=T)
## group schools together based on their campus id
#old.campus.agg <- aggregate(school_id ~ campus_group, data=dta.old.campus, paste, collapse=", ")
#master.schools.check.old <- NULL
#num.schools.old <- NULL
## takes ~ 2 sec to run
#for (i in 1:nrow(old.campus.agg)){
#  master.schools.check.old <- append(master.schools.check.old, unlist(strsplit(old.campus.agg$school_id[i], split=", ")))
#  num.schools.old <- append(num.schools.old, length(unlist(strsplit(old.campus.agg$school_id[i], split=", "))))
#}
#old.campus.agg$num_schools <- num.schools.old


## write out final campus grouping
write.csv(final.campus, paste("../data/final_campus_groupings_", date, ".csv", sep=""), row.names=F)
write.csv(final.campus.sch.level, paste("../data/final_campus_groupings_", date, "_school_level.csv", sep=""), row.names=F)
