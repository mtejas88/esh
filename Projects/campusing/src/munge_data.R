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
nces.districts <- read.csv("data/raw/nces_districts_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)

schools.2016 <- read.csv("data/raw/2016_schools.csv", as.is=T, header=T, stringsAsFactors=F)
deluxe.schools.2016 <- read.csv("data/raw/2016_deluxe_schools.csv", as.is=T, header=T, stringsAsFactors=F)
## since this data is not stored anywhere on the DB, it's stored in the repo
original.2016 <- read.csv("../../General_Resources/datasets/final_campus_groupings_2016-08-31_school_level.csv", as.is=T, header=T, stringsAsFactors=F)

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
schools.2016$school_nces_code <- correct_ids(schools.2016$school_nces_code, district=0)
deluxe.schools.2016$school_nces_cd <- correct_ids(deluxe.schools.2016$school_nces_cd, district=0)

##**************************************************************************************************************************************************
## find campuses that were manually changed by DQT last year and where the lat/long didn't change from 2016 and 2017

## for the schools.2016, categorize the campus "ids" by leading string
schools.2016$campus_id_type <- ifelse(grepl("campus_group_", schools.2016$campus_id), 1,
                                      ifelse(grepl("group_", schools.2016$campus_id), 2,
                                             ifelse(grepl("campus_", schools.2016$campus_id), 3, NA)))
## subset to the correct campus category
schools.2016 <- schools.2016[which(schools.2016$campus_id_type == 3),]

## create an indicator based on any campuses that changed by DQT in 2016
## first, compare original campusing with current campuses for 2016
schools.2016.sub <- schools.2016[,c('school_esh_id', 'campus_id')]
names(schools.2016.sub) <- c('school_esh_id', 'campus_id_updated')
combined.2016 <- merge(schools.2016.sub, original.2016, by='school_esh_id', all.x=T)
combined.2016$campus.change.2016 <- ifelse(combined.2016$campus_id_updated != combined.2016$campus_id, TRUE, FALSE)
combined.2016$campus_id_updated <- as.numeric(gsub("campus_", "", combined.2016$campus_id_updated))
## take unique campus_id and change indicator
combined.2016 <- unique(combined.2016[,c('campus_id_updated', 'campus.change.2016')])
## the campus_ids may be duplicated since some schools were changed and others not for the same campus
combined.2016.duplicates <- combined.2016$campus_id_updated[combined.2016$campus_id_updated %in%
                                                              combined.2016$campus_id_updated[duplicated(combined.2016$campus_id_updated)]]
## remove the duplicates
combined.2016 <- combined.2016[which(!combined.2016$campus_id_updated %in% combined.2016.duplicates),]
## add back in the duplicated ids with TRUE
duplicated.2016 <- data.frame(campus_id_updated=unique(combined.2016.duplicates), campus.change.2016=TRUE)
combined.2016 <- rbind(combined.2016, duplicated.2016)
## find the school ids associated with the changed campus in 2016
schools.2016$campus_id <- as.numeric(gsub("campus_", "", schools.2016$campus_id))
schools.changed.2016 <- merge(schools.2016[,c('campus_id', 'school_nces_code')], combined.2016, by.x='campus_id', by.y='campus_id_updated', all.x=T)
## merge in lat/long info from 2016
schools.changed.2016 <- merge(schools.changed.2016, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude')],
                              by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
## merge in lat/long info from 2017
schools.changed.2016 <- merge(schools.changed.2016, nces.location[,c('ncessch', 'latcode', 'longcode')],
                              by.x='school_nces_code', by.y='ncessch', all.x=T)
## round lat/long to 4 decimal places for 2017
schools.changed.2016$latcode <- round(schools.changed.2016$latcode, digits=4)
schools.changed.2016$longcode <- round(schools.changed.2016$longcode, digits=4)
## create an indicator if lat or long changed
schools.changed.2016$lat.or.long.changed <- ifelse(schools.changed.2016$latcode == schools.changed.2016$latitude &
                                                     schools.changed.2016$longcode == schools.changed.2016$longitude, FALSE, TRUE)
## subset to only the campuses that changed and the lat/long didn't change for all schools in the campus
schools.changed.2016 <- schools.changed.2016[which(schools.changed.2016$campus.change.2016 == TRUE),]
## so need to find the lat/long that changed in the subset and then take the opposite
campuses.lat.long.change <- schools.changed.2016$campus_id[which(schools.changed.2016$lat.or.long.changed == TRUE)]
schools.changed.2016 <- schools.changed.2016[which(!schools.changed.2016$campus_id %in% campuses.lat.long.change),]
## take out 1 school campuses
schools.changed.2016$counter <- 1
num.schools.agg <- aggregate(schools.changed.2016$counter, by=list(schools.changed.2016$campus_id), FUN=sum, na.rm=T)
schools.changed.2016 <- schools.changed.2016[schools.changed.2016$campus_id %in% num.schools.agg$Group.1[which(num.schools.agg$x > 1)],]
## now generate all combinations of school pairs in each campus
unique.campuses <- unique(schools.changed.2016$campus_id)
force.school.pairs <- NULL
for (i in 1:length(unique.campuses)){
  print(i)
  dta.sub <- schools.changed.2016[which(schools.changed.2016$campus_id == unique.campuses[i]),]
  force.school.pairs <- rbind(force.school.pairs, as.data.table(t(combnPrim(dta.sub$school_nces_code, 2))))
}
names(force.school.pairs) <- c('school1', 'school2')

##**************************************************************************************************************************************************
## other minor formatting

## subset schools data to only relevant columns
nces.schools <- nces.schools[,c('stabr', 'leaid', 'lea_name', 'ncessch', 'sch_name')]

## create a combined address field for each school
nces.location$combined.addr <- paste(nces.location$lstree, nces.location$lcity, nces.location$lstate, nces.location$lzip, sep=' ')
## format the address field to ignore punctuation
nces.location$combined.addr <- gsub("[[:punct:]]", "", nces.location$combined.addr)

## merge in lat/long into nces schools
nces.schools <- merge(nces.schools, nces.location[,c('ncessch', 'latcode', 'longcode', 'combined.addr')], by='ncessch', all.x=T)

## merge in district type (to capture charter districts)
nces.schools <- merge(nces.schools, nces.districts[,c('leaid', 'lea_type')], by='leaid', all.x=T)

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(nces.schools, "data/interim/nces_schools_subset.csv", row.names=F)
write.csv(force.school.pairs, "data/interim/2016_DQT_override_forced_school_pairs.csv", row.names=F)
