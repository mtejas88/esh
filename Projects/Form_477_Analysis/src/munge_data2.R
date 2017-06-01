## ===============================================
##
## MUNGE DATA: Subset and Clean data for follow-up
##
## ===============================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## read in data

dd.2016 <- read.csv("../data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)
districts_schools <- read.csv("../data/raw/districts_schools.csv", as.is=T, header=T, stringsAsFactors=F)
censusblocks <- read.csv("../data/raw/esh_ids_with_blockcodes.csv", as.is=T, header=T, stringsAsFactors=F)
dta.477s_fiber <- read.csv("../data/raw/form_477s_fiber.csv", colClasses=c("blockcode"="character"), as.is=T, header=T, stringsAsFactors=F)

str(dd.2016)
str(districts_schools)
str(dta.477s_fiber)
str(censusblocks)

##**************************************************************************************************************************************************
## subset, format and merge data

## census block data formatting
## format the column names (take out capitalization and spaces)
names(censusblocks) <- tolower(names(censusblocks))
## merge in census blocks to schools AND districts
districts_schools_blocks <- merge(districts_schools, censusblocks[,c('esh_id', 'blockcode')], by='esh_id', all.x=T)
## filter only for esh_ids with a census block
districts_schools_blocks=subset(districts_schools_blocks,districts_schools_blocks$blockcode!='None')
## filter only for districts in our universe
districts_schools_blocks=subset(districts_schools_blocks,district_esh_id %in% dd.2016$esh_id)
## merge in service provider info for fiber-only providers
districts_schools_blocks_final <- merge(districts_schools_blocks, dta.477s_fiber, by='blockcode', all.x=T)
str(districts_schools_blocks_final)
## for nproviders, replace nulls with 0
districts_schools_blocks_final$nproviders[is.na(districts_schools_blocks_final$nproviders)] <- 0
summary(districts_schools_blocks_final)
##**************************************************************************************************************************************************
## write out the interim datasets
write.csv(districts_schools_blocks_final, "../data/interim/districts_schools_blocks_final.csv", row.names=F)
