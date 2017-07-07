## =========================================================================
##
## CAMPUSING ALGORITHM: EVALUATING QA
##
## =========================================================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##*********************************************************************************************************
## read in data

nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
deluxe.schools.2016 <- read.csv("data/raw/2016_deluxe_schools.csv", as.is=T, header=T, stringsAsFactors=F)
qa.2016 <- read.csv("data/qa/2016_schools_reassigned_qa.csv", as.is=T, header=T, stringsAsFactors=F)
qa.2017 <- read.csv("data/qa/2017_schools_added_to_existing_campus_qa.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## format qa data

nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)
deluxe.schools.2016$school_nces_cd <- correct_ids(deluxe.schools.2016$school_nces_cd, district=0)
qa.2016$school_nces_code <- correct_ids(qa.2016$school_nces_code, district=0)
qa.2017$school_nces_code <- correct_ids(qa.2017$school_nces_code, district=0)

deluxe.schools.2016$combined.address <- paste(deluxe.schools.2016$address, deluxe.schools.2016$city,
                                              deluxe.schools.2016$postal_cd, deluxe.schools.2016$zip, sep=' ')

##*********************************************************************************************************
## format 2017 QA dataset

names(qa.2017) <- tolower(names(qa.2017))
qa.2017$qa.pass <- tolower(qa.2017$qa.pass)
qa.2017 <- qa.2017[,c(1:10)]
qa.2017$qa.pass <- ifelse(qa.2017$qa.pass == 'f' | qa.2017$qa.pass == 'n', FALSE,
                          ifelse(qa.2017$qa.pass == 'p' | qa.2017$qa.pass == 'y', TRUE,
                                 ifelse(qa.2017$qa.pass == 'u', 'UNDECIDED', NA)))

## merge in lat/long in 2016 and 2017
qa.2017 <- merge(qa.2017, nces[,c('ncessch', 'latcode', 'longcode')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(qa.2017)[names(qa.2017) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
qa.2017 <- merge(qa.2017, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude')], by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(qa.2017)[names(qa.2017) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
## round 2017 to match 2016
qa.2017$lat.2017 <- round(qa.2017$lat.2017, digits=4)
qa.2017$long.2017 <- round(qa.2017$long.2017, digits=4)

## also merge in school names and addresses
qa.2017 <- merge(qa.2017, nces[,c('ncessch', 'sch_name', 'combined.addr')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(qa.2017)[names(qa.2017) == 'combined.addr'] <- 'combined.addr.2017'
names(qa.2017)[names(qa.2017) == 'sch_name'] <- 'name.2017'
qa.2017 <- merge(qa.2017, deluxe.schools.2016[,c('school_nces_cd', 'name', 'combined.address')],
                 by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(qa.2017)[names(qa.2017) == 'combined.address'] <- 'combined.addr.2016'
names(qa.2017)[names(qa.2017) == 'name'] <- 'name.2016'

## format dataset
qa.2017 <- qa.2017[,c("school_nces_code", "district_esh_id", "assignment", "campus_id_2016", "campus_id_2017", "campus.change.2016",
                      "locale", "lat.or.long.diff", "qa.pass", "notes", "lat.2016", "long.2016",
                      "lat.2017", "long.2017", "name.2016", "name.2017", "combined.addr.2016", "combined.addr.2017")]

## look into the ids that did not pass QA
## collect the 2017 campus ids that did not pass
which.2017.ids.not.pass <- qa.2017$campus_id_2017[which(qa.2017$qa.pass == FALSE)]
sub.2017.false <- qa.2017[which(qa.2017$campus_id_2017 %in% which.2017.ids.not.pass),]

## create an indicator if the address didn't match in 2016 but matches group in 2017
sub.2017.false$address.matches.2017 <- NA
for (i in 1:nrow(sub.2017.false)){
  collect.2017.addresses <- unique(sub.2017.false$combined.addr.2017[which(sub.2017.false$campus_id_2017 == sub.2017.false$campus_id_2017[i])])
  if (sub.2017.false$combined.addr.2017[i] %in% collect.2017.addresses){
    sub.2017.false$address.matches.2017[i] <- TRUE
  }
}

##*********************************************************************************************************
## format 2016 QA dataset

names(qa.2016) <- tolower(names(qa.2016))
qa.2016$qa.pass <- tolower(qa.2016$qa.pass)
qa.2016 <- qa.2016[,c(1:10)]
qa.2016$qa.pass <- ifelse(qa.2016$qa.pass == 'f' | qa.2016$qa.pass == 'n', FALSE,
                          ifelse(qa.2016$qa.pass == 'p' | qa.2016$qa.pass == 'y', TRUE,
                                 ifelse(qa.2016$qa.pass == 'u', 'UNDECIDED', NA)))

## merge in lat/long in 2016 and 2017
qa.2016 <- merge(qa.2016, nces[,c('ncessch', 'latcode', 'longcode')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(qa.2016)[names(qa.2016) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
qa.2016 <- merge(qa.2016, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude')], by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(qa.2016)[names(qa.2016) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
## round 2017 to match 2016
qa.2016$lat.2017 <- round(qa.2016$lat.2017, digits=4)
qa.2016$long.2017 <- round(qa.2016$long.2017, digits=4)

## also merge in school names and addresses
qa.2016 <- merge(qa.2016, nces[,c('ncessch', 'sch_name', 'combined.addr')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(qa.2016)[names(qa.2016) == 'combined.addr'] <- 'combined.addr.2017'
names(qa.2016)[names(qa.2016) == 'sch_name'] <- 'name.2017'
qa.2016 <- merge(qa.2016, deluxe.schools.2016[,c('school_nces_cd', 'name', 'combined.address')],
                 by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(qa.2016)[names(qa.2016) == 'combined.address'] <- 'combined.addr.2016'
names(qa.2016)[names(qa.2016) == 'name'] <- 'name.2016'

## format dataset
qa.2016 <- qa.2016[,c("school_nces_code", "district_esh_id", "assignment", "campus_id_2016", "campus_id_2017", "campus.change.2016",
                      "locale", "lat.or.long.diff", "qa.pass", "notes", "lat.2016", "long.2016",
                      "lat.2017", "long.2017", "name.2016", "name.2017", "combined.addr.2016", "combined.addr.2017")]
