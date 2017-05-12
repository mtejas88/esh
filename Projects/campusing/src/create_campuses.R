## =========================================================================
##
## CAMPUSING ALGORITHM: #2
## Cluster schools based on two criteria:
## 1) same combined address field, per the conclusion of investigating_campusing,
##    we want to campus schools with the same location address
## 2) distance calculated in CAMPUSING ALGORITHM #1 (threshold is currently 0.10 miles)
##
## Time Warning: will take ~ 10 min to run the entire script
##
## =========================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
## make sure the dtplyr (used to be known as data.table package)
## is a more recent version: install.packages("data.table", type = "source", repos = "http://Rdatatable.github.io/data.table")
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
library(dtplyr) ## for the fread command
library(data.table)

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

## function to extend dataset to all combinations
all.combos <- function(dta){
  dta.ext <- dta[,c("school2", "school1")]
  names(dta.ext) <- c("school1", "school2")
  dta <- rbind(dta, dta.ext)
  return(dta)
}

## set threshold (in miles)
dist.threshold <- 0.10

##*********************************************************************************************************
## read in data

## (takes a couple minutes to read in)
dta <- read.csv("data/processed/nces_14-15_school_distances.csv", as.is=T, header=T, stringsAsFactors=F)
nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
## 2016 campus overrides by DQT (only when the location of the school didn't change from 2016 to 2017)
dta.dqt.2016 <- read.csv("data/interim/2016_DQT_override_forced_school_pairs.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## format data

## reorder the columns
setcolorder(dta, c("school1", "district1", "lat1", "long1", "combined.addr1", "school2",
                   "district2", "lat2", "long2", "combined.addr2", "distance_hav"))

## correct ids using function
dta$district1 <- correct_ids(dta$district1, district=1)
dta$district2 <- correct_ids(dta$district2, district=1)
dta$school1 <- correct_ids(dta$school1, district=0)
dta$school2 <- correct_ids(dta$school2, district=0)
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)
dta.dqt.2016$school1 <- correct_ids(dta.dqt.2016$school1, district=0)
dta.dqt.2016$school2 <- correct_ids(dta.dqt.2016$school2, district=0)

## extend data frame for the dqt overrides
dta.dqt.2016 <- all.combos(dta.dqt.2016)

##*********************************************************************************************************
## Generate all combinations of schools that share the same address and append these combinations to the distance dataset
## as we want to force these schools to be campused no matter the distance threshold between them
## this is done without regard to the district id as some schools share the same combined address but are located in different districts

### COLLECT ALL OF THE UNIQUE ADDRESSES THAT ARE SHARED BY MORE THAN ONE SCHOOL
## force the combined address to only work when the district id is the same, so add it to the combined address field
nces$combined.addr.rev <- paste(nces$combined.addr, nces$leaid, sep=" ")
#duplicated.addr <- nces$combined.addr.rev[which(duplicated(nces$combined.addr.rev))]
duplicated.addr <- nces$combined.addr[which(duplicated(nces$combined.addr))]
duplicated.addr <- unique(duplicated.addr)
duplicated.addr <- duplicated.addr[!is.na(duplicated.addr)]
## subset to those addresses
#sub.duplicated <- nces[which(nces$combined.addr.rev %in% duplicated.addr),]
sub.duplicated <- nces[which(nces$combined.addr %in% duplicated.addr),]

### FOR EACH UNIQUE, DUPLICATED ADDRESS, FIND ALL PAIRWISE COMBINATIONS OF SCHOOLS
## takes ~1 min to run the loop
system.time({
  dta.same.addr.pairs <- NULL
  for (i in 1:length(duplicated.addr)){
    print(i)
    #dta.sub <- nces[which(nces$combined.addr.rev == duplicated.addr[i]),]
    dta.sub <- nces[which(nces$combined.addr == duplicated.addr[i]),]
    dta.same.addr.pairs <- rbind(dta.same.addr.pairs, as.data.table(t(combnPrim(dta.sub$ncessch, 2))))
  }
})
## name the columns
names(dta.same.addr.pairs) <- c("school1", "school2")

## FOR FURTHER ANALYSIS: DO WE WANT TO CAMPUS ALL SCHOOLS IF THEY SHARE AN FULL ADDRESS (EVEN IF IT'S ACROSS DISTRICTS)?
## merge in combined.address and school type
dta.same.addr.pairs.investigate <- merge(dta.same.addr.pairs, nces[,c('ncessch', 'sch_name', 'combined.addr',
                                                          'lea_type', 'leaid')], by.x='school1', by.y='ncessch', all.x=T)
names(dta.same.addr.pairs.investigate)[names(dta.same.addr.pairs.investigate) %in%
                                         c('sch_name', 'combined.addr', 'lea_type', 'leaid')] <-c('school.name.1',
                                                                                                  'combined.addr.1', 'lea_type.1', 'leaid.1')
dta.same.addr.pairs.investigate <- merge(dta.same.addr.pairs.investigate, nces[,c('ncessch', 'sch_name', 'combined.addr', 'lea_type', 'leaid')],
                                         by.x='school2', by.y='ncessch', all.x=T)
names(dta.same.addr.pairs.investigate)[names(dta.same.addr.pairs.investigate) %in%
                                         c('sch_name', 'combined.addr', 'lea_type', 'leaid')] <- c('school.name.2',
                                                                                                   'combined.addr.2', 'lea_type.2', 'leaid.2')
## subset to the schools that get paired with charter districts
sub.charter <- dta.same.addr.pairs.investigate[which(dta.same.addr.pairs.investigate$lea_type.1 == 7 |
                                                       dta.same.addr.pairs.investigate$lea_type.2 == 7),]
## subset to the schools that get paired with different district ids
sub.different.district.matches <- dta.same.addr.pairs.investigate[which(dta.same.addr.pairs.investigate$leaid.1 !=
                                                                          dta.same.addr.pairs.investigate$leaid.2),]
## breakdown of district types matched across different district ids
table(sub.different.district.matches$lea_type.1, sub.different.district.matches$lea_type.2)
## look at district type 1s that get matched together across district ids
sub.type.1.to.1 <- sub.different.district.matches[which(sub.different.district.matches$lea_type.1 == 1 &
                                                          sub.different.district.matches$lea_type.2 == 1),]

write.csv(sub.charter, "data/qa/charter_schools_matched_on_address_field.csv", row.names=F)
write.csv(sub.different.district.matches, "data/qa/all_schools_matched_on_address_field_across_different_district_ids.csv", row.names=F)
write.csv(sub.type.1.to.1, "data/qa/1_to_1_schools_matched_on_address_field_across_different_district_ids.csv", row.names=F)

##*********************************************************************************************************
## Generate all Campus groupings by combining pairs of schools
## for example, if A -> B, B -> C, then A, B, C are 1 campus

### COMBINE THE FORCED SCHOOL PAIRS (BY ADDRESS) WITH THE SCHOOL PAIRS THAT MEET THE DISTANCE THRESHOLD
### AND THE FORCED SCHOOL PAIRS FROM DQT REVIEW LAST YEAR (WHEN THE SCHOOL LOCATION DIDN'T CHANGE IN 2017)

## subset to the pairs that meet the distance threshold
dta.dist <- subset(dta, dta$distance_hav <= dist.threshold)
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
dta.same.addr.pairs <- dta.same.addr.pairs[which(!dta.same.addr.pairs$combo %in% dta.dist$combo),]
## rbind the remaining pairs
dta.dist <- rbind(dta.dist, dta.same.addr.pairs)

## create combination indicator for dqt forced pairs
dta.dqt.2016$combo <- paste(dta.dqt.2016$school1, dta.dqt.2016$school2, sep=".")
## subset to only the same address pairs that were not previously caught by the distance threshold
dta.dqt.2016 <- dta.dqt.2016[which(!dta.dqt.2016$combo %in% dta.dist$combo),]
## rbind the remaining pairs
dta.dist <- rbind(dta.dist, dta.dqt.2016)

## get rid of combo value
dta.dist$combo <- NULL

##*********************************************************************************************************
### GENERATE CAMPUS GROUPINGS
## initialize lists and datasets
## master list of schools, schools will be removed from this list when they are made into a campus
master.sch.list <- unique(dta.dist$school1)
## this list will collect the matches for each campus
master.match.list <- NULL
## set the master groupings dataset so can subset to find matches
master <- dta.dist
## prep final dataset (note: the number of rows initialized will be MUCH more than needed)
final.campus <- data.frame(matrix(NA, nrow=nrow(nces), ncol=2))
names(final.campus) <- c("campus.id", "schools")

## takes ~2 min to run
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
## write out data

write.csv(final.campus, paste("data/processed/final_campuses_threshold_", dist.threshold, "_miles.csv", sep=""), row.names=F)
