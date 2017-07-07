## =========================================================================
##
## FUZZY MATCHING ALGORITHM
##
## =========================================================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

##*********************************************************************************************************
## read in data

nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
fuzzy.bens <- read.csv("data/interim/bens_for_fuzzy_matching.csv", as.is=T, header=T, stringsAsFactors=F)
nces.to.entities <- read.csv("data/raw/2017_nces_to_entities.csv", as.is=T, header=T, stringsAsFactors=F)
qa <- read.csv("data/QA/fuzzy_matches_to_be_reviewed.csv", as.is=T, header=T, stringsAsFactors=F)

##*********************************************************************************************************
## define function

## function to disaggregate and regularize school names
regularize.names <- function(names){
  
  ## clean all leading and trailing whitespaces
  names <- gsub("^\\s+|\\s+$", "",  names)
  
  ## sub . for no space (unlike punctuation command later)
  names <- gsub("\\.", "", names)
  
  ## sub & for "AND" (unlike punctuation command later)
  names <- gsub("\\&", "AND", names)
  
  ## change "EL" to "ELEMENTARY"
  ## subs for "ELEMENTARY": "EL", "ELEM.", "ELEM", "ELE", etc.
  ## so if we sub " EL", we should be able to catch most of the versions
  names <- gsub("\\sEL\\w+ *", " ELEMENTARY ", names)
  names <- gsub("\\b[EL]{2}\\b", "ELEMENTARY ", names)
  ## clean all leading and trailing whitespaces
  names <- gsub("^\\s+|\\s+$", "",  names)
  
  ## change "SCH" & "SCHL" to "SCHOOL"
  names <- gsub("\\b[SCH]{3}\\b", "SCHOOL", names)
  names <- gsub("\\b[SCHL]{4}\\b", "SCHOOL", names)
  ## clean all leading and trailing whitespaces
  names <- gsub("^\\s+|\\s+$", "",  names)
  
  ## change "CTR" to "CENTER"
  names <- gsub("\\b[CTR]{3}\\b", "CENTER", names)
  
  ## change "HS" & "H S" to "HIGH SCHOOL"
  names <- gsub("\\b[HS]{2}\\b", " HIGH SCHOOL", names)
  names <- gsub(" H S", " HIGH SCHOOL", names)
  
  ## change "MS" & "M S" to "MIDDLE SCHOOL"
  names <- gsub("\\b[MS]{2}\\b", " MIDDLE SCHOOL", names)
  names <- gsub(" M S", " MIDDLE SCHOOL", names)
  
  ## change "ES" & "E S" to "ELEMENTARY SCHOOL"
  names <- gsub("\\b[ES]{2}\\b", " ELEMENTARY SCHOOL", names)
  names <- gsub(" E S", " ELEMENTARY SCHOOL", names)
  
  ## change "JR" to "JUNIOR"
  names <- gsub("\\b[JR]{2}\\b", "JUNIOR", names)
  
  ## change "SR" to "SENIOR"
  names <- gsub("\\b[SR]{2}\\b", "SENIOR", names)
  
  ## change "ALT" to "ALTERNATIVE"
  names <- gsub("\\b[ALT]{3}\\b", "ALTERNATIVE", names)
  
  ## change "AVE" to "AVENUE"
  names <- gsub("\\b[AVE]{3}\\b", "AVENUE", names)
  
  ## change "PROG" to "PROGRAM"
  names <- gsub("\\b[PROG]{4}\\b", "PROGRAM", names)
  
  ## change "LRN" to "LEARNING"
  names <- gsub("\\b[LRN]{3}\\b", "LEARNING", names)
  
  ## change "STUD" to "STUDIES"
  names <- gsub("\\b[STUD]{4}\\b", "STUDIES", names)
  
  ## change "PRI" to "PRIMARY"
  names <- gsub("\\b[PRI]{3}\\b", "PRIMARY", names)
  
  ## change "CO" to "COUNTY"
  names <- gsub("\\b[CO]{2}\\b", "COUNTY", names)
  
  ## add in "SCHOOL" behind "MIDDLE", "ELEMENTARY", "HIGH", "PRIMARY"
  names <- gsub(" ELEMENTARY$", " ELEMENTARY SCHOOL", names)
  names <- gsub(" MIDDLE$", " MIDDLE SCHOOL", names)
  names <- gsub(" HIGH$", " HIGH SCHOOL", names)
  names <- gsub(" PRIMARY$", " PRIMARY SCHOOL", names)
  
  ## remove all punctutation
  names <- gsub("\\W", " ", names)
  
  ## clean all leading and trailing whitespaces
  names <- gsub("^\\s+|\\s+$", "",  names)
  
  ## make all entries upper case
  names <- toupper(names)
  
  return(names)
}

## function to disaggregate and regularize school address
regularize.addresses <- function(address){
  
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## sub . for no space (unlike punctuation command later)
  address <- gsub("\\.", "", address)
  
  ## sub & for "AND" (unlike punctuation command later)
  address <- gsub("\\&", "AND", address)
  
  ## change "ST" to "STREET"
  address <- gsub("\\b[ST]{2}\\b", "STREET ", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "BLVD" to "BOULEVARD"
  address <- gsub("\\b[BLVD]{4}\\b", "BOULEVARD", address)
  
  ## change "RD" to "ROAD"
  address <- gsub("\\b[RD]{2}\\b", "ROAD", address)
  
  ## change "LN" to "LANE"
  address <- gsub("\\b[LN]{2}\\b", "LANE", address)
  
  ## change "DR" to "DRIVE"
  address <- gsub("\\b[DR]{2}\\b", "DRIVE", address)
  
  ## change "HWY" to "HIGHWAY"
  address <- gsub("\\b[HWY]{3}\\b", "HIGHWAY", address)
  
  ## change "CT" to "COURT"
  address <- gsub("\\b[CT]{2}\\b", "COURT", address)
  
  ## change "PL" to "PLACE"
  address <- gsub("\\b[PL]{2}\\b", "PLACE", address)
  
  ## change "CIR" to "CIRCLE"
  address <- gsub("\\b[CIR]{3}\\b", "CIRCLE", address)
  
  ## change "AVE" to "AVENUE"
  address <- gsub("\\b[AVE]{3}\\b", "AVENUE", address)
  
  ## change "AV" to "AVENUE"
  address <- gsub("\\b[AV]{2}\\b", "AVENUE", address)
  
  ## change "SW" to "SOUTHWEST"
  address <- gsub("\\b[SW]{2}\\b", "SOUTHWEST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "SE" to "SOUTHEAST"
  address <- gsub("\\b[SE]{2}\\b", "SOUTHEAST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "NW" to "NORTHWEST"
  address <- gsub("\\b[NW]{2}\\b", "NORTHWEST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "NE" to "NORTHEAST"
  address <- gsub("\\b[NE]{2}\\b", "NORTHEAST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "S" to "SOUTH"
  address <- gsub("\\b[S]{1}\\b", "SOUTH", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "N" to "NORTH"
  address <- gsub("\\b[N]{1}\\b", "NORTH", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "W" to "WEST"
  address <- gsub("\\b[W]{1}\\b", "WEST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## change "E" to "EAST"
  address <- gsub("\\b[E]{1}\\b", "EAST", address)
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## remove all punctutation
  address <- gsub("\\W", " ", address)
  
  ## clean all leading and trailing whitespaces
  address <- gsub("^\\s+|\\s+$", "",  address)
  
  ## make all entries upper case
  address <- toupper(address)
  
  return(address)
}

##*********************************************************************************************************

## correct ids using function
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)
nces.to.entities$nces_code <- correct_ids(nces.to.entities$nces_code, district=0)

## merge in esh_ids for nces_codes
nces <- merge(nces, nces.to.entities[,c('nces_code', 'entity_id')], by.x='ncessch', by.y='nces_code', all.x=T)

## regularize names
nces$sch_name_regularized <- regularize.names(nces$sch_name)
fuzzy.bens$name_regularized <- regularize.names(fuzzy.bens$name)

## regularize addresses
nces$address_regularized <- regularize.addresses(nces$street_name)
fuzzy.bens$address_regularized <- regularize.addresses(fuzzy.bens$street_name)


## for each school needed to be matched, calculate the levenstein distance between it and the other schools, subsetting to same zip, city, state

## STRICT MATCH ON 0 SCORE
matches.0 <- data.frame(matrix(NA, nrow=0, ncol=8))
names(matches.0) <- c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized_usac', 'scores.name', 'entity_id')
for (i in 1:nrow(fuzzy.bens)){
  print(i)
  #if (!is.na(fuzzy.bens$applicant_esh_id[i])){
  #  sub <- nces[which(nces$district_esh_id == fuzzy.bens$applicant_esh_id[i]),]
  #} else{
    sub <- nces[which(nces$city.state.zip == fuzzy.bens$city.state.zip[i]),]
  #}
  ## run levenstein distance on each school name
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens$ben[i]
    sub$raw_name_usac <- fuzzy.bens$name[i]
    sub$name_regularized_usac <- fuzzy.bens$name_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized_usac', 'entity_id')]
    sub$scores.name <- adist(sub$sch_name_regularized, fuzzy.bens$name_regularized[i]) / nchar(fuzzy.bens$name_regularized[i])
    ## grab the matches only if the distance is 0 for now
    sub.0 <- sub[which(sub$scores.name == 0),]
    if (nrow(sub.0) > 0){
      matches.0 <- rbind(matches.0, sub.0)
    }
  }
}

## MATCH ON VARIABLE SCORE
var <- 0.10
matches.var <- data.frame(matrix(NA, nrow=0, ncol=8))
names(matches.var) <- c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized_usac', 'scores.name', 'entity_id')
for (i in 1:nrow(fuzzy.bens)){
  print(i)
  sub <- nces[which(nces$city.state.zip == fuzzy.bens$city.state.zip[i]),]
  ## run levenstein distance on each school name
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens$ben[i]
    sub$raw_name_usac <- fuzzy.bens$name[i]
    sub$name_regularized_usac <- fuzzy.bens$name_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized_usac', 'entity_id')]
    sub$scores.name <- adist(sub$sch_name_regularized, fuzzy.bens$name_regularized[i]) / nchar(fuzzy.bens$name_regularized[i])
    ## grab the matches only if the distance is 0 for now
    sub.var <- sub[which(sub$scores.name <= var & sub$scores.name != 0),]
    if (nrow(sub.var) > 0){
      matches.var <- rbind(matches.var, sub.var)
    }
  }
}

## MATCH ON STREET NUMBER AND ADDRESS
var.name <- 0.10
var.address <- 0.30
## remove the matches that have already been confirmed
fuzzy.bens.sub <- fuzzy.bens[which(!fuzzy.bens$ben %in% matches.0$ben),]
matches.street.addr <- data.frame(matrix(NA, nrow=0, ncol=13))
names(matches.street.addr) <- c('ncessch', 'sch_name_regularized', 'street_number', 'street_name', 'address_regularized',
                                'ben', 'name_regularized_usac', 'street_number_usac', 'street_name_usac', 'address_regularized_usac',
                                'scores.address', 'scores.name', 'entity_id')
no.matches <- NULL
for (i in 1:nrow(fuzzy.bens.sub)){
  print(i)
  sub <- nces[which(nces$city.state.zip == fuzzy.bens.sub$city.state.zip[i]),]
  sub <- sub[which(sub$street_number == fuzzy.bens.sub$street_number[i]),]
  ## run levenstein distance on each street name only after forcing the street number to be the same
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens.sub$ben[i]
    sub$name_regularized_usac <- fuzzy.bens.sub$name_regularized[i]
    sub$street_number_usac <- fuzzy.bens.sub$street_number[i]
    sub$street_name_usac <- fuzzy.bens.sub$street_name[i]
    sub$address_regularized_usac <- fuzzy.bens.sub$address_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name_regularized', 'street_number', 'street_name', 'address_regularized',
                  'ben', 'name_regularized_usac', 'street_number_usac', 'street_name_usac', 'address_regularized_usac', 'entity_id')]
    sub$scores.address <- adist(sub$address_regularized, fuzzy.bens.sub$address_regularized[i]) / nchar(fuzzy.bens.sub$address_regularized[i])
    sub$scores.name <- adist(sub$sch_name_regularized, fuzzy.bens.sub$name_regularized[i]) / nchar(fuzzy.bens.sub$name_regularized[i])
    
    ## grab the matches only if the name distance is <= 0.10 AND the address distance is <= 0.30
    sub.var <- sub[which(sub$scores.address <= var.address & sub$scores.name <= var.name),]
    if (nrow(sub.var) > 0){
      matches.street.addr <- rbind(matches.street.addr, sub.var)
    }
  } else{
    no.matches <- append(no.matches, fuzzy.bens.sub$ben[i])
  }
}
length(no.matches)
no.matches <- fuzzy.bens[which(fuzzy.bens$ben %in% no.matches),]

## combine the matches with 0 scores
confirmed.matches <- matches.0[,c('ncessch', 'sch_name_regularized', 'ben', 'name_regularized_usac', 'scores.name', 'entity_id')]
confirmed.matches <- rbind(confirmed.matches, matches.street.addr[,c('ncessch', 'sch_name_regularized', 'ben', 'name_regularized_usac', 'scores.name', 'entity_id')])

## MATCH ON STREET NUMBER AND ADDRESS
## pick the smallest match score for both name and address
## remove the matches that have already been confirmed
fuzzy.bens.sub <- fuzzy.bens[which(!fuzzy.bens$ben %in% matches.0$ben),]
fuzzy.bens.sub <- fuzzy.bens.sub[which(!fuzzy.bens.sub$ben %in% matches.street.addr$ben),]
fuzzy.bens.sub <- fuzzy.bens.sub[which(!fuzzy.bens.sub$ben %in% no.matches),]
matches.street.addr2 <- data.frame(matrix(NA, nrow=0, ncol=13))
names(matches.street.addr2) <- c('ncessch', 'sch_name_regularized', 'street_number', 'street_name', 'address_regularized',
                                'ben', 'name_regularized_usac', 'street_number_usac', 'street_name_usac', 'address_regularized_usac',
                                'scores.address', 'scores.name', 'entity_id')
for (i in 1:nrow(fuzzy.bens.sub)){
  print(i)
  sub <- nces[which(nces$city.state.zip == fuzzy.bens.sub$city.state.zip[i]),]
  sub <- sub[which(sub$street_number == fuzzy.bens.sub$street_number[i]),]
  ## run levenstein distance on each street name only after forcing the street number to be the same
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens.sub$ben[i]
    sub$name_regularized_usac <- fuzzy.bens.sub$name_regularized[i]
    sub$street_number_usac <- fuzzy.bens.sub$street_number[i]
    sub$street_name_usac <- fuzzy.bens.sub$street_name[i]
    sub$address_regularized_usac <- fuzzy.bens.sub$address_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name_regularized', 'street_number', 'street_name', 'address_regularized',
                  'ben', 'name_regularized_usac', 'street_number_usac', 'street_name_usac', 'address_regularized_usac', 'entity_id')]
    sub$scores.address <- adist(sub$address_regularized, fuzzy.bens.sub$address_regularized[i]) / nchar(fuzzy.bens.sub$address_regularized[i])
    sub$scores.name <- adist(sub$sch_name_regularized, fuzzy.bens.sub$name_regularized[i]) / nchar(fuzzy.bens.sub$name_regularized[i])
    ## grab the lowest scored match
    matches.street.addr2 <- rbind(matches.street.addr2, sub[which(sub$scores.address == min(sub$scores.address) & sub$scores.name == min(sub$scores.name)),])
  }
}
##**************************************************************************************************************************************************
## merge in QA results

## correct names of columns
names(qa) <- tolower(names(qa))
## correct ids
qa$ncessch <- correct_ids(qa$ncessch, district=0)
## merge
matches.street.addr2 <- merge(matches.street.addr2, qa[,c('ncessch', 'correct.ben')], by='ncessch', all.x=T)
matches.street.addr2$ben <- matches.street.addr2$correct.ben

## create a subset for updates
eng.update <- rbind(matches.street.addr2[,c('entity_id', 'ncessch', 'ben')], confirmed.matches[,c('entity_id', 'ncessch', 'ben')])
## take out the NA's
eng.update <- eng.update[which(!is.na(eng.update$ben)),]

##**************************************************************************************************************************************************
## write out the datasets

write.csv(no.matches, "data/processed/no_matches.csv", row.names=F)
write.csv(matches.street.addr2, "data/processed/fuzzy_matches_to_be_reviewed.csv", row.names=F)
write.csv(confirmed.matches, "data/processed/recommended_matches.csv", row.names=F)

write.csv(eng.update, "data/processed/eng_mass_update_fuzzy_bens.csv", row.names=F)
