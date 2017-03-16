## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

frn.2016 <- read.csv("data/raw/frn_line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
line.items.2016 <- read.csv("data/raw/line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

## append "clean" to each variable name in line.items
names(line.items.2016)[names(line.items.2016) != 'id'] <- paste(names(line.items.2016)[names(line.items.2016) != 'id'], "clean", sep='.')

## first, merge together the datasets
dta <- merge(frn.2016, line.items.2016, by='id', all.x=T)

## for the first attempt at ML, subset the dataset to the dirty columns plus the clean version of connect_type
dta.connect.type <- dta[,c("connect_type.clean", names(dta)[!names(dta) %in% names(dta)[grepl(".clean", names(dta))]])]

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(dta, "data/interim/combined_raw_and_clean_line_items_2016.csv", row.names=F)
write.csv(dta.connect.type, "data/interim/ml_connect_type_2016.csv", row.names=F)
