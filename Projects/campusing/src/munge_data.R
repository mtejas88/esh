## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##**************************************************************************************************************************************************
## read in data

nces.schools <- read.csv("data/raw/nces_schools_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)
nces.location <- read.csv("data/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## subset and format data

## change column names to lowercase
names(nces.schools) <- tolower(names(nces.schools))
names(nces.location) <- tolower(names(nces.location))

## correct ids using function
nces.schools$leaid <- correct_ids(nces.schools$leaid, district=1)
nces.schools$ncessch <- correct_ids(nces.schools$ncessch, district=0)
nces.location$ncessch <- correct_ids(nces.location$ncessch, district=0)

## subset schools data to only relevant columns
nces.schools <- nces.schools[,c('stabr', 'leaid', 'lea_name', 'ncessch', 'sch_name')]

## create a combined address field for each school
nces.location$combined.addr <- paste(nces.location$lstree, nces.location$lcity, nces.location$lstate, nces.location$lzip, sep=' ')

## merge in lat/long into nces schools
nces.schools <- merge(nces.schools, nces.location[,c('ncessch', 'latcode', 'longcode', 'combined.addr')], by='ncessch', all.x=T)

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(nces.schools, "data/interim/nces_schools_subset.csv", row.names=F)
