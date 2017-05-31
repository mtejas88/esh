## =========================================================================
##
## FUZZY MATCHING ALGORITHM
##
## =========================================================================

## Clearing memory
rm(list=ls())

## source functions
source("../../General_Resources/common_functions/correct_nces_ids.R")

## load packages (if not already in the environment)
packages.to.install <- c("geosphere", "caTools", "dplyr", "gRbase", "dtplyr", "data.table")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
#library(geosphere)
#library(caTools)
#library(dplyr)
#library(gRbase) ## for combn function
#library(dtplyr) 
#library(data.table) ## for the as.data.table function

##*********************************************************************************************************
## read in data

nces <- read.csv("data/interim/nces_schools_subset.csv", as.is=T, header=T, stringsAsFactors=F)
fuzzy.bens <- read.csv("data/interim/bens_for_fuzzy_matching.csv", as.is=T, header=T, stringsAsFactors=F)

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

##*********************************************************************************************************

## correct ids using function
nces$leaid <- correct_ids(nces$leaid, district=1)
nces$ncessch <- correct_ids(nces$ncessch, district=0)

## regularize names
nces$sch_name_regularized <- regularize.names(nces$sch_name)
fuzzy.bens$name_regularized <- regularize.names(fuzzy.bens$name)

## create an indicator involving city, state, zip
fuzzy.bens$org_zipcode <- ifelse(nchar(fuzzy.bens$org_zipcode) == 4, paste('0', fuzzy.bens$org_zipcode, sep=""), fuzzy.bens$org_zipcode)
fuzzy.bens$org_city <- gsub("\xd5", "", fuzzy.bens$org_city)
fuzzy.bens$city.state.zip <- paste(toupper(fuzzy.bens$org_city), toupper(fuzzy.bens$org_state), fuzzy.bens$org_zipcode, sep=".")

nces$lzip <- ifelse(nchar(nces$lzip) == 4, paste('0', nces$lzip, sep=""), nces$lzip)
nces$city.state.zip <- paste(toupper(nces$lcity), toupper(nces$lstate), nces$lzip, sep=".")

## for each school needed to be matched, calculate the levenstein distance between it and the other schools, subsetting to same zip, city, state

## STRICT MATCH ON 0 SCORE
matches.0 <- data.frame(matrix(NA, nrow=0, ncol=7))
names(matches.0) <- c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized', 'scores.name')
for (i in 1:nrow(fuzzy.bens)){
  print(i)
  sub <- nces[which(nces$city.state.zip == fuzzy.bens$city.state.zip[i]),]
  ## run levenstein distance on each school name
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens$ben[i]
    sub$raw_name_usac <- fuzzy.bens$name[i]
    sub$name_regularized <- fuzzy.bens$name_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized')]
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
matches.var <- data.frame(matrix(NA, nrow=0, ncol=7))
names(matches.var) <- c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized', 'scores.name')
for (i in 1:nrow(fuzzy.bens)){
  print(i)
  sub <- nces[which(nces$city.state.zip == fuzzy.bens$city.state.zip[i]),]
  ## run levenstein distance on each school name
  if (nrow(sub) > 0){
    sub$ben <- fuzzy.bens$ben[i]
    sub$raw_name_usac <- fuzzy.bens$name[i]
    sub$name_regularized <- fuzzy.bens$name_regularized[i]
    sub <- sub[,c('ncessch', 'sch_name', 'sch_name_regularized', 'ben', 'raw_name_usac', 'name_regularized')]
    sub$scores.name <- adist(sub$sch_name_regularized, fuzzy.bens$name_regularized[i]) / nchar(fuzzy.bens$name_regularized[i])
    ## grab the matches only if the distance is 0 for now
    sub.var <- sub[which(sub$scores.name <= var & sub$scores.name != 0),]
    if (nrow(sub.var) > 0){
      matches.var <- rbind(matches.var, sub.var)
    }
  }
}



