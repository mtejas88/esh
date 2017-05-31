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

fuzzy1 <- read.csv("../../General_Resources/datasets/bens_needing_fuzzy_matching_2017-05-25.csv", as.is=T, header=T, stringsAsFactors=F)
## it appears that all of the 114 bens are already in the first set above
#fuzzy2 <- read.csv("../../General_Resources/datasets/bens_needing_fuzzy_matching_2017-05-30.csv", as.is=T, header=T, stringsAsFactors=F)
usac.fuzzy <- read.csv("../../General_Resources/datasets/USAC_bens_needing_fuzzy_matching_2017-05-30.csv", as.is=T, header=T, stringsAsFactors=F)
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)

nces.schools <- read.csv("data/raw/nces_schools_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)
nces.location <- read.csv("data/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv", as.is=T, header=T, stringsAsFactors=F)
nces.districts <- read.csv("data/raw/nces_districts_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## subset and format data

## change column names to lowercase
names(nces.schools) <- tolower(names(nces.schools))
names(nces.location) <- tolower(names(nces.location))
names(nces.districts) <- tolower(names(nces.districts))
## correct ids using function
nces.schools$leaid <- correct_ids(nces.schools$leaid, district=1)
nces.schools$ncessch <- correct_ids(nces.schools$ncessch, district=0)
nces.location$ncessch <- correct_ids(nces.location$ncessch, district=0)
nces.districts$leaid <- correct_ids(nces.districts$leaid, district=1)

## subset schools data to only relevant columns
nces.schools <- nces.schools[,c('stabr', 'leaid', 'lea_name', 'ncessch', 'sch_name')]
## create a combined address field for each school
nces.location$combined.addr <- paste(nces.location$lstree, nces.location$lcity, nces.location$lstate, nces.location$lzip, sep=' ')
## format the address field to ignore punctuation
nces.location$combined.addr <- gsub("[[:punct:]]", "", nces.location$combined.addr)
## merge in lat/long into nces schools
nces.schools <- merge(nces.schools, nces.location[,c('ncessch', 'latcode', 'longcode', 'combined.addr',
                                                     'lstree', 'lcity', 'lstate', 'lzip')], by='ncessch', all.x=T)
## merge in district type (to capture charter districts)
nces.schools <- merge(nces.schools, nces.districts[,c('leaid', 'lea_type')], by='leaid', all.x=T)

## do all of the schools needed fuzzy matching exist in USAC's data?
sub <- usac.fuzzy[which(usac.fuzzy$ben %in% fuzzy1$ben),]
## which columns don't already exist in usac's dataset
names.to.merge <- c('ben', names(fuzzy1)[!names(fuzzy1) %in% names(usac.fuzzy)])
sub <- merge(sub, fuzzy1[,names.to.merge], by='ben', all.x=T)

## break out lat/long into two different columns
sub$latitude <- NA
sub$longitude <- NA
for (i in 1:nrow(sub)){
  sub$latitude[i] <- as.numeric(strsplit(sub$location.coordinates[i], ", ")[[1]][1])
  sub$longitude[i] <- as.numeric(strsplit(sub$location.coordinates[i], ", ")[[1]][2])
}

## round lat/long coordinates to 5 decimal places to match nces
sub$latitude <- round(sub$latitude, digits=5)
sub$longitude <- round(sub$longitude, digits=5)

## create a combined address field for each school
sub$org_zipcode <- ifelse(nchar(sub$org_zipcode) == 4, paste('0', sub$org_zipcode, sep=""), sub$org_zipcode)
sub$combined.addr <- paste(sub$org_address1, sub$org_address2, sub$org_city, sub$org_state, sub$org_zipcode, sep=' ')
## format the address field to ignore punctuation
sub$combined.addr <- gsub("[[:punct:]]", "", sub$combined.addr)

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(nces.schools, "data/interim/nces_schools_subset.csv", row.names=F)
write.csv(sub, "data/interim/bens_for_fuzzy_matching.csv", row.names=F)
