## =========================================================================
##
## CAMPUSING ALGORITHM: #1
## GOAL: Calculate distance between all combinations of schools within a district
## Uses NCES latitude and longitude data to calculate distance between schools
##
## Written by Adrianna Boghozian (AJB), based off of previous work by Carson Forter (CF)
## (old scripts by CF located in /src/old/)
##
## Time Warning: will take ~ 25 min to run the entire script
##
## =========================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("geosphere", "caTools", "ggmap", "dplyr", "gRbase")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(geosphere)
library(caTools)
library(ggmap)
library(dplyr)
library(gRbase) ## for combn function

### the following dependencies may be necessary, install as follows:
#source("http://bioconductor.org/biocLite.R")
#biocLite("graph")
#biocLite("BiocGenerics")
#biocLite("RBGL")

## set date (for file naming)
date <- Sys.Date()

##*********************************************************************************************************
## READ IN FILES

## NCES raw school data
### Select all schools
#schools_query <- "
#select * 
#from schools
#"
#schools <- dbGetQuery(con, schools_query)
## takes ~ 22 secs to load
schools <- read.csv("../data/sc131a.csv", as.is=T, header=T)
## use "fread" since sc131a.csv is a large file
#schools <- fread("../data/sc131a.csv")
## Variables of interest:
## NCESSCH_ADJ == school_id, unique
## LEAID == district_id
## LATCOD == Latitude
## LONCOD == Longitude
## get the school ids that we care about, since NCES data contains learning programs, juvenile detention centers, etc.
real.schools <- read.csv("../data/fy2016_schools_demog_2016-08-30.csv", as.is=T, header=T)
## grab the district ids and school ids that we care about
#district.ids <- unique(real.schools$nces_cd)
schools.ids <- unique(real.schools$school_nces_code)
## subset NCES raw data to the districts and schools we care about
#schools <- schools[schools$LEAID %in% district.ids,]
schools <- schools[schools$NCESSCH %in% schools.ids,]

##*********************************************************************************************************
## Calculate distances between schools

## NOTE: There is an error with Excel.
## If you open the exported file from Mode in Excel,
## Excel will change the unique NCESSCH id to an exponential number and round off the last digits,
## thus the number is not unique anymore. To get around this, we've created an adjusted id that concatenates
## the state abbreviation with the school id, which lets Excel recognize the id properly as a character.
length(unique(schools$NCESSCH_ADJ)) == length(unique(schools$NCESSCH))
#schools$NCESSCH <- as.character(schools$NCESSCH)
all_districts <- unique(schools$LEAID)

### FIND ALL POSSIBLE COMBINATIONS OF SCHOOLS WITHIN EACH DISTRICT
## subset to districts with more than 1 school
districts.dta <- data.frame(table(schools$LEAID))
districts.sub <- districts.dta$Var1[districts.dta$Freq > 2]
dta <- NULL
## append all combinations of school pairings within a district (where a district has 3 or more schools)
## takes ~ 16-18 min to run the loop
system.time({
  for (i in 1:length(districts.sub)){
    print(i)
    dta.sub <- schools[schools$LEAID == districts.sub[i],]
    dta <- rbind(dta, as.data.table(t(combnPrim(dta.sub$NCESSCH_ADJ, 2))))
  }
})
names(dta) <- c("school1", "school2")
## merge in district and lat/long information for each school
dta <- merge(dta, schools[,c("NCESSCH_ADJ", "LEAID", "LATCOD", "LONCOD")], by.x="school1", by.y="NCESSCH_ADJ", all.x=T)
dta <- merge(dta, schools[,c("NCESSCH_ADJ", "LEAID", "LATCOD", "LONCOD")], by.x="school2", by.y="NCESSCH_ADJ", all.x=T)
names(dta) <- c("school1", "school2", "district1", "lat1", "long1", "district2", "lat2", "long2")

## append all combinations of school pairings within a district (where a district has 2 schools)
## this is split up to speed up computer processing time
dta.sub <- schools[schools$LEAID %in% districts.dta$Var1[districts.dta$Freq == 2],]
dta.2 <- NULL
## takes ~ 5 sec to run
system.time({
  dta.2 <- rbind(dta.2, as.data.table(t(combnPrim(dta.sub$NCESSCH_ADJ, 2))))
})
names(dta.2) <- c("school1", "school2")
## merge in district and lat/long information for each school
dta.2 <- merge(dta.2, schools[,c("NCESSCH_ADJ", "LEAID", "LATCOD", "LONCOD")], by.x="school1", by.y="NCESSCH_ADJ", all.x=T)
dta.2 <- merge(dta.2, schools[,c("NCESSCH_ADJ", "LEAID", "LATCOD", "LONCOD")], by.x="school2", by.y="NCESSCH_ADJ", all.x=T)
names(dta.2) <- c("school1", "school2", "district1", "lat1", "long1", "district2", "lat2", "long2")
## only keep the combinations where the districts are the same
dta.2 <- dta.2[dta.2$district1 == dta.2$district2,]
## append to the overall dataset
dta <- rbind(dta, dta.2)

## calculate distances within all combinations of schools
## takes ~ 2 sec to run
system.time({
  dta[,distance_hav := distHaversine(matrix(c(dta$long1, dta$lat1), ncol = 2),
                                     matrix(c(dta$long2, dta$lat2), ncol = 2))]
  ## convert to miles
  dta$distance_hav <- dta$distance_hav * 0.000621371
})

## merge in combined address field
schools$combined.addr <- paste(schools$LSTREE, schools$LCITY, schools$LSTATE, schools$LZIP, sep=' ')
dta <- merge(dta, schools[,c('NCESSCH_ADJ', 'combined.addr')], by.x='school1', by.y='NCESSCH_ADJ', all.x=T)
names(dta)[names(dta) == 'combined.addr'] <- 'combined.addr1'
dta <- merge(dta, schools[,c('NCESSCH_ADJ', 'combined.addr')], by.x='school2', by.y='NCESSCH_ADJ', all.x=T)
names(dta)[names(dta) == 'combined.addr'] <- 'combined.addr2'

## take out the schools that don't have lat/long info
dta <- dta[dta$lat1 != 0 & dta$long1 != 0,]

## write out the file
write.csv(dta, paste("../data/all_distances_", date, ".csv", sep=""), row.names=F)
