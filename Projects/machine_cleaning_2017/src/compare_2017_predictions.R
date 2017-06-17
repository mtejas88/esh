## =============================================================
##
## 2017 COMPARE DATA: Compare Predictions with Current Values
##
## =============================================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(tidyr)

##**************************************************************************************************************************************************
## READ IN DATA

line.items.2017 <- read.csv("data/raw/line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
#frn.meta.data.2017 <- read.csv("data/raw/frn_meta_data_2017.csv", as.is=T, header=T, stringsAsFactors=F)
flags <- read.csv("data/raw/flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
predictions <- read.csv("src/dk_raw_model/model_data_versions/final_models/2017_predictions_June16_2017.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

names(predictions)[names(predictions) == "connect_category"] <- "pred_connect_category"

## Flags
flags <- flags[,c('flaggable_id', 'open_flag_labels')]
flags$open_flag_labels <- gsub("\\{", "", flags$open_flag_labels)
flags$open_flag_labels <- gsub("\\}", "", flags$open_flag_labels)
## break out the flags into different columns
flags <- flags %>% separate(open_flag_labels, c("flag1", "flag2", "flag3", "flag4"), ",")
unique.flags <- unique(c(flags$flag1, flags$flag2, flags$flag3, flags$flag4))
## create an indicator for whether a line item is flagged with "product_bandwidth"
flags$product_bandwdith <- ifelse(flags$flag1 == "product_bandwidth" | flags$flag2 == "product_bandwidth" | flags$flag3 == "product_bandwidth" |
                                    flags$flag4 == "product_bandwidth", TRUE, FALSE)
flags$product_bandwdith <- ifelse(is.na(flags$product_bandwdith), FALSE, flags$product_bandwdith)


## determine which id to merge on:
class(predictions$id)
class(line.items.2017$id)
class(line.items.2017$base_line_item_id)
range(predictions$id)
range(line.items.2017$id)
range(line.items.2017$base_line_item_id, na.rm=T)

combine <- merge(line.items.2017[,c('base_line_item_id', 'connect_category', 'id')], predictions, by.x='base_line_item_id', by.y='id', all.y=T)
combine <- merge(combine, flags, by.x="id", by.y="flaggable_id", all.x=T)

combine$diff.pred <- ifelse(combine$connect_category != combine$pred_connect_category, TRUE, FALSE)

changed <- combine[which(combine$diff.pred == TRUE),]
table(changed$connect_category, changed$pred_connect_category)
changed$counter <- 1
agg.cc <- aggregate(changed$counter, by=list(changed$connect_category), FUN=sum, na.rm=T)
names(agg.cc) <- c("current_connect_category", "line_item_count_changed")

same <- combine[which(combine$diff.pred == FALSE),]
table(same$product_bandwdith)


## probabilities that were undetermined either way -- > hard cases, put in IRT


