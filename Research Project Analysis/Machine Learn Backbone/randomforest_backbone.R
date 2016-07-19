##packages
library(randomForest)
library(caret)
#library(tree)
#library(party)
#install.packages("party", 
#                 repos=c("http://rstudio.org/_packages", "http://cran.rstudio.com"))

setwd("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Data Strategy/Machine Learn Clean")

##importing and merging 2015 verified files
orig <- read.csv('orig_broadband_line_items.csv') # predictors
verified <- read.csv('verified_and_inferred_or_backbone.csv') # outcome
orig <- na.omit(orig)
verified <- na.omit(verified)
cross <- merge(verified,orig,by = c("frn","frn_line_item_no"))
cross <- unique(cross)
cross <- cross[!duplicated(cross[,c('frn','frn_line_item_no')]),]

##creating 2015 verified variables
cross <- cross[as.character(cross$backbone_conditions_met) %in% c('false', 'true'),]
cross$backbone_conditions_met <- as.factor(cross$backbone_conditions_met)
cross$backbone_conditions_met <- droplevels(cross$backbone_conditions_met)
cross$rec_elig_cost.y <- as.numeric(cross$rec_elig_cost.y)
cross$cost_per_circuit <- (cross$rec_elig_cost.y+(cross$one_time_eligible_cost.y/12))/cross$num_lines.y
cross$cost_per_mbps <- cross$cost_per_circuit/cross$bandwidth_in_mbps.y
cross <- cross[is.finite(cross$cost_per_circuit),]
cross$count_recipient_districts <- as.numeric(cross$count_recipient_districts)
cross$recipient_schools_per_district <- as.integer(as.numeric(cross$recipient_schools)/cross$count_recipient_districts)
cross <- cross[is.finite(cross$recipient_schools_per_district),]

###test and train on 2015 verified data
data.size <- nrow(cross)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size
train_vector <- sample(data.size, train.size)
cross.train <- cross[train_vector,] 
cross.test <- cross[-train_vector,]

##running classification
backbone.forest.2016 <- randomForest(backbone_conditions_met ~ internet_conditions_met.y + upstream_conditions_met.y +
                                    +wan_conditions_met.y + isp_conditions_met.y +applicant_type.y+cost_per_circuit
                                    +connect_type.y
                                    +bandwidth_in_mbps.y+count_recipient_districts
                                    +recipient_schools_per_district+num_lines.y, data=cross.train, 
                                    importance=T, ntree=501)
varImpPlot(backbone.forest.2016)
backbone.forest.2016$importance

##accuracy measure
predict.backbone.forest.2016 <- predict(backbone.forest.2016, cross.test)
predict.prob.backbone.forest.2016 <- predict(backbone.forest.2016, cross.test, "prob")
cross.test$predicted_category <- predict.backbone.forest.2016
cross.test$probability <- predict.prob.backbone.forest.2016
confusionMatrix(predict.backbone.forest.2016, reference = cross.test$backbone_conditions_met) #accuracy = 100% excluding train set

##prediction checking
predict.backbone.forest.2016.all <- predict(backbone.forest.2016, cross)
predict.prob.backbone.forest.2016.all <- predict(backbone.forest.2016, cross, "prob")
cross.all <- cross
cross.all$predicted_category <- predict.backbone.forest.2016.all
cross.all$probability <- predict.prob.backbone.forest.2016.all
confusionMatrix(predict.backbone.forest.2016.all, reference = cross$backbone_conditions_met) #accuracy = 100% including train set
write.csv(cross.all, "backbone_predict_cross_all.csv", row.names = FALSE) #prediction for all verified line items
