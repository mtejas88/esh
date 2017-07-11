## =============================================================
##
## 2017 COMPARE DATA: Compare Predictions with Current Values
##
## =============================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/machine_cleaning_2017/")

library(dplyr)
library(tidyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

line.items.2017 <- read.csv("data/raw/line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.frns.2017 <- read.csv("data/raw/clean_frn_meta_data_2017.csv", as.is=T, header=T, stringsAsFactors=F)
cl.line.items.2017 <- read.csv("data/raw/clean_line_items_2017.csv", as.is=T, header=T, stringsAsFactors=F)
clean.flags.2017 <- read.csv("data/raw/clean_flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
flags <- read.csv("data/raw/flags_2017.csv", as.is=T, header=T, stringsAsFactors=F)
## DK model predictions
#predictions <- read.csv("src/dk_raw_model/model_data_versions/final_models/2017_predictions_June16_2017.csv", as.is=T, header=T, stringsAsFactors=F)
## ESH model predictions
predictions <- read.csv("src/esh_pristine_model/model_versions/final_models/2017_predictions.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT & MERGE DATA

predictions$frn_complete <- as.character(predictions$frn_complete)
length(unique(predictions$frn_complete)) == nrow(predictions)
names(predictions)[names(predictions) == "connect_category"] <- "pred_connect_category"

cl.line.items.2017$frn_complete <- as.character(cl.line.items.2017$frn_complete)
cl.frns.2017$frn <- as.character(cl.frns.2017$frn)
line.items.2017$frn_complete <- as.character(line.items.2017$frn_complete)

## subset to only broadband line items
cl.line.items.2017 <- cl.line.items.2017[which(cl.line.items.2017$broadband == 't'),]

## create FRN id for cl.line.items.2017
cl.line.items.2017$frn <- as.character(cl.line.items.2017$frn_complete)
for (i in 1:nrow(cl.line.items.2017)){
  cl.line.items.2017$frn[i] <- strsplit(cl.line.items.2017$frn[i], "\\.")[[1]][1]
}

## combine metadata with line item data
cl_combined <- merge(cl.line.items.2017, cl.frns.2017[,c('frn', names(cl.frns.2017)[!names(cl.frns.2017) %in% names(cl.line.items.2017)])],
                by='frn', all.x=T)

## merge in flags
cl_combined <- merge(cl_combined, clean.flags.2017, by.x="id", by.y="flaggable_id", all.x=T)

## compare with DQT (QA)

## first, states that have been confirmed by DQT: MA, TN, AL, AZ, KS, MD, NJ, FL, NH, CO, MO, TX, OR
states.qa <- c('MA', 'TN', 'AL', 'AZ', 'KS', 'MD', 'NJ', 'FL', 'NH', 'CO', 'MO', 'TX', 'OR')
cl_combined$qa.state <- ifelse(cl_combined$postal_cd %in% states.qa, TRUE, FALSE)

## combined QA with predictions
dqt.qa <- merge(cl_combined, predictions, by='frn_complete', all=T)

## create an indicator if the connect_category matches the predicted category
dqt.qa$match <- ifelse(dqt.qa$connect_category == dqt.qa$pred_connect_category, TRUE, FALSE)

## save the larger dataset
dqt.qa.all <- dqt.qa

## look at proportion of cases that don't match in the population
table(dqt.qa.all$match)

## create a subset where the state has been QA'd and there are no open flags
dqt.qa <- dqt.qa[which(dqt.qa$qa.state == TRUE & is.na(dqt.qa$num_open_flags)),]
## look at proportion of cases that don't match in the QA subset
table(dqt.qa$match)

## create an indicator for difference between highest predicted value and and the second highest
## and also max probability
dqt.qa$difference_between_1st_2nd <-  NA
for (i in 1:nrow(dqt.qa)){
  order.pred <- c(dqt.qa[i,91], dqt.qa[i,92], dqt.qa[i,93], dqt.qa[i,94], dqt.qa[i,95],
                  dqt.qa[i,96], dqt.qa[i,97], dqt.qa[i,98], dqt.qa[i,99], dqt.qa[i,100])
  order.pred <- order.pred[order(order.pred, decreasing=T)]
  dqt.qa$difference_between_1st_2nd[i] <- order.pred[1] - order.pred[2]
  dqt.qa$max_prob[i] <- order.pred[1]
}
range(dqt.qa$difference_between_1st_2nd, na.rm=T)
range(dqt.qa$max_prob, na.rm=T)


## calculate the porportion of falses for each probability bucket
prob.buckets <- seq(0,1,by=0.10)
dqt.qa$prob.bucket <- ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[2], 1,
                             ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[3], 2,
                                    ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[4], 3,
                                           ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[5], 4,
                                                  ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[6], 5,
                                                         ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[7], 6,
                                                                ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[8], 7,
                                                                       ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[9], 8,
                                                                              ifelse(dqt.qa$difference_between_1st_2nd < prob.buckets[10], 9, 10)))))))))



## Flags
#flags <- flags[,c('flaggable_id', 'open_flag_labels')]
#flags$open_flag_labels <- gsub("\\{", "", flags$open_flag_labels)
#flags$open_flag_labels <- gsub("\\}", "", flags$open_flag_labels)
## break out the flags into different columns
#flags <- flags %>% separate(open_flag_labels, c("flag1", "flag2", "flag3", "flag4"), ",")
#unique.flags <- unique(c(flags$flag1, flags$flag2, flags$flag3, flags$flag4))
## create an indicator for whether a line item is flagged with "product_bandwidth"
#flags$product_bandwdith <- ifelse(flags$flag1 == "product_bandwidth" | flags$flag2 == "product_bandwidth" | flags$flag3 == "product_bandwidth" |
#                                    flags$flag4 == "product_bandwidth", TRUE, FALSE)
#flags$product_bandwdith <- ifelse(is.na(flags$product_bandwdith), FALSE, flags$product_bandwdith)

#combine <- merge(line.items.2017[,c('base_line_item_id', 'connect_category', 'id')], predictions, by.x='base_line_item_id', by.y='id', all.y=T)
#combine <- merge(line.items.2017[,c('frn_complete', 'connect_category', 'id')], predictions, by='frn_complete', all.y=T)
#combine <- merge(combine, flags, by.x="id", by.y="flaggable_id", all.x=T)
#combine$diff.pred <- ifelse(combine$connect_category != combine$pred_connect_category, TRUE, FALSE)

#changed <- combine[which(combine$diff.pred == TRUE),]
#table(changed$connect_category, changed$pred_connect_category)
#changed$counter <- 1
#agg.cc <- aggregate(changed$counter, by=list(changed$connect_category), FUN=sum, na.rm=T)
#names(agg.cc) <- c("current_connect_category", "line_item_count_changed")

#same <- combine[which(combine$diff.pred == FALSE),]
#table(same$product_bandwdith)

## find max probability for each line item
#predictions$max.prob <- NA
#for (i in 1:nrow(predictions)){
#  predictions$max.prob[i] <- max(predictions[i,c(4:13)], na.rm=T)
#}

##**************************************************************************************************************************************************
## Compare with DQT results

sub.true <- dqt.qa[which(dqt.qa$match == TRUE),]
sub.false <- dqt.qa[which(dqt.qa$match == FALSE),]
table(sub.false$connect_category, sub.false$pred_connect_category)
## ISP Only is the highest category wrongly predicted
prop.table(table(sub.false$pred_connect_category))
sub.false.isp <- sub.false[which(sub.false$pred_connect_category == 'ISP Only'),]
prop.table(table(sub.false$connect_category))
## not that high in the other categories
prop.table(table(sub.true$pred_connect_category))
prop.table(table(dqt.qa$pred_connect_category))

## plot difference metric when false
#hist(sub.false$difference_between_1st_2nd)

pdf("figures/density_plot_prob_diff_metric.pdf", height=5, width=7)
## plot line for false
h <- hist(sub.false$difference_between_1st_2nd, breaks=seq(0,1,0.1), plot=FALSE)
plot(x=h$mids, y=h$density, type="l", col=rgb(1,0,0,0.8),
     xaxt="n", xlab="Prob Difference between\n 1st and 2nd Predicted Category", ylab="density", main="Density Plot")
## plot line for true
h2 <- hist(sub.true$difference_between_1st_2nd, breaks=seq(0,1,0.1), plot=FALSE)
lines(x=h2$mids, y=h2$density, type="l", col=rgb(0,0.8,0,0.8))
axis(1, at=seq(0,1,0.1), labels=seq(0,1,0.1))
## plot line for all
#h3 <- hist(dqt.qa$difference_between_1st_2nd, breaks=seq(0,1,0.1), plot=FALSE)
#lines(x=h3$mids, y=h3$density, type="l", col=rgb(0, 0, 0, 0.6))
dev.off()

## aggregate the proportion of FALSE at each bucket
dqt.qa$false.ind <- ifelse(dqt.qa$match == FALSE, 1, 0)
dqt.qa$counter <- 1
false.prop <- aggregate(dqt.qa$false.ind, by=list(dqt.qa$prob.bucket), FUN=sum, na.rm=T)
names(false.prop) <- c('bucket', 'false.total')
total <- aggregate(dqt.qa$counter, by=list(dqt.qa$prob.bucket), FUN=sum, na.rm=T)
names(total) <- c('bucket', 'total')
## merge
false.prop <- merge(false.prop, total, by='bucket', all=T)
false.prop$false.proportion <- false.prop$false.total / false.prop$total

pdf("figures/proportion_false.pdf", height=5, width=5)
plot(x=false.prop$bucket, y=false.prop$false.proportion, type="l", col=rgb(0,0,0,0.8),
     xaxt="n", xlab="Prob Difference between\n 1st and 2nd Predicted Category (Bucket)", ylab="Proportion", main="Proportion of False")
axis(1, at=seq(1,10,1), labels=seq(1,10,1))
points(x=false.prop$bucket, y=false.prop$false.proportion, cex=1/50*sqrt(false.prop$total)*pi, col=rgb(0,0,0,0.4), pch=16)
dev.off()



## What if we left out ISP Only?
#sub.true.no.isp <- dqt.qa[which(dqt.qa$match == TRUE & dqt.qa$pred_connect_category != 'ISP Only'),]
sub.false.no.isp <- dqt.qa[which(dqt.qa$match == FALSE & dqt.qa$pred_connect_category != 'ISP Only'),]
table(sub.false.no.isp$prob.bucket)
pdf("figures/density_plot_prob_diff_metric_no_isp.pdf", height=5, width=7)
## plot line for false
h <- hist(sub.false.no.isp$difference_between_1st_2nd, breaks=seq(0,1,0.1), plot=FALSE)
plot(x=h$mids, y=h$density, type="l", col=rgb(1,0,0,0.8), ylim=c(0,5),
     xaxt="n", xlab="Prob Difference between\n 1st and 2nd Predicted Category", ylab="density", main="Density Plot")
## plot line for true
h2 <- hist(sub.true$difference_between_1st_2nd, breaks=seq(0,1,0.1), plot=FALSE)
lines(x=h2$mids, y=h2$density, type="l", col=rgb(0,0.8,0,0.8))
axis(1, at=seq(0,1,0.1), labels=seq(0,1,0.1))
dev.off()

## aggregate the proportion of FALSE at each bucket
dqt.qa$false.ind <- ifelse(dqt.qa$match == FALSE & dqt.qa$pred_connect_category != 'ISP Only', 1, 0)
dqt.qa$counter <- ifelse(dqt.qa$pred_connect_category != 'ISP Only', 1, 0)
false.prop <- aggregate(dqt.qa$false.ind, by=list(dqt.qa$prob.bucket), FUN=sum, na.rm=T)
names(false.prop) <- c('bucket', 'false.total')
total <- aggregate(dqt.qa$counter, by=list(dqt.qa$prob.bucket), FUN=sum, na.rm=T)
names(total) <- c('bucket', 'total')
## merge
false.prop <- merge(false.prop, total, by='bucket', all=T)
false.prop$false.proportion <- false.prop$false.total / false.prop$total

pdf("figures/proportion_false_no_isp.pdf", height=5, width=5)
plot(x=false.prop$bucket, y=false.prop$false.proportion, type="l", col=rgb(0,0,0,0.8),
     xaxt="n", xlab="Prob Difference between\n 1st and 2nd Predicted Category (Bucket)", ylab="Proportion", main="Proportion of False")
axis(1, at=seq(1,10,1), labels=seq(1,10,1))
points(x=false.prop$bucket, y=false.prop$false.proportion, cex=1/50*sqrt(false.prop$total)*pi, col=rgb(0,0,0,0.4), pch=16)
dev.off()


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
## Create Subset for ENG Staging

#raw.ids <- unique(line.items.2017$frn_complete[line.items.2017$broadband == 't'])

## subset the cleaned line items
#to.merge <- unique(cl.line.items.2017[cl.line.items.2017$frn_complete %in% raw.ids, c('frn_complete', 'id', 'connect_type', 'function.', 'connect_category')])
## merge in id, current connect category, current function, and current connect type
#eng <- merge(to.merge, predictions[predictions$frn_complete %in% raw.ids,], by='frn_complete', all.y=T)
#eng$pred <- NULL
#eng <- unique(eng)
#eng <- eng[!is.na(eng$id),]
#length(unique(eng$id))

## write out the dataset
#write.csv(eng, "data/interim/eng_subset_for_staging.csv", row.names=F)
