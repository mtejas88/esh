## =========================================================================
##
## CAMPUSING ALGORITHM: CROSS YEAR COMPARISON
## Investigating differences between campusing in 2016 and 2017 results
##
## =========================================================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##*********************************************************************************************************
## read in data

final.campus.sch.level <- read.csv("data/processed/final_campuses_school_level.csv", as.is=T, header=T, stringsAsFactors=F)
nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
schools.2016 <- read.csv("data/raw/2016_schools.csv", as.is=T, header=T, stringsAsFactors=F)
deluxe.schools.2016 <- read.csv("data/raw/2016_deluxe_schools.csv", as.is=T, header=T, stringsAsFactors=F)
## since this data is not stored anywhere on the DB, it's stored in the repo
original.2016 <- read.csv("../../General_Resources/datasets/final_campus_groupings_2016-08-31_school_level.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## format data

## correct ids using function
schools.2016$school_nces_code <- correct_ids(schools.2016$school_nces_code, district=0)
deluxe.schools.2016$school_nces_cd <- correct_ids(deluxe.schools.2016$school_nces_cd, district=0)
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)
final.campus.sch.level$school_id <- correct_ids(final.campus.sch.level$school_id, district=0)
final.campus.sch.level$leaid <- correct_ids(final.campus.sch.level$leaid, district=1)

## for the schools.2016, categorize the campus "ids" by leading string
schools.2016$campus_id_type <- ifelse(grepl("campus_group_", schools.2016$campus_id), 1,
                                      ifelse(grepl("group_", schools.2016$campus_id), 2,
                                             ifelse(grepl("campus_", schools.2016$campus_id), 3, NA)))
table(schools.2016$campus_id_type)
## subset to the correct campus category
schools.2016 <- schools.2016[which(schools.2016$campus_id_type == 3),]

##*********************************************************************************************************
## Compare with 2016 campusing (ideally retain the 2016 campus_id)

sub.campus.ids <- merge(schools.2016[,c('school_nces_code', 'campus_id')],
                        final.campus.sch.level[,c('school_id', 'campus_id_2017')],
                        by.x='school_nces_code', by.y='school_id', all=T)
names(sub.campus.ids)[names(sub.campus.ids) == "campus_id"] <- "campus_id_2016"

## take away the "campus_" in each id
sub.campus.ids$campus_id_2016 <- as.numeric(gsub("campus_", "", sub.campus.ids$campus_id_2016))
sub.campus.ids$campus_id_2017 <- as.numeric(gsub("campus_", "", sub.campus.ids$campus_id_2017))

## order by campus_id_2016
sub.campus.ids <- sub.campus.ids[order(sub.campus.ids$campus_id_2016),]

## take the unique combinations of 2016 and 2017 ids
sub.unique <- unique(sub.campus.ids[,c('campus_id_2016', 'campus_id_2017')])

## take out the NA in the 2017 and 2016 columns (for now)
sub.unique <- sub.unique[!is.na(sub.unique$campus_id_2017),]
sub.unique <- sub.unique[!is.na(sub.unique$campus_id_2016),]

## for each unique 2016 id, does the 2017 id exist elsewhere?
unique.2016 <- unique(sub.unique$campus_id_2016)
unique.2017 <- unique(sub.unique$campus_id_2017)
repeat.2016 <- NULL
repeat.2017 <- NULL
same.2016 <- NULL
same.2017 <- NULL
## look for 2016 schools that were put in a different campus grouping in 2017
for (i in 1:length(unique.2016)){
  print(i)
  if (length(which(sub.unique$campus_id_2016 == unique.2016[i])) > 1){
    repeat.2016 <- append(repeat.2016, unique.2016[i])
  } else{
    same.2016 <- append(same.2016, unique.2016[i])
  }
}
## look for 2017 schools that were added to an existing 2016 campus grouping
for (i in 1:length(unique.2017)){
  print(i)
  if (length(which(sub.unique$campus_id_2017 == unique.2017[i])) > 1){
    repeat.2017 <- append(repeat.2017, unique.2017[i])
  } else{
    same.2017 <- append(same.2017, unique.2017[i])
  }
}

## 1,264 (1,431 old) schools were split up in 2017
length(repeat.2016)
sub.2016 <- sub.campus.ids[which(sub.campus.ids$campus_id_2016 %in% repeat.2016),]
## 284 (308 old) schools were added to an existing 2016 campus grouping
length(repeat.2017)
sub.2017 <- sub.campus.ids[which(sub.campus.ids$campus_id_2017 %in% repeat.2017),]
sub.2017 <- sub.2017[order(sub.2017$campus_id_2017),]

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
## merge in whether the campus id was changed by DQT last year, merge on latest 2016 campus id
sub.2016 <- merge(sub.2016, combined.2016[,c('campus_id_updated', 'campus.change.2016')], by.x='campus_id_2016', by.y='campus_id_updated', all.x=T)
sub.2016 <- sub.2016[,c('school_nces_code', 'campus_id_2016', 'campus_id_2017', 'campus.change.2016')]
sub.2017 <- merge(sub.2017, combined.2016[,c('campus_id_updated', 'campus.change.2016')], by.x='campus_id_2016', by.y='campus_id_updated', all.x=T)
sub.2017 <- sub.2017[,c('school_nces_code', 'campus_id_2016', 'campus_id_2017', 'campus.change.2016')]

## merge in esh_district_id and locale
sub.2017 <- merge(sub.2017, schools.2016[,c('school_nces_code', 'district_esh_id', 'locale')], by='school_nces_code', all.x=T)
sub.2016 <- merge(sub.2016, schools.2016[,c('school_nces_code', 'district_esh_id', 'locale')], by='school_nces_code', all.x=T)

deluxe.schools.2016$combined.address <- paste(deluxe.schools.2016$address, deluxe.schools.2016$city,
                                              deluxe.schools.2016$postal_cd, deluxe.schools.2016$zip, sep=' ')

## merge in lat/long, name, and combined address in 2016 and 2017
sub.2016 <- merge(sub.2016, nces[,c('ncessch', 'latcode', 'longcode', 'sch_name', 'combined.addr', 'lea_type')],
                  by.x='school_nces_code', by.y='ncessch', all.x=T)
names(sub.2016)[names(sub.2016) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
names(sub.2016)[names(sub.2016) %in% c('sch_name', 'combined.addr')] <- c('name.2017', 'combined.addr.2017')
sub.2016 <- merge(sub.2016, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude', 'name', 'combined.address')],
                  by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(sub.2016)[names(sub.2016) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
names(sub.2016)[names(sub.2016) %in% c('name', 'combined.address')] <- c('name.2016', 'combined.addr.2016')
## round 2017 to match 2016
sub.2016$lat.2017 <- round(sub.2016$lat.2017, digits=4)
sub.2016$long.2017 <- round(sub.2016$long.2017, digits=4)
## create indicator if lat or long is different
sub.2016$lat.diff <- abs(sub.2016$lat.2016 - sub.2016$lat.2017)
sub.2016$long.diff <- abs(sub.2016$long.2016 - sub.2016$long.2017)
sub.2016$lat.diff.b <- ifelse(sub.2016$lat.diff > 0.00015, TRUE, FALSE)
sub.2016$long.diff.b <- ifelse(sub.2016$long.diff > 0.00015, TRUE, FALSE)
sub.2016$lat.or.long.diff <- ifelse(sub.2016$lat.diff.b == TRUE | sub.2016$long.diff.b == TRUE, TRUE, FALSE)
## create indicator if combined address is different
sub.2016$combined.address.diff <- ifelse(sub.2016$combined.addr.2016 != sub.2016$combined.addr.2017, TRUE, FALSE)
## order columns differently
sub.2016 <- sub.2016[,c("school_nces_code", "district_esh_id", "lea_type", "campus_id_2016", "campus_id_2017", "campus.change.2016",
                        "locale", "lat.2016", "long.2016", "lat.2017", "long.2017", "lat.diff", "long.diff", "lat.or.long.diff",
                        "name.2016", "name.2017", "combined.addr.2016", "combined.addr.2017", "combined.address.diff")]

## look into lat/long difference in 2017
## merge in lat/long in 2016 and 2017
sub.2017 <- merge(sub.2017, nces[,c('ncessch', 'latcode', 'longcode', 'sch_name', 'combined.addr',"lea_type")],
                  by.x='school_nces_code', by.y='ncessch', all.x=T)
names(sub.2017)[names(sub.2017) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
names(sub.2017)[names(sub.2017) %in% c('sch_name', 'combined.addr')] <- c('name.2017', 'combined.addr.2017')
sub.2017 <- merge(sub.2017, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude', 'name', 'combined.address')],
                  by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(sub.2017)[names(sub.2017) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
names(sub.2017)[names(sub.2017) %in% c('name', 'combined.address')] <- c('name.2016', 'combined.addr.2016')
## round 2017 to match 2016
sub.2017$lat.2017 <- round(sub.2017$lat.2017, digits=4)
sub.2017$long.2017 <- round(sub.2017$long.2017, digits=4)
## create indicator if lat or long is different
sub.2017$lat.diff <- abs(sub.2017$lat.2016 - sub.2017$lat.2017)
sub.2017$long.diff <- abs(sub.2017$long.2016 - sub.2017$long.2017)
sub.2017$lat.diff.b <- ifelse(sub.2017$lat.diff > 0.00015, TRUE, FALSE)
sub.2017$long.diff.b <- ifelse(sub.2017$long.diff > 0.00015, TRUE, FALSE)
sub.2017$lat.or.long.diff <- ifelse(sub.2017$lat.diff.b == TRUE | sub.2017$long.diff.b == TRUE, TRUE, FALSE)
## create indicator if combined address is different
sub.2017$combined.address.diff <- ifelse(sub.2017$combined.addr.2016 != sub.2017$combined.addr.2017, TRUE, FALSE)
## order columns differently
sub.2017 <- sub.2017[,c("school_nces_code", "district_esh_id", "lea_type", "campus_id_2016", "campus_id_2017", "campus.change.2016",
                        "locale", "lat.2016", "long.2016", "lat.2017", "long.2017", "lat.diff", "long.diff", "lat.or.long.diff",
                        "name.2016", "name.2017", "combined.addr.2016", "combined.addr.2017", "combined.address.diff")]

##*********************************************************************************************************
## create subsets based on the following situations:

## 1) any DQT manually applied campusing edits persist into 2017
##    A) subset of schools with different lat/longs from 2016 to 2017 for a manual review
##    (this will help us ensure these campuses should always persist / simply feel more confident)

## 2016
sub.dqt.edited.2016 <- sub.2016[sub.2016$campus.change.2016 == TRUE,]
lat.long.diff.2016 <- unique(sub.dqt.edited.2016$campus_id_2016[which(sub.dqt.edited.2016$lat.or.long.diff == TRUE)])
sub.dqt.edited.2016.lat.long.diff <- sub.dqt.edited.2016[sub.dqt.edited.2016$campus_id_2016 %in% lat.long.diff.2016,]

## 2017
sub.dqt.edited.2017 <- sub.2017[which(sub.2017$campus.change.2016 == TRUE),]
sub.dqt.edited.2017.lat.long.diff <- sub.dqt.edited.2017[which(sub.dqt.edited.2017$lat.or.long.diff == TRUE),]

##    B) subset of schools with same lat/longs from 2016 to 2017 but were changed by DQT last year
##    (this will help us ensure these campuses should always persist / simply feel more confident)

## 2016
sub.dqt.edited.2016.no.change <- sub.dqt.edited.2016[which(!sub.dqt.edited.2016$campus_id_2016 %in% lat.long.diff.2016),]
length(unique(sub.dqt.edited.2016.no.change$campus_id_2016))

## 2017
sub.dqt.edited.2017.no.change <- sub.dqt.edited.2017[which(!sub.dqt.edited.2017$campus_id_2017 %in% sub.dqt.edited.2017.lat.long.diff$campus_id_2017),]
length(unique(sub.dqt.edited.2017.no.change$campus_id_2017))

## 2) 2017 campusing is accepted if address or lat/long changed from 2016 to 2017 for schools
##    (note: this applies to de-coupled schools as well as newly merged schools)
ids.2017.different.2016 <- unique(sub.2016$campus_id_2016[which(sub.2016$campus.change.2016 == FALSE & sub.2016$lat.or.long.diff == TRUE)])
sub.2016.2017.different <- sub.2016[which(sub.2016$campus_id_2016 %in% ids.2017.different.2016),]

ids.2017.different.2017 <- unique(sub.2017$campus_id_2017[which(sub.2017$campus.change.2016 == FALSE & sub.2017$lat.or.long.diff == TRUE)])
sub.2017.2017.different <- sub.2017[which(sub.2017$campus_id_2017 %in% ids.2017.different.2017),]

## 3) when 2017 campusing is different than 2016 campusing, but neither the address or lat/longs changed...still to be determined 
##    to be reviewed by DQT
## find campus_ids that have different lat/long or combined address and then take the opposite to grab all of the campuses
## that don't have a changed lat/long or combined.address
ids.2017.different.2016.2 <- unique(sub.2016$campus_id_2016[which(sub.2016$lat.or.long.diff == TRUE)])
sub.2016.2017.same <- sub.2016[which(!sub.2016$campus_id_2016 %in% ids.2017.different.2016.2),]
## order by campus id 2016
sub.2016.2017.same <- sub.2016.2017.same[order(sub.2016.2017.same$campus_id_2016),]
## take out where the campus was changed by DQT
sub.2016.2017.same <- sub.2016.2017.same[which(sub.2016.2017.same$campus.change.2016 == FALSE),]
## for the sames, loop through and calculate the distance between the schools in the campus and see if the distance is > 0.10
## collect unique campus ids
unique.2016.campus.ids <- unique(sub.2016.2017.same$campus_id_2016)
dta.2016 <- NULL
system.time({
  for (i in 1:length(unique.2016.campus.ids)){
    print(i)
    dta.2016.sub <- sub.2016.2017.same[sub.2016.2017.same$campus_id_2016 == unique.2016.campus.ids[i],]
    dta.2016 <- rbind(dta.2016, as.data.table(t(combnPrim(dta.2016.sub$school_nces_code, 2))))
  }
})
names(dta.2016) <- c("school1", "school2")
dta.2016 <- merge(dta.2016, sub.2016.2017.same[,c('school_nces_code', 'campus_id_2016', 'campus_id_2017',
                                                  'lat.2016', 'long.2016', 'lat.2017', 'long.2017', 'combined.addr.2016', 'combined.addr.2017')],
                  by.x='school1', by.y='school_nces_code', all.x=T)
dta.2016 <- merge(dta.2016, sub.2016.2017.same[,c('school_nces_code', 'campus_id_2016', 'campus_id_2017',
                                                  'lat.2016', 'long.2016', 'lat.2017', 'long.2017', 'combined.addr.2016', 'combined.addr.2017')],
                  by.x='school2', by.y='school_nces_code', all.x=T)
names(dta.2016) <- c("school2", "school1", 'campus.id.2016.1', "campus.id.2017.1",
                     "lat.2016.1", "long.2016.1", "lat.2017.1", "long.2017.1", "combined.addr.2016.1", "combined.addr.2017.1",
                     'campus.id.2016.2', "campus.id.2017.2",
                     "lat.2016.2", "long.2016.2", "lat.2017.2", "long.2017.2", "combined.addr.2016.2", "combined.addr.2017.2")
## calculate distances
dta.2016[,distance_hav_2016 := distHaversine(matrix(c(dta.2016$long.2016.1, dta.2016$lat.2016.1), ncol = 2),
                                             matrix(c(dta.2016$long.2016.2, dta.2016$lat.2016.2), ncol = 2))]
## convert to miles
dta.2016$distance_hav_2016 <- dta.2016$distance_hav_2016 * 0.000621371

dta.2016[,distance_hav_2017 := distHaversine(matrix(c(dta.2016$long.2017.1, dta.2016$lat.2017.1), ncol = 2),
                                             matrix(c(dta.2016$long.2017.2, dta.2016$lat.2017.2), ncol = 2))]
## convert to miles
dta.2016$distance_hav_2017 <- dta.2016$distance_hav_2017 * 0.000621371
## subset to the difference greater than 0.10 in either year, since that means they weren't campused in one of the years
dta.2016.sub <- dta.2016[which(dta.2016$distance_hav_2016 > 0.10 | dta.2016$distance_hav_2017 > 0.10),]
## how many 2016 campus ids are in the dta subset
length(unique.2016.campus.ids)
length(unique(dta.2016.sub$campus.id.2016.1, dta.2016.sub$campus.id.2016.2))

ids.2017.different.2017.2 <- unique(sub.2017$campus_id_2017[which(sub.2017$lat.or.long.diff == TRUE)])
sub.2017.2017.same <- sub.2017[which(!sub.2017$campus_id_2017 %in% ids.2017.different.2017.2),]
## order by campus id 2016
sub.2017.2017.same <- sub.2017.2017.same[order(sub.2017.2017.same$campus_id_2017),]
## take out where the campus was changed by DQT
sub.2017.2017.same <- sub.2017.2017.same[which(sub.2017.2017.same$campus.change.2016 == FALSE),]


## merge in unrounded lat/long
sub.2016.2017.same <- merge(sub.2016.2017.same, nces[,c('ncessch', 'latcode', 'longcode')], by.x='school_nces_code', by.y='ncessch', all.x=T)

## look at only cases where the lat/long AND combined address is the same
ids.diff.all.2016 <- sub.2016.2017.same$campus_id_2016[which(sub.2016.2017.same$combined.address.diff == TRUE)]
sub.same.all <- sub.2016.2017.same[which(!sub.2016.2017.same$campus_id_2016 %in% ids.diff.all.2016),]

## for each unique 2016 campus, diagnose the problem:
unique.2016.campuses <- unique(sub.2016.2017.same$campus_id_2016[which(!sub.2016.2017.same$campus_id_2016 %in% ids.diff.all.2016)])
## create a dataset to collect the problem types:
## 7 = charter district
## or calculated distance
dta.problem <- data.frame(campus_id_2016=unique.2016.campuses, problem_id=NA)
for (i in 1:length(unique.2016.campuses)){
  sub <- sub.same.all[which(sub.same.all$campus_id_2016 == unique.2016.campuses[i]),]
  if (length(unique(sub$district_esh_id)) > 1){
    dta.problem$problem_id[i] <- 7
  } else {
    if (nrow(sub) == 2){
      dta.problem$problem_id[i] <- distHaversine(c(sub$longcode[1], sub$latcode[1]),
                                                 c(sub$longcode[2], sub$latcode[2])) * 0.000621371
    }
  }
}
## SUMMARY: 69/84 cases have to do with charter schools having their own district id and therefore not matching in the new campus algorithm
##          the other 15/84 cases have to do with the 2017 lat/long being 5 decimal points instead of 4 last year and thus the distance is just slightly over .10 miles

## now look at the cases where the string address is different but the lat/long is the same
sub.same.ll.diff.addr <- sub.2016.2017.same[which(sub.2016.2017.same$campus_id_2016 %in% ids.diff.all.2016),]
## is there a levenstein distance we can use for the string address to match these?
## for each unique 2016 campus, calculate the levenstein distance:
unique.2016.campuses <- unique(sub.2016.2017.same$campus_id_2016[which(sub.2016.2017.same$campus_id_2016 %in% ids.diff.all.2016)])

dta.same.ll.2016.combos <- NULL
for (i in 1:length(unique.2016.campuses)){
  print(i)
  dta.sub <- sub.same.ll.diff.addr[sub.same.ll.diff.addr$campus_id_2016 == unique.2016.campuses[i],]
  dta.same.ll.2016.combos <- rbind(dta.same.ll.2016.combos, as.data.table(t(combnPrim(dta.sub$school_nces_code, 2))))
}
names(dta.same.ll.2016.combos) <- c("school1", "school2")
## merge in combined address string
dta.same.ll.2016.combos <- merge(dta.same.ll.2016.combos, sub.same.ll.diff.addr[,c('school_nces_code', 'combined.addr.2017')],
                                 by.x='school1', by.y='school_nces_code', all.x=T)
names(dta.same.ll.2016.combos)[names(dta.same.ll.2016.combos) == "combined.addr.2017"] <- "combined.addr.2017.1"
dta.same.ll.2016.combos <- merge(dta.same.ll.2016.combos, sub.same.ll.diff.addr[,c('school_nces_code', 'combined.addr.2017')],
                                 by.x='school2', by.y='school_nces_code', all.x=T)
names(dta.same.ll.2016.combos)[names(dta.same.ll.2016.combos) == "combined.addr.2017"] <- "combined.addr.2017.2"
## take out addresses that are NA for either school
dta.same.ll.2016.combos <- dta.same.ll.2016.combos[!is.na(dta.same.ll.2016.combos$combined.addr.2017.1) & !is.na(dta.same.ll.2016.combos$combined.addr.2017.2),]
## create an indicator if the string addresses are not the same
dta.same.ll.2016.combos$same.string <- ifelse(dta.same.ll.2016.combos$combined.addr.2017.1 == dta.same.ll.2016.combos$combined.addr.2017.2, TRUE, FALSE)
## calculate levenstein distance
dta.same.ll.2016.combos$lev.distance <- adist(dta.same.ll.2016.combos$combined.addr.2017.1, dta.same.ll.2016.combos$combined.addr.2017.2)
dta.same.ll.2016.combos$lev.distance.partial <- adist(dta.same.ll.2016.combos$combined.addr.2017.1, dta.same.ll.2016.combos$combined.addr.2017.2, partial=TRUE)

##*********************************************************************************************************
## write out data

write.csv(sub.2016, "data/processed/2016_schools_reassigned.csv", row.names=F)
write.csv(sub.2017, "data/processed/2017_schools_added_to_existing_campus.csv", row.names=F)
write.csv(sub.dqt.edited.2016.lat.long.diff, "data/qa/DQT_edited_2017_info_different_2016.csv", row.names=F)
write.csv(sub.dqt.edited.2017.lat.long.diff, "data/qa/DQT_edited_2017_info_different_2017.csv", row.names=F)
write.csv(sub.dqt.edited.2016.no.change, "data/qa/DQT_edited_2017_same_info_2016.csv", row.names=F)
write.csv(sub.dqt.edited.2017.no.change, "data/qa/DQT_edited_2017_same_info_2017.csv", row.names=F)
write.csv(sub.2016.2017.same, "data/qa/different_campusing_same_lat_long_2016.csv", row.names=F)
write.csv(sub.2017.2017.same, "data/qa/different_campusing_same_lat_long_2017.csv", row.names=F)
