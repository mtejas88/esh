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

##**************************************************************************************************************************************************
## Follow-up 6/6 - need data at blockgroup and census tract level

#create columns for block group and census tract
districts_schools_blocks_final$blockgroup <- substr(districts_schools_blocks_final$blockcode, 1, 12)
districts_schools_blocks_final$censustract <- substr(districts_schools_blocks_final$blockcode, 1, 11)
#read in data
  #blockgroup
dta.477s_fiber_bg = read.csv("../data/raw/form_477s_fiber_bg.csv", colClasses=c("blockgroup"="character"), as.is=T, header=T, stringsAsFactors=F)
names(dta.477s_fiber_bg) = c("blockgroup","nproviders_bg")
  #censustract
dta.477s_fiber_ct = read.csv("../data/raw/form_477s_fiber_ct.csv", colClasses=c("censustract"="character"), as.is=T, header=T, stringsAsFactors=F)
names(dta.477s_fiber_ct) = c("censustract","nproviders_ct")

##### blockgroup
## merge in service provider info for fiber-only providers
districts_schools_blocks_bg <- merge(districts_schools_blocks_final, dta.477s_fiber_bg, by='blockgroup', all.x=T)
str(districts_schools_blocks_bg)
## for nproviders, replace nulls with 0
districts_schools_blocks_bg$nproviders_bg[is.na(districts_schools_blocks_bg$nproviders_bg)] <- 0
summary(districts_schools_blocks_bg)

##### censustract
## merge in service provider info for fiber-only providers
districts_schools_blocks_ct <- merge(districts_schools_blocks_final, dta.477s_fiber_ct, by='censustract', all.x=T)
str(districts_schools_blocks_ct)
## for nproviders, replace nulls with 0
districts_schools_blocks_ct$nproviders_ct[is.na(districts_schools_blocks_ct$nproviders_ct)] <- 0
summary(districts_schools_blocks_ct)

### merge so it's easier to summarize together
districts_schools_blocks_bg_ct=merge(districts_schools_blocks_bg,districts_schools_blocks_ct[,c("esh_id","nproviders_ct")], by="esh_id", all.x=T)
summary(districts_schools_blocks_bg_ct)
#remove duplicate rows
print(length(districts_schools_blocks_bg_ct$esh_id))
print(dim(unique(districts_schools_blocks_bg_ct[,c("esh_id","district_esh_id")])))
districts_schools_blocks_bg_ct=districts_schools_blocks_bg_ct[!duplicated(districts_schools_blocks_bg_ct),]
##**************************************************************************************************************************************************
## write out the interim datasets
write.csv(districts_schools_blocks_bg_ct, "../data/interim/districts_schools_blocks_final_bg_ct.csv", row.names=F)
