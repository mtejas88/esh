## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

line.items.2016 <- read.csv("data/raw/line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
frn.meta.data.2016 <- read.csv("data/raw/frn_meta_data_2016.csv", as.is=T, header=T, stringsAsFactors=F)
clean.line.items.2016 <- read.csv("data/raw/clean_line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
sp.2016 <- read.csv("data/raw/service_providers_2016.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## CLEAN DATA

line.items.2016$frn <- as.character(line.items.2016$frn)
frn.meta.data.2016$frn <- as.character(frn.meta.data.2016$frn)
line.items.2016$frn_complete <- as.character(line.items.2016$frn_complete)
clean.line.items.2016$frn_complete <- as.character(clean.line.items.2016$frn_complete)

mg_raw <- merge(line.items.2016, frn.meta.data.2016[,c('frn', names(frn.meta.data.2016)[!names(frn.meta.data.2016) %in% names(line.items.2016)])],
                by='frn', all.x=T)

## subset to line items that are broadband
full_mg <- mg_raw[which(mg_raw$broadband == "t"),]
## subset line.items to those that are fit for analysis
clean.line.items.2016 <- clean.line.items.2016[which(clean.line.items.2016$exclude == "f"),]
## append "clean" to each variable name in line.items
names(clean.line.items.2016) <- paste("cl", names(clean.line.items.2016), sep='_')

## merge in raw with clean connect category
## merge on id
full_mg <- merge(mg_raw, clean.line.items.2016[,c('cl_id', 'cl_connect_category')], by.x='id', by.y='cl_id', all.x=T)
## merge on frn_complete
full_mg.2 <- merge(full_mg, clean.line.items.2016[,c('cl_frn_complete', 'cl_connect_category')], by.x='frn_complete', by.y='cl_frn_complete', all.x=T)


