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
stag.district.flags <- read.csv("data/raw/district_flags_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.all.district.flags <- read.csv("data/raw/all_district_flags_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.line.item.flags <- read.csv("data/raw/line_item_flags_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.dd <- read.csv("data/raw/districts_deluxe_staging.csv", as.is=T, header=T, stringsAsFactors=F)
stag.sr <- read.csv("data/raw/services_received_staging.csv", as.is=T, header=T, stringsAsFactors=F)

## Current 2017
#cl.frns.2017 <- read.csv("data/raw/clean_frn_meta_data_2017.csv", as.is=T, header=T, stringsAsFactors=F)
#cl.line.items.2017 <- read.csv("data/raw/clean_line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
#cl.flags.2017 <- read.csv("data/raw/clean_flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
#cl.dd.2017 <- read.csv("data/raw/districts_deluxe_2017.csv", as.is=T, header=T, stringsAsFactors=F)

## ESH model predictions
predictions <- read.csv("data/interim/eng_subset_for_staging.csv", as.is=T, header=T, stringsAsFactors=F)

## ENG logic for predictions
eng.logic <- read.csv("../../General_Resources/datasets/Mass update_pred algorithm_FINAL_7.7.17.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT & MERGE DATA

## format frn_complete and frn fields
stag.line.items$frn_complete <- as.character(stag.line.items$frn_complete)
stag.frns$frn <- as.character(stag.frns$frn)
#cl.line.items.2017$frn_complete <- as.character(cl.line.items.2017$frn_complete)
#cl.frns.2017$frn <- as.character(cl.frns.2017$frn)
predictions$frn_complete <- as.character(predictions$frn_complete)

## subset the predictions to the ones that had a change in predicted connect_category
predictions <- predictions[which(predictions$connect_category != predictions$pred_connect_category),]
## merge in the line items in staging that were updated (since only a subset of the predictions can be updated)
names(stag.line.items)[names(stag.line.items) == 'connect_category'] <- 'changed_connect_category'
predictions <- merge(predictions, stag.line.items[,c('id', 'changed_connect_category')], by='id', all.x=T)
predictions <- predictions[which(predictions$pred_connect_category == predictions$changed_connect_category),]
## take out ISP Only Predictions
predictions <- predictions[which(predictions$pred_connect_category != 'ISP Only'),]

## create the frn field
for (i in 1:nrow(predictions)){
  predictions$frn[i] <- strsplit(predictions$frn_complete[i], "\\.")[[1]][1]
}
## merge in frn info to line items
predictions <- merge(predictions, stag.frns[,c('frn', 'postal_cd')], by='frn', all.x=T)

##**************************************************************************************************************************************************

## merge predictions with line item flags
names(stag.line.item.flags)[names(stag.line.item.flags) == "id"] <- 'id_in_flag_table'
pred.line.item.flags <- merge(predictions, stag.line.item.flags, by.x='id', by.y='flaggable_id', all.x=T)

## due to Marques' QA: Need to take out line item predictions where Product BW flags are raised
line.items.prod.bw.flag.open <- unique(pred.line.item.flags$id[which(pred.line.item.flags$label == "product_bandwidth" &
                                                                       pred.line.item.flags$status == 'open')])
pred.line.item.flags <- pred.line.item.flags[which(!pred.line.item.flags$id %in% line.items.prod.bw.flag.open),]
## also take them out of the predictions dataset
predictions <- predictions[which(!predictions$id %in% line.items.prod.bw.flag.open),]
predictions.jamie <- predictions

## aggregate at the line item level to see how many total resolved and opened
pred.line.item.flags$resolved <- ifelse(pred.line.item.flags$status == 'resolved', 1, 0)
pred.line.item.flags$open <- ifelse(pred.line.item.flags$status == 'open', 1, 0)
## fill NAs
pred.line.item.flags$resolved <- ifelse(is.na(pred.line.item.flags$status), 0, pred.line.item.flags$resolved)
pred.line.item.flags$open <- ifelse(is.na(pred.line.item.flags$status), 0, pred.line.item.flags$open)
## aggregate
pred.line.items <- aggregate(pred.line.item.flags$resolved, by=list(pred.line.item.flags$id), FUN=sum, na.rm=T)
names(pred.line.items) <- c('id', 'resolved')
pred.line.items.x <- aggregate(pred.line.item.flags$open, by=list(pred.line.item.flags$id), FUN=sum, na.rm=T)
names(pred.line.items.x) <- c('id', 'opened')
pred.line.items <- merge(pred.line.items, pred.line.items.x, by='id', all=T)
## merge in state
line.items.to.state <- unique(predictions[,c('id', 'postal_cd')])
pred.line.items <- merge(pred.line.items, line.items.to.state, by='id', all.x=T)
## create an indicator where the line items only had resolved flags (and none opened)
pred.line.items$smaller_num_flags <- ifelse(pred.line.items$resolved > pred.line.items$opened, 1, 0)
pred.line.items$larger_num_flags <- ifelse(pred.line.items$resolved < pred.line.items$opened, 1, 0)
pred.line.items$no_change <- ifelse(pred.line.items$resolved == pred.line.items$opened, 1, 0)
## aggregate line items at the state level
line.items.states.smaller <- aggregate(pred.line.items$smaller_num_flags, by=list(pred.line.items$postal_cd), FUN=sum, na.rm=T)
names(line.items.states.smaller) <- c('postal_cd', 'num_line_items_smaller_flags')
line.items.states.larger <- aggregate(pred.line.items$larger_num_flags, by=list(pred.line.items$postal_cd), FUN=sum, na.rm=T)
names(line.items.states.larger) <- c('postal_cd', 'num_line_items_larger_flags')
line.items.states.no.change <- aggregate(pred.line.items$no_change, by=list(pred.line.items$postal_cd), FUN=sum, na.rm=T)
names(line.items.states.no.change) <- c('postal_cd', 'num_line_items_no_change')
## merge
line.items.states <- merge(line.items.states.smaller, line.items.states.larger, by='postal_cd', all=T) 
line.items.states <- merge(line.items.states, line.items.states.no.change, by='postal_cd', all=T) 
line.items.states$total_line.items <- rowSums(line.items.states[,c(2:4)])
## create a row at the end that is the sum of all values
line.items.states <- rbind(line.items.states, rep(NA, ncol(line.items.states)))
line.items.states$postal_cd[nrow(line.items.states)] <- 'TOTAL'
for (i in 2:ncol(line.items.states)){
  line.items.states[line.items.states$postal_cd == 'TOTAL', i] <- sum(line.items.states[,i], na.rm=T)
}

## most common opened flags:
pred.line.item.flags.open <- pred.line.item.flags[which(pred.line.item.flags$status == 'open'),]
table(pred.line.item.flags.open$label)
## make a subset for product bandwdith open flags
pred.line.item.flags.open.product.bw <- pred.line.item.flags.open[which(pred.line.item.flags.open$label == 'product_bandwidth'),]
## most common resolved flags:
pred.line.item.flags.resolved <- pred.line.item.flags[which(pred.line.item.flags$status == 'resolved'),]
table(pred.line.item.flags.resolved$label)



## merge predictions with district flags
## first merge in district id to line items in predictions, we'll lose about half because those line items don't go to directly to districts
## (cleared this with Jeremy)
predictions <- merge(predictions, stag.sr[,c('line_item_id', 'recipient_id')], by.x='id', by.y='line_item_id', all.x=T)
predictions <- predictions[!is.na(predictions$recipient_id),]
names(stag.district.flags)[names(stag.district.flags) == "id"] <- 'id_in_flag_table'
pred.district.flags <- merge(predictions, stag.district.flags, by.x='recipient_id', by.y='flaggable_id', all.x=T)
## aggregate at the district level to see how many total resolved and opened
pred.district.flags$resolved <- ifelse(pred.district.flags$status == 'resolved', 1, 0)
pred.district.flags$open <- ifelse(pred.district.flags$status == 'open', 1, 0)
## fill NAs
pred.district.flags$resolved <- ifelse(is.na(pred.district.flags$status), 0, pred.district.flags$resolved)
pred.district.flags$open <- ifelse(is.na(pred.district.flags$status), 0, pred.district.flags$open)
## aggregate
pred.districts <- aggregate(pred.district.flags$resolved, by=list(pred.district.flags$recipient_id), FUN=sum, na.rm=T)
names(pred.districts) <- c('recipient_id', 'resolved')
pred.districts.x <- aggregate(pred.district.flags$open, by=list(pred.district.flags$recipient_id), FUN=sum, na.rm=T)
names(pred.districts.x) <- c('recipient_id', 'opened')
pred.districts <- merge(pred.districts, pred.districts.x, by='recipient_id', all=T)
## merge in state
districts.to.state <- unique(predictions[,c('recipient_id', 'postal_cd')])
pred.districts <- merge(pred.districts, districts.to.state, by='recipient_id', all.x=T)
## create an indicator where the districts only had resolved flags (and none opened)
pred.districts$smaller_num_flags <- ifelse(pred.districts$resolved > pred.districts$opened, 1, 0)
pred.districts$larger_num_flags <- ifelse(pred.districts$resolved < pred.districts$opened, 1, 0)
pred.districts$no_change <- ifelse(pred.districts$resolved == pred.districts$opened, 1, 0)
## aggregate districts at the state level
districts.states.smaller <- aggregate(pred.districts$smaller_num_flags, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.smaller) <- c('postal_cd', 'num_districts_smaller_flags')
districts.states.larger <- aggregate(pred.districts$larger_num_flags, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.larger) <- c('postal_cd', 'num_districts_larger_flags')
districts.states.no.change <- aggregate(pred.districts$no_change, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.no.change) <- c('postal_cd', 'num_districts_no_change')
## merge
districts.states <- merge(districts.states.smaller, districts.states.larger, by='postal_cd', all=T) 
districts.states <- merge(districts.states, districts.states.no.change, by='postal_cd', all=T) 
districts.states$total_districts <- rowSums(districts.states[,c(2:4)])

## most common opened flags:
pred.district.flags.open <- pred.district.flags[which(pred.district.flags$status == 'open'),]
table(pred.district.flags.open$label)
## most common resolved flags:
pred.district.flags.resolved <- pred.district.flags[which(pred.district.flags$status == 'resolved'),]
table(pred.district.flags.resolved$label)

##**************************************************************************************************************************************************
## define cleanliness for district

## create a version of the flags as of Friday BEFORE the mass update and keep a version AFTER the mass update:
## 1) subset all flags to only the districts we care about and merge in ia_bandwidth_per_student
stag.all.district.flags <- stag.all.district.flags[which(stag.all.district.flags$flaggable_id %in% pred.district.flags$recipient_id),]
stag.all.district.flags <- merge(stag.all.district.flags, stag.dd[,c('esh_id', 'ia_bandwidth_per_student_kbps')], by.x='flaggable_id',
                                 by.y='esh_id', all.x=T)
## 2) make copy for BEFORE and AFTER update
before.update.flags <- stag.all.district.flags
after.update.flags <- stag.all.district.flags
## 3) for BEFORE, revert the flags that were resolved by the mass update
resolved_flag_ids <- pred.district.flags$id_in_flag_table[pred.district.flags$status_update == 'flag resolved by mass update']
before.update.flags$status[before.update.flags$id %in% resolved_flag_ids] <- 'open'
## 4) for BEFORE, revert the flags that were opened by the mass update
opened_flag_ids <- pred.district.flags$id_in_flag_table[pred.district.flags$status_update == 'flag opened by mass update']
before.update.flags$status[before.update.flags$id %in% opened_flag_ids] <- 'resolved'

## define the logic for whether a district is dirty:
define.district.dirty <- function(dta, dta.store){
  unique.districts <- unique(pred.district.flags$recipient_id)
  for (i in 1:length(unique.districts)){
    sub <- dta[which(dta$flaggable_id == unique.districts[i] & dta$status == 'open'),]
    collect.flags.wan <- unique(sub$label)
    collect.flags.ia <- collect.flags.wan[!grepl("wan", collect.flags.wan)]
    ## assign district
    dta.store$recipient_id[i] <- unique.districts[i]
    ## apply logic for dirty for ia
    if ((length(collect.flags.ia) > 0) | (0 %in% unique(sub$ia_bandwidth_per_student_kbps))){
      dta.store$dirty_for_ia[i] <- TRUE
    } else{
      dta.store$dirty_for_ia[i] <- FALSE
    }
    ## apply logic for dirty for wan
    if (length(collect.flags.wan) > 0){
      dta.store$dirty_for_wan[i] <- TRUE
    } else{
      dta.store$dirty_for_wan[i] <- FALSE
    }
  }
  return(dta.store)
}

unique.districts <- unique(pred.district.flags$recipient_id)
before.districts <- data.frame(matrix(NA, nrow=length(unique.districts), ncol=3))
names(before.districts) <- c('recipient_id', 'dirty_for_ia', 'dirty_for_wan')
after.districts <- data.frame(matrix(NA, nrow=length(unique.districts), ncol=3))
names(after.districts) <- c('recipient_id', 'dirty_for_ia', 'dirty_for_wan')

before.districts <- define.district.dirty(before.update.flags, before.districts)
names(before.districts) <- c('recipient_id', 'before_dirty_for_ia', 'before_dirty_for_wan')
after.districts <- define.district.dirty(after.update.flags, after.districts)
names(after.districts) <- c('recipient_id', 'after_dirty_for_ia', 'after_dirty_for_wan')

## combine
districts <- merge(before.districts, after.districts, by='recipient_id', all=T)
districts$made_dirty_ia <- ifelse(districts$before_dirty_for_ia == FALSE & districts$after_dirty_for_ia == TRUE, 1, 0)
districts$made_dirty_wan <- ifelse(districts$before_dirty_for_wan == FALSE & districts$after_dirty_for_wan == TRUE, 1, 0)
districts$made_clean_ia <- ifelse(districts$before_dirty_for_ia == TRUE & districts$after_dirty_for_ia == FALSE, 1, 0)
districts$made_clean_wan <- ifelse(districts$before_dirty_for_wan == TRUE & districts$after_dirty_for_wan == FALSE, 1, 0)
districts$same_ia <- ifelse(districts$before_dirty_for_ia == districts$after_dirty_for_ia, 1, 0)
districts$same_wan <- ifelse(districts$before_dirty_for_wan == districts$after_dirty_for_wan, 1, 0)

## merge into pred.districts
pred.districts <- merge(pred.districts, districts, by='recipient_id', all=T)

## aggregate by state
districts.states.made.dirty.ia <- aggregate(pred.districts$made_dirty_ia, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.made.dirty.ia) <- c('postal_cd', 'num_districts_made_dirty_ia')
districts.states.made.dirty.wan <- aggregate(pred.districts$made_dirty_wan, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.made.dirty.wan) <- c('postal_cd', 'num_districts_made_dirty_wan')
districts.states.made.clean.ia <- aggregate(pred.districts$made_clean_ia, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.made.clean.ia) <- c('postal_cd', 'num_districts_made_clean_ia')
districts.states.made.clean.wan <- aggregate(pred.districts$made_clean_wan, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.made.clean.wan) <- c('postal_cd', 'num_districts_made_clean_wan')
districts.states.same.ia <- aggregate(pred.districts$same_ia, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.same.ia) <- c('postal_cd', 'num_districts_same_ia')
districts.states.same.wan <- aggregate(pred.districts$same_wan, by=list(pred.districts$postal_cd), FUN=sum, na.rm=T)
names(districts.states.same.wan) <- c('postal_cd', 'num_districts_same_wan')

## add to districts.states
districts.states <- merge(districts.states, districts.states.made.dirty.ia, by='postal_cd', all.x=T)
districts.states <- merge(districts.states, districts.states.made.dirty.wan, by='postal_cd', all.x=T)
districts.states <- merge(districts.states, districts.states.made.clean.ia, by='postal_cd', all.x=T)
districts.states <- merge(districts.states, districts.states.made.clean.wan, by='postal_cd', all.x=T)
districts.states <- merge(districts.states, districts.states.same.ia, by='postal_cd', all.x=T)
districts.states <- merge(districts.states, districts.states.same.wan, by='postal_cd', all.x=T)

## create a row at the end that is the sum of all values
districts.states <- rbind(districts.states, rep(NA, ncol(districts.states)))
districts.states$postal_cd[nrow(districts.states)] <- 'TOTAL'
for (i in 2:ncol(districts.states)){
  districts.states[districts.states$postal_cd == 'TOTAL', i] <- sum(districts.states[,i], na.rm=T)
}


## format predictions to be passed back to ENG
predictions.eng <- predictions.jamie 
## subset logic defined previously by ENG
eng.logic <- eng.logic[which(eng.logic$id %in% predictions.eng$id),]
## merge in the probabilities
eng.logic <- merge(eng.logic, predictions.eng[,c(2,8:17)], by='id', all.x=T)

##**************************************************************************************************************************************************
## write out data

write.csv(districts.states, "data/interim/districts_by_states_impact_analysis.csv", row.names=F)
write.csv(line.items.states, "data/interim/line_items_by_states_impact_analysis.csv", row.names=F)

## product bandwidth -- why are they open?
## write out open product BW line items
#write.csv(pred.line.item.flags.open.product.bw, "data/interim/product_bw_line_item_flags_open.csv", row.names=T)

## for cross-over between Jamie's work
## write out the finalized line items affected by the mass update
write.csv(predictions.jamie, "data/interim/line_items_predicted_for_jamie.csv", row.names=F)

## write out FINAL ENG dataset
write.csv(eng.logic, "data/interim/final_ML_update_line_items_7-13-2017.csv", row.names=F)
