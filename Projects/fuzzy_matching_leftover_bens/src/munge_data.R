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
esh_ids_2017 <- read.csv("data/raw/2017_nces_to_entities.csv", as.is=T, header=T, stringsAsFactors=F)

nces.schools <- read.csv("data/raw/nces_schools_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)
nces.location <- read.csv("data/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv", as.is=T, header=T, stringsAsFactors=F)
nces.districts <- read.csv("data/raw/nces_districts_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## subset and format data

## FORMATE NCES
## change column names to lowercase
names(nces.schools) <- tolower(names(nces.schools))
names(nces.location) <- tolower(names(nces.location))
names(nces.districts) <- tolower(names(nces.districts))
## correct ids using function
nces.schools$leaid <- correct_ids(nces.schools$leaid, district=1)
nces.schools$ncessch <- correct_ids(nces.schools$ncessch, district=0)
nces.location$ncessch <- correct_ids(nces.location$ncessch, district=0)
nces.districts$leaid <- correct_ids(nces.districts$leaid, district=1)
esh_ids_2017$nces_code <- correct_ids(esh_ids_2017$nces_code, district=0)

## also format district nces id to match esh_ids_2017
nces.schools$leaid <- paste(nces.schools$leaid, "00000", sep="")
nces.districts$leaid <- paste(nces.districts$leaid, "00000", sep="")

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

## break out the address field (split number and street)
nces.schools$split_address <- gsub("^([0-9]+ +)?(.*)", "\\1\t\\2", nces.schools$lstree)
nces.schools.addresses <- read.delim(text = nces.schools$split_address, header = FALSE)
names(nces.schools.addresses) <- c('street_number', 'street_name')
nces.schools.addresses$street_name <- toupper(nces.schools.addresses$street_name)
nces.schools.addresses$ncessch <- nces.schools$ncessch
## merge back in
nces.schools <- merge(nces.schools, nces.schools.addresses, by='ncessch', all.x=T)

## create an indicator involving city, state, zip
nces.schools$lzip <- ifelse(nchar(nces.schools$lzip) == 4, paste('0', nces.schools$lzip, sep=""),
                            ifelse(nchar(nces.schools$lzip) == 3, paste('00', nces.schools$lzip, sep=""), nces.schools$lzip))
nces.schools$lcity <- toupper(nces.schools$lcity)
nces.schools$lstate <- toupper(nces.schools$lstate)
nces.schools$city.state.zip <- paste(nces.schools$lcity, nces.schools$lstate, nces.schools$lzip, sep=".")

## merge in esh_ids
nces.schools <- merge(nces.schools, esh_ids_2017[,c('nces_code', 'entity_id')], by.x="ncessch", by.y="nces_code", all.x=T)
names(nces.schools)[names(nces.schools) == 'entity_id'] <- 'school_esh_id'
nces.schools <- merge(nces.schools, esh_ids_2017[,c('nces_code', 'entity_id')], by.x="leaid", by.y="nces_code", all.x=T)
names(nces.schools)[names(nces.schools) == 'entity_id'] <- 'district_esh_id'


## FORMAT FUZZY SCHOOLS
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

## formatting
sub$org_zipcode <- ifelse(nchar(sub$org_zipcode) == 4, paste('0', sub$org_zipcode, sep=""), sub$org_zipcode)
sub$org_city <- gsub("\xd5", "", sub$org_city)
sub$org_city <- toupper(sub$org_city)
sub$org_state <- toupper(sub$org_state)

## break out the address field (split number and street)
sub$split_address <- gsub("^([0-9]+ +)?(.*)", "\\1\t\\2", sub$org_address1)
fuzzy.split.addresses <- read.delim(text = sub$split_address, header = FALSE)
names(fuzzy.split.addresses) <- c('street_number', 'street_name')
fuzzy.split.addresses$street_name <- toupper(fuzzy.split.addresses$street_name)
fuzzy.split.addresses$ben <- sub$ben
## merge back in
sub <- merge(sub, fuzzy.split.addresses, by='ben', all.x=T)

## create an indicator involving city, state, zip
sub$city.state.zip <- paste(sub$org_city, sub$org_state, sub$org_zipcode, sep=".")

## create a combined address field for each district
sub$combined.addr <- paste(sub$street_number, sub$street_name, sub$org_address2, sub$org_city, sub$org_state, sub$org_zipcode, sep=' ')
## format the address field to ignore punctuation
sub$combined.addr <- gsub("[[:punct:]]", "", sub$combined.addr)

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(nces.schools, "data/interim/nces_schools_subset.csv", row.names=F)
write.csv(sub, "data/interim/bens_for_fuzzy_matching.csv", row.names=F)
