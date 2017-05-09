## =========================================================================
##
## CAMPUSING ALGORITHM: CHECKS & FORMATTING
## 1) Every school should only be assigned to 1 campus
##    also collect number of schools in each campus
## 2) Percentage of schools campused (>= 2 schools)
##
## =========================================================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##*********************************************************************************************************
## read in data

final.campus <- read.csv("data/processed/final_campuses_threshold_0.1_miles.csv", as.is=T, header=T, stringsAsFactors=F)
nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
schools.2016 <- read.csv("data/raw/2016_schools.csv", as.is=T, header=T, stringsAsFactors=F)
deluxe.schools.2016 <- read.csv("data/raw/2016_deluxe_schools.csv", as.is=T, header=T, stringsAsFactors=F)
original.2016 <- read.csv("data/old/final_campus_groupings_2016-08-31_school_level.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## format data

## correct ids using function
schools.2016$school_nces_code <- correct_ids(schools.2016$school_nces_code, district=0)
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)

## for the schools.2016, categorize the campus "ids" by leading string
schools.2016$campus_id_type <- ifelse(grepl("campus_group_", schools.2016$campus_id), 1,
                                ifelse(grepl("group_", schools.2016$campus_id), 2,
                                  ifelse(grepl("campus_", schools.2016$campus_id), 3, NA)))
table(schools.2016$campus_id_type)
## subset to the correct campus category
schools.2016 <- schools.2016[which(schools.2016$campus_id_type == 3),]

##*********************************************************************************************************
## Checks and Formatting Final Campuses at the School Level

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
schools.ids <- unique(as.character(nces$ncessch))
schools.ids.no.campus <- schools.ids[!schools.ids %in% master.schools.check]
final.campus.no.campus <- data.frame(campus.id = seq(nrow(final.campus)+1, nrow(final.campus)+length(schools.ids.no.campus)),
                                     schools = schools.ids.no.campus)
final.campus.no.campus$num.schools <- 1
## rbind with master
final.campus <- rbind(final.campus, final.campus.no.campus)

## create a version of the final dataset that matches each school to a campus id, on the school level
final.campus.sch.level <- data.frame(school_id=c(master.schools.check, schools.ids.no.campus),
                                     campus_id_num=rep(final.campus$campus.id, final.campus$num.schools))
## format the id how engineering wants
final.campus.sch.level$campus_id <- paste("campus_", final.campus.sch.level$campus_id_num, sep="")

## take out school_id column so we only have school_esh_id and campus_id
#final.campus.sch.level$school_id <- NULL
#final.campus.sch.level <- final.campus.sch.level[,c("school_esh_id", "campus_id")]

## 2) percentage of schools campused (>= 2 schools)
paste(round((length(master.schools.check) / nrow(nces))*100, 0), "%", sep="")
## percentage of schools campused (all)
paste(round((nrow(final.campus) / nrow(nces))*100, 0), "%", sep="")

##*********************************************************************************************************
## Compare with 2016 campusing (ideally retain the 2016 campus_id)

sub.campus.ids <- merge(schools.2016[,c('school_nces_code', 'campus_id')],
                        final.campus.sch.level[,c('school_id', 'campus_id')],
                        by.x='school_nces_code', by.y='school_id', all=T)
names(sub.campus.ids)[names(sub.campus.ids) == "campus_id.x"] <- "campus_id_2016"
names(sub.campus.ids)[names(sub.campus.ids) == "campus_id.y"] <- "campus_id_2017"

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

## 1,298 schools were split up in 2017
length(repeat.2016)
sub.2016 <- sub.campus.ids[which(sub.campus.ids$campus_id_2016 %in% repeat.2016),]
## 317 schools were added to an existing 2016 campus grouping
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

## merge in district ids into final campus groupings
## use NCES district id instead of esh_id since merging in the esh info would only be 2016 info
final.campus.sch.level <- merge(final.campus.sch.level, nces[,c('ncessch', 'leaid')], by.x='school_id', by.y='ncessch', all.x=T)
final.campus.sch.level$counter <- 1
## aggregate at the district level
campus.district.level <- aggregate(final.campus.sch.level$counter, by=list(final.campus.sch.level$leaid), FUN=sum, na.rm=T)
names(campus.district.level) <- c('district_nces_id', 'num_campuses_2017')

## take out columns in school level
final.campus.sch.level$campus_id_num <- NULL
final.campus.sch.level$leaid <- NULL
final.campus.sch.level$counter <- NULL

## merge in esh_district_id and locale
sub.2017 <- merge(sub.2017, schools.2016[,c('school_nces_code', 'district_esh_id', 'locale')], by='school_nces_code', all.x=T)
sub.2016 <- merge(sub.2016, schools.2016[,c('school_nces_code', 'district_esh_id', 'locale')], by='school_nces_code', all.x=T)

## look into lat/long difference in 2016
## merge in lat/long in 2016 and 2017
sub.2016 <- merge(sub.2016, nces[,c('ncessch', 'latcode', 'longcode')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(sub.2016)[names(sub.2016) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
sub.2016 <- merge(sub.2016, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude')], by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(sub.2016)[names(sub.2016) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
## round 2017 to match 2016
sub.2016$lat.2017 <- round(sub.2016$lat.2017, digits=4)
sub.2016$long.2017 <- round(sub.2016$long.2017, digits=4)
## create indicator if lat or long is different
sub.2016$lat.diff <- ifelse(sub.2016$lat.2016 != sub.2016$lat.2017, TRUE, FALSE)
sub.2016$long.diff <- ifelse(sub.2016$long.2016 != sub.2016$long.2017, TRUE, FALSE)
sub.2016$lat.or.long.diff <- ifelse(sub.2016$lat.diff == TRUE | sub.2016$long.diff == TRUE, TRUE, FALSE)
sub.2016$lat.2017 <- NULL
sub.2016$long.2017 <- NULL
sub.2016$lat.2016 <- NULL
sub.2016$long.2016 <- NULL
sub.2016$lat.diff <- NULL
sub.2016$long.diff <- NULL

## look into lat/long difference in 2017
## merge in lat/long in 2016 and 2017
sub.2017 <- merge(sub.2017, nces[,c('ncessch', 'latcode', 'longcode')], by.x='school_nces_code', by.y='ncessch', all.x=T)
names(sub.2017)[names(sub.2017) %in% c('latcode', 'longcode')] <- c('lat.2017', 'long.2017')
sub.2017 <- merge(sub.2017, deluxe.schools.2016[,c('school_nces_cd', 'latitude', 'longitude')], by.x='school_nces_code', by.y='school_nces_cd', all.x=T)
names(sub.2017)[names(sub.2017) %in% c('latitude', 'longitude')] <- c('lat.2016', 'long.2016')
## round 2017 to match 2016
sub.2017$lat.2017 <- round(sub.2017$lat.2017, digits=4)
sub.2017$long.2017 <- round(sub.2017$long.2017, digits=4)
## create indicator if lat or long is different
sub.2017$lat.diff <- ifelse(sub.2017$lat.2016 != sub.2017$lat.2017, TRUE, FALSE)
sub.2017$long.diff <- ifelse(sub.2017$long.2016 != sub.2017$long.2017, TRUE, FALSE)
sub.2017$lat.or.long.diff <- ifelse(sub.2017$lat.diff == TRUE | sub.2017$long.diff == TRUE, TRUE, FALSE)
sub.2017$lat.2017 <- NULL
sub.2017$long.2017 <- NULL
sub.2017$lat.2016 <- NULL
sub.2017$long.2016 <- NULL
sub.2017$lat.diff <- NULL
sub.2017$long.diff <- NULL

##*********************************************************************************************************
## write out final campus groupings at school level

write.csv(final.campus.sch.level, "data/processed/final_campuses_school_level.csv", row.names=F)
write.csv(campus.district.level, "data/processed/final_campuses_district_level.csv", row.names=F)
write.csv(sub.2016, "data/processed/2016_schools_reassigned.csv", row.names=F)
write.csv(sub.2017, "data/processed/2017_schools_added_to_existing_campus.csv", row.names=F)

