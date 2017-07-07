## =========================================================================
##
## CAMPUSING ALGORITHM: CHECKS & FINAL FORMATTING
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
esh_ids_2017 <- read.csv("data/raw/2017_nces_to_entities.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## format data

## correct ids using function
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)
esh_ids_2017$nces_code <- correct_ids(esh_ids_2017$nces_code, district=0)

## also format district nces id to match esh_ids_2017
nces$leaid <- paste(nces$leaid, "00000", sep="")

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
final.campus.sch.level$campus_id_2017 <- paste("campus_", final.campus.sch.level$campus_id_num, sep="")
## merge in school_esh_id
final.campus.sch.level <- merge(final.campus.sch.level, esh_ids_2017[,c('nces_code', 'entity_id')], by.x="school_id", by.y="nces_code", all.x=T)
## take out school_id column so we only have school_esh_id and campus_id
names(final.campus.sch.level)[names(final.campus.sch.level) == "entity_id"] <- "school_esh_id"
final.campus.sch.level.publish <- final.campus.sch.level[,c("school_esh_id", "campus_id_2017")]

## merge in district ids into final campus groupings
final.campus.sch.level <- merge(final.campus.sch.level, nces[,c('ncessch', 'leaid')], by.x='school_id', by.y='ncessch', all.x=T)
final.campus.sch.level <- merge(final.campus.sch.level, esh_ids_2017[,c('nces_code', 'entity_id')], by.x='leaid', by.y='nces_code', all.x=T)
final.campus.sch.level$counter <- 1
## aggregate at the district level
campus.district.level <- aggregate(final.campus.sch.level$counter, by=list(final.campus.sch.level$entity_id), FUN=sum, na.rm=T)
names(campus.district.level) <- c('district_esh_id', 'num_campuses_2017')

## 2) percentage of schools campused (>= 2 schools)
paste(round((length(master.schools.check) / nrow(nces))*100, 0), "%", sep="")
## percentage of schools campused (all)
paste(round((nrow(final.campus) / nrow(nces))*100, 0), "%", sep="")

##*********************************************************************************************************
## write out data

write.csv(final.campus.sch.level, "data/processed/final_campuses_school_level.csv", row.names=F)
write.csv(final.campus.sch.level.publish, "data/processed/final_campuses_school_level_for_engineering.csv", row.names=F)
write.csv(campus.district.level, "data/processed/final_campuses_district_level.csv", row.names=F)
