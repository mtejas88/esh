## =============================================================
##
## 2017 COMPARE DATA: Compare Predictions with Current Values
##
## =============================================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(tidyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

line.items.2017 <- read.csv("data/raw/line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.line.items.2017 <- read.csv("data/raw/clean_line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
flags <- read.csv("data/raw/flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
## DK model predictions
#predictions <- read.csv("src/dk_raw_model/model_data_versions/final_models/2017_predictions_June16_2017.csv", as.is=T, header=T, stringsAsFactors=F)
## ESH model predictions
predictions <- read.csv("src/esh_pristine_model/model_data_versions/2017_predictions.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT & MERGE DATA

predictions$frn_complete <- as.character(predictions$frn_complete)
length(unique(predictions$frn_complete)) == nrow(predictions)
names(predictions)[names(predictions) == "connect_category"] <- "pred_connect_category"

cl.line.items.2017$frn_complete <- as.character(cl.line.items.2017$frn_complete)
length(unique(cl.line.items.2017$frn_complete)) == nrow(cl.line.items.2017)

line.items.2017$frn_complete <- as.character(line.items.2017$frn_complete)

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

#combine <- merge(line.items.2017[,c('base_line_item_id', 'connect_category', 'id')], predictions, by.x='base_line_item_id', by.y='id', all.y=T)
combine <- merge(line.items.2017[,c('frn_complete', 'connect_category', 'id')], predictions, by='frn_complete', all.y=T)
combine <- merge(combine, flags, by.x="id", by.y="flaggable_id", all.x=T)
combine$diff.pred <- ifelse(combine$connect_category != combine$pred_connect_category, TRUE, FALSE)

changed <- combine[which(combine$diff.pred == TRUE),]
table(changed$connect_category, changed$pred_connect_category)
changed$counter <- 1
agg.cc <- aggregate(changed$counter, by=list(changed$connect_category), FUN=sum, na.rm=T)
names(agg.cc) <- c("current_connect_category", "line_item_count_changed")

same <- combine[which(combine$diff.pred == FALSE),]
table(same$product_bandwdith)

## find max probability for each line item
predictions$max.prob <- NA
for (i in 1:nrow(predictions)){
  predictions$max.prob[i] <- max(predictions[i,c(4:13)], na.rm=T)
}

##**************************************************************************************************************************************************
## create histogram of probabilities

#table(changed$pred_connect_category)
#sub.lf <- changed[which(changed$pred_connect_category == "Lit Fiber"),]
#hist(sub.lf$Lit.Fiber)

#pred.lf <- combine[which(combine$pred_connect_category == "Lit Fiber"),]
#pdf("presentation/figs/predicted_lit_fiber_probs.pdf", height=5, width=6)
#hist(pred.lf$Lit.Fiber, col=rgb(0,0,0,0.6), border=F, main="Predicted Lit Fiber", xlab="Probability", ylab="",
#     xlim=c(0,1.0), breaks=seq(0,1.0,by=0.02))
#ggplot(data=pred.lf, aes(pred.lf$Lit.Fiber)) +
#  geom_histogram(breaks=seq(0,1.0,by=0.02), col=rgb(1,1,1,0.6), fill=rgb(0,0,0,0.6)) +
#  labs(title="Predicted Lit Fiber") +
#  labs(x="Probability", y="") +
#  theme_bw() +
#  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
#                       panel.grid.minor = element_blank(), axis.line = element_line(colour = rgb(0,0,0,0.7)))
#dev.off()

#pdf("presentation/figs/predicted_connect_cat_probs.pdf", height=5, width=6)
#hist(predictions$max.prob, col=rgb(0,0,0,0.6), border=F, main="Predicted Connect Category", xlab="Probability", ylab="",
#     xlim=c(0,1.0), breaks=seq(0,1.0,by=0.02))
#ggplot(data=predictions, aes(predictions$max.prob)) +
#  geom_histogram(breaks=seq(0,1.0,by=0.02), col=rgb(1,1,1,0.6), fill=rgb(0,0,0,0.6)) +
#  labs(title="Predicted Connect Category") +
#  labs(x="Probability", y="") +
#  theme_bw() +
#  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
#        panel.grid.minor = element_blank(), axis.line = element_line(colour = rgb(0,0,0,0.7)))
#dev.off()

##**************************************************************************************************************************************************
## compare with DQT









