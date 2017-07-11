## =============================================================
##
## 2017 IMPACT ANALYSIS: Investigate Impact of Predictions
##
## =============================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/machine_cleaning_2017/")

library(tidyr) ## for "separate" function

##**************************************************************************************************************************************************
## READ IN DATA

## Staging
stag.frns <- read.csv("data/raw/frn_meta_data_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.line.items <- read.csv("data/raw/line_items_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.flags <- read.csv("data/raw/flags_staging.csv", as.is=T, header=T, stringsAsFactors=F)

## Current 2017
cl.frns.2017 <- read.csv("data/raw/clean_frn_meta_data_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.line.items.2017 <- read.csv("data/raw/clean_line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.flags.2017 <- read.csv("data/raw/clean_flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.dd.2017 <- read.csv("data/raw/districts_deluxe_2017.csv", as.is=T, header=T, stringsAsFactors=F)

## ESH model predictions
predictions <- read.csv("data/interim/eng_subset_for_staging.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT & MERGE DATA

## format frn_complete and frn fields
stag.line.items$frn_complete <- as.character(stag.line.items$frn_complete)
stag.frns$frn <- as.character(stag.frns$frn)
cl.line.items.2017$frn_complete <- as.character(cl.line.items.2017$frn_complete)
cl.frns.2017$frn <- as.character(cl.frns.2017$frn)
predictions$frn_complete <- as.character(predictions$frn_complete)

## subset the predictions to the ones that had a change in predicted connect_category
predictions <- predictions[which(predictions$connect_category != predictions$pred_connect_category),]
## merge in the line items in staging that were updated (since only a subset of the predictions can be updated)
names(stag.line.items)[names(stag.line.items) == 'connect_category'] <- 'changed_connect_category'
predictions <- merge(predictions, stag.line.items[,c('id', 'changed_connect_category')], by='id', all.x=T)
predictions <- predictions[which(predictions$pred_connect_category == predictions$changed_connect_category),]

## define function to deal with flags data
process.flags <- function(flags){
  flags$open_flag_labels <- gsub("\\{", "", flags$open_flag_labels)
  flags$open_flag_labels <- gsub("\\}", "", flags$open_flag_labels)
  ## break out the flags into different columns
  flags <- suppressWarnings(flags %>% separate(open_flag_labels, c("flag1", "flag2", "flag3", "flag4"), ","))
  unique.flags <- unique(c(flags$flag1, flags$flag2, flags$flag3, flags$flag4))
  unique.flags <- unique.flags[unique.flags != "\"\""]
  unique.flags <- unique.flags[!is.na(unique.flags)]
  for (i in 1:length(unique.flags)){
    flags$sub <- ifelse(flags$flag1 == unique.flags[i] | flags$flag2 == unique.flags[i] | flags$flag3 == unique.flags[i] |
                          flags$flag4 == unique.flags[i], TRUE, FALSE)
    flags$sub <- ifelse(is.na(flags$sub), FALSE, flags$sub)
    names(flags)[names(flags) == 'sub'] <- unique.flags[i]
  }
  flags <- flags[,-c(3:6)]
  return(flags)
}

## format staging flags data
stag.flags <- process.flags(stag.flags)
names(stag.flags) <- paste("stag", names(stag.flags), sep="_")
## merge flags into predictions
predictions <- merge(predictions, stag.flags, by.x='id', by.y='stag_flaggable_id', all.x=T)
predictions$stag_num_open_flags[is.na(predictions$stag_num_open_flags)] <- 0
predictions[is.na(predictions)] <- FALSE

## format current flags data
cl.flags.2017 <- process.flags(cl.flags.2017)
names(cl.flags.2017) <- paste("current", names(cl.flags.2017), sep="_")
## merge flags into predictions
predictions <- merge(predictions, cl.flags.2017, by.x='id', by.y='current_flaggable_id', all.x=T)
predictions$current_num_open_flags[is.na(predictions$current_num_open_flags)] <- 0
predictions[is.na(predictions)] <- FALSE

## reorder the dataset
predictions <- predictions[,c('id', 'frn_complete', 'connect_type', 'function.',
                              'connect_category', 'pred_connect_category', 'changed_connect_category',
                              'Cable', 'DSL', 'Dark.Fiber', 'Fixed.Wireless', 'ISP.Only', 'Lit.Fiber',
                              'Not.Broadband', 'Other.Copper', 'Satellite.LTE', 'T.1',
                              'current_num_open_flags', 'stag_num_open_flags', 'current_product_bandwidth', 'stag_product_bandwidth', 
                              'current_unknown_quantity', 'stag_unknown_quantity', 'current_not_upstream', 'stag_not_upstream',
                              'current_not_isp', 'stag_not_isp', 'current_fiber_maintenance', 'stag_fiber_maintenance',
                              'current_exclude', 'stag_exclude', 'current_flipped_speed', 'stag_flipped_speed',
                              'current_outlier_cost_per_circuit', 'stag_outlier_cost_per_circuit', 'current_unknown_conn_type', 'stag_unknown_conn_type',
                              'current_forced_bandwidth', 'stag_forced_bandwidth', 'current_not_bundled_ia', 'stag_not_bundled_ia',
                              'current_lines_received_error', 'stag_lines_received_error', 'current_special_construction', 'stag_special_construction',
                              'current_dqt_veto', 'stag_dqt_veto', 'current_video_conferencing', 'stag_video_conferencing',
                              'current_not_wan', 'stag_not_wan', 'current_duplicate_service', 'stag_duplicate_service',
                              'current_not_broadband', 'stag_not_broadband', 'current_dqt_veto_wan', 'stag_dqt_veto_wan')]

## define function to remove columns that only have one unique value
manual_flags <- c('dqt_veto_wan', 'dqt_veto', 'exclude', 'video_conferencing')
root_cols <- names(predictions)[grepl("stag", names(predictions))]
root_cols <- gsub("stag_", "", root_cols)
root_cols <- root_cols[root_cols != 'num_open_flags']
## also take out manual flags
root_cols <- root_cols[!root_cols %in% manual_flags]
remove.singular.cols <- function(dta){
  for (i in 1:length(root_cols)){
    ## take out the columns that don't change
    print(root_cols[i])
    if ((!TRUE %in% dta[,paste('current', root_cols[i], sep="_")]) & 
        (!TRUE %in% dta[,paste('stag', root_cols[i], sep="_")])){
      #print(root_cols[i])
      dta[,names(dta)[grepl(root_cols[i], names(dta))]] <- NULL
    }
  }
  for (i in 1:length(manual_flags)){
    dta[,names(dta)[grepl(manual_flags[i], names(dta))]] <- NULL
  }
  return(dta)
}

#predictions <- remove.singular.cols(predictions)

##**************************************************************************************************************************************************
## INVESTIGATE FLAGS

## change in number of flags
table(predictions$current_num_open_flags, predictions$stag_num_open_flags)

sub.less.flags <- predictions[which(predictions$stag_num_open_flags < predictions$current_num_open_flags),]
sub.same.flags <- predictions[which(predictions$stag_num_open_flags == predictions$current_num_open_flags),]
sub.more.flags <- predictions[which(predictions$stag_num_open_flags > predictions$current_num_open_flags),]

## investigate less flags
sub.less.flags$num_diff_flags <- sub.less.flags$current_num_open_flags - sub.less.flags$stag_num_open_flags
table(sub.less.flags$num_diff_flags)
sub <- sub.less.flags[which(sub.less.flags$num_diff_flags == 3),]
sub <- remove.singular.cols(sub)
sub <- sub.less.flags[which(sub.less.flags$num_diff_flags == 2),]
sub <- remove.singular.cols(sub)


