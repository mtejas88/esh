#library(class)
library(caret)
#library(dplyr)
#library(sqldf)
library(randomForest)
#library(rfUtilities)
#library(randomForestSRC)
#library(RPostgreSQL)
library(dplyr)

setwd("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Data Strategy/Machine Learn Clean")

verified_lis <- read.csv("verified_line_items_v7.csv")
raw_lis <- read.csv("original_line_items_v7.csv")

joined = merge(x = raw_lis, y = verified_lis, by = 'frn_complete', all.y = TRUE)
compacted_joined <- select(joined, frn_complete:akira_consortium_shared.x, connect_category_adjusted.y)

compacted_joined <- na.omit(compacted_joined)

data.size <- nrow(compacted_joined)
train.size <- round(data.size *.8, 0)
test.size <- data.size - train.size
training_id_integers <- sample(data.size, train.size)

train_data <- compacted_joined[training_id_integers,]
test_data <- compacted_joined[-training_id_integers,]

connect.forest <- randomForest(as.factor(connect_category_adjusted.y) ~ 
                                 raw_postal_cd.x +
                                 raw_service_type.x + akira_type_of_service.x + raw_connect_type.x +
                                 raw_purpose.x + raw_wan.x + raw_num_lines.x + raw_rec_elig_cost.x + raw_one_time_eligible_cost.x + 
                                 raw_burstable_bw_entered.x + raw_firewall.x + raw_last_mile.x + akira_applicant_type.x + 
                                 known_isp_only_provider.x + known_fixed_wireless_provider.x +
                                 akira_num_recipients.x + akira_consortium_shared.x + raw_downspeed_bandwidth.x +
                                 raw_upspeed_bandwidth.x, data=train_data, importance=T, ntree=501)

connect.forest$importance
varImpPlot(connect.forest)

predict.forest <- predict(connect.forest, test_data)
confusionMatrix(predict.forest, reference=test_data$connect_category_adjusted.y)

##prediction checking
cross.2015$raw_postal_cd.x <- factor(cross.2015$raw_postal_cd.x, levels=levels(train_data$raw_postal_cd.x))
cross.2015$raw_connect_type.x <- factor(cross.2015$raw_connect_type.x, levels=levels(train_data$raw_connect_type.x))
cross.2015$raw_service_type.x <- factor(cross.2015$raw_service_type.x, levels=levels(train_data$raw_service_type.x))
cross.2015$akira_type_of_service.x <- factor(cross.2015$akira_type_of_service.x, levels=levels(train_data$akira_type_of_service.x))
cross.2015$raw_purpose.x <- factor(cross.2015$raw_purpose.x, levels=levels(train_data$raw_purpose.x))
cross.2015$raw_wan.x <- factor(cross.2015$raw_wan.x, levels=levels(train_data$raw_wan.x))
cross.2015$raw_burstable_bw_entered.x <- factor(cross.2015$raw_burstable_bw_entered, levels=levels(train_data$raw_burstable_bw_entered.x))
cross.2015$raw_firewall.x <- factor(cross.2015$raw_firewall, levels=levels(train_data$raw_firewall.x))
cross.2015$raw_last_mile.x <- factor(cross.2015$raw_last_mile.x, levels=levels(train_data$raw_last_mile.x))
cross.2015$akira_applicant_type.x <- factor(cross.2015$akira_applicant_type.x, levels=levels(train_data$akira_applicant_type.x))
cross.2015$known_isp_only_provider.x <- factor(cross.2015$known_isp_only_provider.x, levels=levels(train_data$known_isp_only_provider.x))
cross.2015$known_fixed_wireless_provider.x <- factor(cross.2015$known_fixed_wireless_provider.x, levels=levels(train_data$known_fixed_wireless_provider.x))
cross.2015$akira_consortium_shared.x <- as.logical(cross.2015$akira_consortium_shared.x)

predict.cc.forest.2015.all <- predict(connect.forest, cross.2015)
predict.prob.cc.forest.2015.all <- predict(connect.forest, cross.2015, "prob")

cross.2015$predicted_cc <- predict.cc.forest.2015.all
cross.2015$probability_cc <- predict.prob.cc.forest.2015.all
cross.2015$cc_same <- as.character(cross.2015$connect_category_adjusted.y) == as.character(cross.2015$predicted_cc)

cross.2015<- cross.2015[,c("frn_complete", "production_id", "raw_postal_cd.x", "predicted_purpose", "probability_purpose",
                           "predicted_cc", "probability_cc", "reviewed_purpose",  "connect_category_adjusted.x",
                           "isp_indicator", "upstream_indicator", "wan_indicator", "internet_indicator", 
                           "known_isp_only_provider.x", "known_fixed_wireless_provider.x", "review_status", "number_of_dirty_line_item_flags", 
                           "open_flags","recipient_districts", "count_recipient_districts", "recipient_schools",
                           "category", "raw_service_type.x", "akira_type_of_service.x", "raw_connect_type.x", "raw_purpose.x",
                           "raw_wan.x", "raw_num_lines.x", "raw_rec_elig_cost.x", "raw_one_time_eligible_cost.x", 
                           "raw_burstable_bw_entered", "raw_firewall", "raw_last_mile.x", "raw_downspeed_bandwidth.x", 
                           "raw_upspeed_bandwidth.x", "akira_applicant_type.x", "akira_service_provider_name", 
                           "connect_category_adjusted.y", "akira_num_recipients.x", "akira_consortium_shared.x", 
                           "akira_connect_category", "applicant_type", "connect_category", "num_lines", "bandwidth_in_mbps", 
                           "orig_purpose", "rec_elig_cost", "one_time_elig_cost", "cost_per_circuit", "cost_per_mbps", 
                           "applicant_type.y", "recipient_schools_per_district", "connect_category.y", "connect_type.y", 
                           "bandwidth_in_mbps.y", "num_lines.y", "raw_burstable_bw_entered.x", "raw_firewall.x", "purpose_same",
                           "cc_same")]
write.csv(cross.2015, "orig_verif_predict_cross_all_2015.csv", row.names = FALSE) #prediction for all verified line items

cross.2015.dqs.review <- cross.2015[!is.na(cross.2015$predicted_cc),]  
cross.2015.dqs.review <- cross.2015.dqs.review[!is.na(cross.2015.dqs.review$predicted_purpose),] 
cross.2015.dqs.review <- cross.2015.dqs.review[cross.2015.dqs.review$count_recipient_districts > 0,]
cross.randomforest.train$frn_complete <- paste (cross.randomforest.train$frn, cross.randomforest.train$frn_line_item_no , sep = "-", collapse = NULL)
cross.2015.dqs.review <- cross.2015.dqs.review[!(cross.2015.dqs.review$frn_complete %in% cross.randomforest.train[,c('frn_complete')]),]
cross.2015.dqs.review <- cross.2015.dqs.review[!(cross.2015.dqs.review$frn_complete %in% train_data[,c('frn_complete')]),]
write.csv(cross.2015.dqs.review, "orig_verif_predict_cross_all_2015_dqsreview.csv", row.names = FALSE) #prediction for dqs review

cross.2015.quantify.change <- cross.2015[cross.2015$count_recipient_districts > 0,]
cross.2015.quantify.change <- cross.2015.quantify.change[!with(cross.2015.quantify.change,
                                                               is.na(cross.2015.quantify.change$predicted_cc)
                                                               & is.na(cross.2015.quantify.change$predicted_purpose)),]  
write.csv(cross.2015.quantify.change, "orig_verif_predict_cross_all_2015_quantifychange.csv", row.names = FALSE) #prediction for dqs review
