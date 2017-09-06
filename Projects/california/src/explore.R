## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

dd <- read.csv("data/raw/dd.csv", as.is=T, header=T, stringsAsFactors=F)
ca_reported <- read.csv("external_data/pubschls.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## CLEAN UP CA REPORTED DISTRICTS

table(ca_reported$StatusType)

#keeping only active schools
ca_reported <- filter(ca_reported, StatusType == 'Active')

ca_reported_districts <- select(ca_reported, NCESDist, District)
ca_reported_districts <- unique(ca_reported_districts)

##**************************************************************************************************************************************************
## MERGING TOGETHER DD AND CA REPORTED

combined <- merge(x = dd, y = ca_reported_districts, by.x = 'nces_cd', by.y = 'NCESDist', all = T)

not.in.dd <- filter(combined, is.na(esh_id))
not.in.ca.reported <- filter(combined, is.na(District))

## EXPORTING not in ca reported

write.csv(not.in.dd, 'not_in_dd.csv', row.names = F)
write.csv(not.in.ca.reported, 'not_in_ca_reported.csv', row.names = F)
