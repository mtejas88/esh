## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

nces <- read.csv("data/raw/nces_2014-15.csv", as.is=T, header=T, stringsAsFactors=F)
usac <- read.csv("data/raw/usac_2016.csv", as.is=T, header=T, stringsAsFactors=F)
schools <- read.csv("data/raw/schools.csv", as.is=T, header=T, stringsAsFactors=F)
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)
salesforce_account <- read.csv("data/raw/salesforce_account.csv", as.is=T, header=T, stringsAsFactors=F)
salesforce_facilities <- read.csv("data/raw/salesforce_facilities.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## format the column names (take out capitalization)
names(nces) <- tolower(names(nces))

## USAC
## merge in BENs to DD
usac <- merge(usac, bens, by.x='entity_number', by.y='ben', all.x=T)
## subset to the usac ids that were matched with a ben
#usac <- usac[!is.na(usac$entity_type.y),]
## subset to schools only in schools_demog
usac.schools <- usac[which(usac$entity_id %in% schools$school_esh_id),]
## merge in district_esh_id from schools table
usac.schools <- merge(usac.schools, schools[,c('school_esh_id', 'district_esh_id',
                                               'school_nces_code', 'nces_cd',
                                               'district_include_in_universe_of_districts')],
              by.x='entity_id', by.y='school_esh_id', all.x=T)
## subset to schools only in districts we care about
usac.schools <- usac.schools[which(usac.schools$district_include_in_universe_of_districts == TRUE),]
schools <- schools[which(schools$district_include_in_universe_of_districts == TRUE),]

## subset to schools with missing entity_id
#sub <- schools[which(!schools$school_esh_id %in% usac$entity_id),]
## merge in BENs with schools
#sub <- merge(sub, bens, by.x="school_esh_id", by.y="entity_id", all.x=T)
## to see how many unique BENs are missing
#table(is.na(sub$ben))
#length(unique(sub$district_esh_id))
## state trends?
#table(sub$postal_cd)
## unique bens still missing
## 556, 1,013
## take a sample to send to Lacy/Lindie/Meghan
#sub.missing.sample <- sub[sample(1:nrow(sub), 50),]
#write.csv(sub.missing.sample, "data/interim/sample_50_missing_usac_school_entity_id.csv", row.names=F)

## NCES
## subset to the same schools in the USAC dataset
nces.schools <- nces[which(nces$ncessch %in% usac.schools$school_nces_code),]

## there appear to be duplicates in the USAC data, look into why
duplicated.usac <- usac.schools[which(usac.schools$school_nces_code %in%
                                        usac.schools$school_nces_code[which(duplicated(usac.schools$school_nces_code))]),]
duplicated.usac <- duplicated.usac[order(duplicated.usac$school_nces_code),]
## take out the duplicates in the usac data for now (will rbind back later)
usac.schools <- usac.schools[which(!usac.schools$school_nces_code %in%
                                     usac.schools$school_nces_code[which(duplicated(usac.schools$school_nces_code))]),]
## there is a field called "last_updated_date" so grab the most recent one for each duplicated school
duplicated.usac$last_updated_date_revised <- as.Date(duplicated.usac$last_updated_date, format="%m/%d/%Y")
duplicated.usac$school_nces_code <- as.character(duplicated.usac$school_nces_code)
collect.duplicates <- unique(duplicated.usac$school_nces_code)
## order by nces code and date
duplicated.usac <- duplicated.usac[order(duplicated.usac$school_nces_code, duplicated.usac$last_updated_date_revised, decreasing=T),]
## for each unique nces school idea, grab the latest entry
## (match will take the first instance of the duplicate, since we ordered by date, that's what we want it to take)
dta.temp <- duplicated.usac[match(unique(duplicated.usac$school_nces_code), duplicated.usac$school_nces_code),]
## remove new variable we added for the rbind to work
dta.temp$last_updated_date_revised <- NULL
## rbind back in duplicated schools
usac.schools <- rbind(usac.schools, dta.temp)

## USAC
## aggregate the number of students by district
usac.student.count <- aggregate(usac.schools$number_of_full_time_students, by=list(usac.schools$nces_cd), FUN=sum, na.rm=T)
names(usac.student.count) <- c('nces_cd', 'total_num_students_usac')
## merge in state for each district
district.states <- unique(usac.schools[,c('nces_cd', 'physical_state')])
usac.student.count <- merge(usac.student.count, district.states, by='nces_cd', all=T)
## create list of verified states
verified.states <- c('AL', 'AR', 'DE', 'FL', 'GA', 'HI', 'IN', 'KS', 'KY',
                      'ME', 'MA', 'MI', 'MO', 'MT', 'NV', 'NC', 'OK', 'SC',
                      'TN', 'UT', 'VT', 'WA', 'WV', 'WI', 'WY')
## create indicator based on verified states
usac.student.count$verified <- ifelse(usac.student.count$physical_state %in% verified.states, TRUE, FALSE)

## NCES
## aggregate the number of students by district
nces.student.count <- aggregate(nces.schools$total, by=list(nces.schools$leaid), FUN=sum, na.rm=T)
names(nces.student.count) <- c('leaid', 'total_num_students_nces')
## merge in state for each district
district.states <- unique(nces.schools[,c('leaid', 'stabr')])
nces.student.count <- merge(nces.student.count, district.states, by='leaid', all=T)
names(nces.student.count)[names(nces.student.count) == "leaid"] <- "nces_cd"

## combine the datasets
combined <- merge(usac.student.count, nces.student.count, by='nces_cd', all=T)
## take out the districts that don't match up (in regards to state)
combined$state.match <- ifelse(combined$physical_state == combined$stabr, TRUE, FALSE)
table(combined$state.match)
combined <- combined[combined$state.match == TRUE,]
## calculate difference in districts
combined$diff <- abs(combined$total_num_students_usac - combined$total_num_students_nces)

## take out FL outlier
#combined <- combined[combined$nces_cd != 1201290,]
#combined <- combined[combined$diff <= 100000,]

##**************************************************************************************************************************************************
## TEST

## initialize list
store.t <- NULL
mean.true <- NULL
mean.false <- NULL
iters <- 5000
set.seed(533)

## use t-test to see if there is a statistically significant difference between verified districts and none verified districts
for (i in 1:iters){
  sub <- combined[sample(1:nrow(combined), 2000, replace=F),]
  store.t <- append(store.t, t.test(diff~verified, data=sub)$p.value)
  mean.true <- append(mean.true, mean(sub$diff[sub$verified == TRUE], na.rm=T))
  mean.false <- append(mean.false, mean(sub$diff[sub$verified == FALSE], na.rm=T))
}

hist(store.t)
mean(store.t)

mean(mean.true)
median(mean.true)

mean(mean.false)
median(mean.false)

##**************************************************************************************************************************************************
## write out the interim datasets

