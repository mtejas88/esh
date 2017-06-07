## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## read in data

dd.2016 <- read.csv("../data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)
censusblocks <- read.csv("../data/raw/esh_ids_with_blockcodes.csv", as.is=T, header=T, stringsAsFactors=F)
#this takes 5-10 mins
dta.477s <- read.csv("../data/raw/form_477s.csv", as.is=T, header=T, stringsAsFactors=F)

str(dd.2016)
str(dta.477s)
str(censusblocks)

##**************************************************************************************************************************************************
## subset, format and merge data

## census block data formatting
## format the column names (take out capitalization and spaces)
names(censusblocks) <- tolower(names(censusblocks))
## merge in census blocks to DD
dd.2016_blocks <- merge(dd.2016, censusblocks[,c('esh_id', 'blockcode')], by='esh_id', all.x=T)
## check if there are any districts without a block
nrow(subset(dd.2016_blocks,dd.2016_blocks$blockcode=='None'))
## merge in service provider info
dd.2016_blocks_final <- merge(dd.2016_blocks, dta.477s, by='blockcode', all.x=T)
str(dd.2016_blocks_final)
## filter form777 table to only include our districts
dta.477s_final <- dta.477s %>% semi_join(dd.2016_blocks, by = c("blockcode" = "blockcode"))

##**************************************************************************************************************************************************
## write out the interim datasets
write.csv(dta.477s_final, "../data/interim/form_477s_final.csv", row.names=F)
write.csv(dd.2016_blocks_final, "../data/interim/dd_blocks_sp.csv", row.names=F)
