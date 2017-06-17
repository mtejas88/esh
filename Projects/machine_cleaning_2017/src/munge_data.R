## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(tidyr)

##**************************************************************************************************************************************************
## READ IN DATA

line.items.2016 <- read.csv("data/raw/line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
frn.meta.data.2016 <- read.csv("data/raw/frn_meta_data_2016.csv", as.is=T, header=T, stringsAsFactors=F)
clean.line.items.2016 <- read.csv("data/raw/clean_line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
sp.2016 <- read.csv("data/raw/service_providers_2016.csv", as.is=T, header=T, stringsAsFactors=F)

line.items.2017 <- read.csv("data/raw/line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
frn.meta.data.2017 <- read.csv("data/raw/frn_meta_data_2017.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## CLEAN DATA

line.items.2016$frn <- as.character(line.items.2016$frn)
frn.meta.data.2016$frn <- as.character(frn.meta.data.2016$frn)
line.items.2016$frn_complete <- as.character(line.items.2016$frn_complete)
clean.line.items.2016$frn_complete <- as.character(clean.line.items.2016$frn_complete)
line.items.2017$frn <- as.character(line.items.2017$frn)
frn.meta.data.2017$frn <- as.character(frn.meta.data.2017$frn)

## combine metadata with line item data
mg_raw <- merge(line.items.2016, frn.meta.data.2016[,c('frn', names(frn.meta.data.2016)[!names(frn.meta.data.2016) %in% names(line.items.2016)])],
                by='frn', all.x=T)
## subset to line items that are broadband
mg_raw <- mg_raw[which(mg_raw$broadband == "t"),]

## combine metadata with line item data
line.items.2017 <- line.items.2017 %>% separate(frn, c("new_frn", "line_id"), "\\.")
frn.meta.data.2017 <- frn.meta.data.2017 %>% separate(frn, c("new_frn", "line_id"), "\\.")
mg_raw_2017 <- merge(line.items.2017, frn.meta.data.2017[,c('new_frn', names(frn.meta.data.2017)[!names(frn.meta.data.2017) %in% names(line.items.2017)])],
                by='new_frn', all.x=T)
## subset to line items that are broadband
mg_raw_2017 <- mg_raw_2017[which(mg_raw_2017$broadband == "t"),]

## collect all clean frn_completes that are duplicated (means they were de-bundled when cleaned)
duplicate.frns <- clean.line.items.2016$frn_complete[duplicated(clean.line.items.2016$frn_complete)]
duplicate.frns <- unique(duplicate.frns)
## subset to the clean line items that are not duplicated
clean.line.items.2016 <- clean.line.items.2016[which(!clean.line.items.2016$frn_complete %in% duplicate.frns),]
## append "clean" to each variable name in line.items
names(clean.line.items.2016) <- paste("cl", names(clean.line.items.2016), sep='_')

## merge in raw with clean connect category
full_mg <- merge(mg_raw, clean.line.items.2016[,c('cl_frn_complete', 'cl_connect_category', 'cl_exclude')], by.x='frn_complete', by.y='cl_frn_complete', all.x=T)
## subset to only the line items that were cleaned
full_mg <- full_mg[which(full_mg$cl_exclude == "f"),]

##**************************************************************************************************************************************************
## COMPARE COLUMNS THAT WERE CHANGED

## take out the "cl_"
names(clean.line.items.2016) <- gsub("cl_", "", names(clean.line.items.2016))

## define that columns that overlap
overlap.cols <- names(clean.line.items.2016)[names(clean.line.items.2016) %in% names(line.items.2016)]

names(line.items.2016) <- paste("raw_", names(line.items.2016), sep='')
## subset to line items that are broadband
line.items.2016 <- line.items.2016[which(line.items.2016$raw_broadband == "t"),]
## merge
raw_clean_mg <- merge(line.items.2016[,paste("raw_", overlap.cols, sep='')], clean.line.items.2016[,overlap.cols],
                      by.x="raw_frn_complete", by.y="frn_complete", all.x=T)

## subset line.items to those that are fit for analysis
raw_clean_mg <- raw_clean_mg[which(raw_clean_mg$exclude == "f"),]

raw_clean_mg$num_lines <- as.numeric(raw_clean_mg$num_lines)
raw_clean_mg$raw_num_lines <- as.numeric(raw_clean_mg$raw_num_lines)

## for each column, record the percentage that's different
overlap.cols <- overlap.cols[overlap.cols != "frn_complete"]
dta.store <- data.frame(matrix(NA, nrow=length(overlap.cols), ncol=3))
names(dta.store) <- c('column', 'percent_changed', 'percent_changed_raw')
for (i in 1:length(overlap.cols)){
  print(overlap.cols[i])
  dta.store$column[i] <- overlap.cols[i]
  raw_clean_mg$temp.col <- ifelse(raw_clean_mg[,paste('raw_', overlap.cols[i], sep='')] != raw_clean_mg[,overlap.cols[i]], 1, 0)
  dta.store$percent_changed[i] <- round((sum(raw_clean_mg$temp.col, na.rm=T) / nrow(raw_clean_mg[!is.na(raw_clean_mg$temp.col),]))*100, 0)
  dta.store$percent_changed_raw[i] <- round((sum(raw_clean_mg$temp.col, na.rm=T) / nrow(raw_clean_mg))*100, 0)
}
## sort by largest difference
dta.store <- dta.store[order(dta.store$percent_changed, decreasing=T),]

## for each column, record the percentage that's different
## take into account NA's
dta.store.with.nas <- data.frame(matrix(NA, nrow=length(overlap.cols), ncol=2))
names(dta.store.with.nas) <- c('column', 'percent_changed')
for (i in 1:length(overlap.cols)){
  print(overlap.cols[i])
  dta.store.with.nas$column[i] <- overlap.cols[i]
  ## change NA values to "NA VALUE"
  raw_clean_mg[,paste('raw_', overlap.cols[i], sep='')] <- ifelse(is.na(raw_clean_mg[,paste('raw_', overlap.cols[i], sep='')]), "NA_VALUE",
                                                                  raw_clean_mg[,paste('raw_', overlap.cols[i], sep='')])
  raw_clean_mg[,overlap.cols[i]] <- ifelse(is.na(raw_clean_mg[,overlap.cols[i]]), "NA_VALUE", raw_clean_mg[,overlap.cols[i]])
  raw_clean_mg$temp.col <- ifelse(raw_clean_mg[,paste('raw_', overlap.cols[i], sep='')] != raw_clean_mg[,overlap.cols[i]], 1, 0)
  dta.store.with.nas$percent_changed[i] <- round((sum(raw_clean_mg$temp.col, na.rm=T) / nrow(raw_clean_mg))*100, 0)
}
## sort by largest difference
dta.store.with.nas <- dta.store.with.nas[order(dta.store.with.nas$percent_changed, decreasing=T),]


## investigate number of lines difference
## is number of lines the same data type?
#class(raw_clean_mg$num_lines)
#class(raw_clean_mg$raw_num_lines)
#raw_clean_mg$diff.num.lines <- ifelse(raw_clean_mg$num_lines != raw_clean_mg$raw_num_lines, TRUE, FALSE)
#table(raw_clean_mg$diff.num.lines)
#sub.diff.num.lines <- raw_clean_mg[which(raw_clean_mg$diff.num.lines == TRUE),]
## for number of lines, pristine might be 1
#table(raw_clean_mg$raw_num_lines == "1")

##**************************************************************************************************************************************************
## FORMAT OPEN FLAGS AND TAGS

## Flags
sub <- full_mg[,c('frn_complete', 'open_flag_labels')]
sub$open_flag_labels.2 <- gsub("\\{", "", sub$open_flag_labels)
sub$open_flag_labels.3 <- gsub("\\}", "", sub$open_flag_labels.2)
## break out the flags into different columns
sub2 <- sub %>% separate(open_flag_labels.3, c("flag1", "flag2", "flag3", "flag4"), ",")
unique.flags <- unique(c(sub2$flag1, sub2$flag2, sub2$flag3, sub2$flag4))
unique.flags <- unique.flags[!unique.flags %in% c(NA, "")]
unique.flags

## Tags -- No Tags in the dataset
#sub <- full_mg[,c('frn_complete', 'open_tag_labels')]
#sub$open_tag_labels.2 <- gsub("\\{", "", sub$open_tag_labels)
#sub$open_tag_labels.3 <- gsub("\\}", "", sub$open_tag_labels.2)
## break out the tags into different columns
#sub2 <- sub %>% separate(open_tag_labels.3, c("tag1", "tag2", "tag3", "tag4"), ",")
#unique.tags <- unique(c(sub2$tag1, sub2$tag2, sub2$tag3, sub2$tag4))
#unique.tags <- unique.tags[!unique.tags %in% c(NA, "")]
#unique.tags

