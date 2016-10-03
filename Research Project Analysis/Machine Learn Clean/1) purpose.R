##packages
#install.packages("randomForest")
#install.packages("caret")
library(randomForest)
library(caret)
#library(tree)
#library(party)
#install.packages("party", 
#                 repos=c("http://rstudio.org/_packages", "http://cran.rstudio.com"))

setwd("\Google Drive\ESH Main Share\Strategic Analysis Team\2016\Org-wide Projects\Data Strategy\Machine Learn Clean")


##importing and merging 2015 verified files
orig <- read.csv('orig_broadband_line_items.csv') # predictors
verified <- read.csv('verified_and_inferred_broadband_line_items.csv') # outcome

verified <- na.omit(verified, cols="frn_line_item_no")
orig <- na.omit(orig, cols="frn_line_item_no")

cross <- merge(verified,orig,by = c("frn","frn_line_item_no"))
cross <- unique(cross)

cross <- cross[!duplicated(cross[,c('frn','frn_line_item_no')]),]
##creating 2015 verified variables
cross$verified_purpose <-   ifelse(cross$internet_conditions_met.x == 'true', 'Internet',
                                   ifelse(cross$upstream_conditions_met.x == 'true', 'Upstream', 
                                          ifelse(cross$wan_conditions_met.x == 'true', 'WAN', 
                                                 ifelse(cross$isp_conditions_met.x == 'true', 'ISP', 'Unknown'))))
cross$orig_purpose <-   ifelse(cross$internet_conditions_met.y == 'true', 'Internet',
                               ifelse(cross$upstream_conditions_met.y == 'true', 'Upstream', 
                                      ifelse(cross$wan_conditions_met.y == 'true', 'WAN', 
                                             ifelse(cross$isp_conditions_met.y == 'true', 'ISP', 'Unknown'))))
cross <- cross[!cross$verified_purpose == 'Unknown',]
#cross$orig_purpose <- ifelse(cross$orig_purpose == 'Unknown', cross$verified_purpose, cross$orig_purpose)
#include if running for 2016, exclude if running for 2016

cross$rec_elig_cost.y <- as.numeric(cross$rec_elig_cost.y)
cross$cost_per_circuit <- (cross$rec_elig_cost.y+(cross$one_time_eligible_cost.y/12))/cross$num_lines.y
cross$cost_per_mbps <- cross$cost_per_circuit/cross$bandwidth_in_mbps.y

cross <- cross[is.finite(cross$cost_per_circuit),]

cross$category <-  ifelse( grepl('Electric', as.character(cross$category)), 'Electric', as.character(cross$category))
cross$verified_purpose <- as.factor(cross$verified_purpose)
cross$category <- as.factor(cross$category)
cross$orig_purpose <- as.factor(cross$orig_purpose)
cross$recipient_schools_per_district <- as.integer(cross$recipient_schools/cross$count_recipient_districts)
cross <- na.omit(cross, cols="recipient_schools_per_district") 
cross$connect_category.y <- as.factor(cross$connect_category.y)

cross.randomforest <- cross[,c("verified_purpose","category","orig_purpose","applicant_type.y",
                               "isp_indicator","wan_indicator","upstream_indicator", "internet_indicator",
                               "bandwidth_in_mbps.y","recipient_schools", "connect_type.y","connect_category.y", 
                               "num_lines.y", "cost_per_circuit", "cost_per_mbps", "recipient_schools_per_district",
                               "count_recipient_districts", "frn", "frn_line_item_no")]

###test and train on 2015 verified data
data.size <- nrow(cross.randomforest)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size
train_vector <- sample(data.size, train.size)
cross.randomforest.train <- cross.randomforest[train_vector,] 
cross.randomforest.test <- cross.randomforest[-train_vector,]

##running classification
purpose.forest.2016 <- randomForest(verified_purpose ~ category
                                    +orig_purpose +applicant_type.y+cost_per_circuit
                                    +connect_type.y+isp_indicator+wan_indicator+upstream_indicator
                                    +bandwidth_in_mbps.y+count_recipient_districts+internet_indicator
                                    +recipient_schools_per_district+num_lines.y, data=cross.randomforest.train, 
                                    importance=T, ntree=501)

varImpPlot(purpose.forest.2016)
purpose.forest.2016$importance

##accuracy measure
predict.purpose.forest.2016 <- predict(purpose.forest.2016, cross.randomforest.test)
predict.prob.purpose.forest.2016 <- predict(purpose.forest.2016, cross.randomforest.test, "prob")

cross.randomforest.test$predicted_category <- predict.purpose.forest.2016
cross.randomforest.test$probability <- predict.prob.purpose.forest.2016
confusionMatrix(predict.purpose.forest.2016, reference = cross.randomforest.test$verified_purpose) #accuracy = 91% excluding train set

##prediction checking
predict.purpose.forest.2016.all <- predict(purpose.forest.2016, cross.randomforest)
predict.prob.purpose.forest.2016.all <- predict(purpose.forest.2016, cross.randomforest, "prob")

cross.randomforest.all <- cross.randomforest
cross.randomforest.all$predicted_category <- predict.purpose.forest.2016.all
cross.randomforest.all$probability <- predict.prob.purpose.forest.2016.all
confusionMatrix(predict.purpose.forest.2016.all, reference = cross.randomforest$verified_purpose) #accuracy = 97% including train set
write.csv(cross.randomforest.all, "orig_verif_predict_cross_all.csv", row.names = FALSE) #prediction for all verified line items

##importing and merging files for 2015
orig.2015 <- read.csv('original_2015_line_items.csv')
orig.2015 <- unique(orig.2015)

reviewed.2015 <- read.csv('reviewed_2015_line_items.csv')
reviewed.2015 <- unique(reviewed.2015)

cross.2015 <- merge(reviewed.2015,orig.2015,by = c('frn_complete'))
cross.2015 <- unique(cross.2015)

##creating variables for 2015
cross.2015$orig_purpose <-   ifelse(as.character(cross.2015$internet_conditions_met.y) == 'true', 'Internet',
                                    ifelse(as.character(cross.2015$upstream_conditions_met.y) == 'true', 'Upstream', 
                                           ifelse(as.character(cross.2015$wan_conditions_met.y) == 'true', 'WAN', 
                                                  ifelse(as.character(cross.2015$isp_conditions_met.y) == 'true', 'ISP', 'Unknown'))))
cross.2015$reviewed_purpose <-   ifelse(cross.2015$internet_conditions_met.x == 'true', 'Internet',
                                    ifelse(cross.2015$upstream_conditions_met == 'true', 'Upstream', 
                                           ifelse(cross.2015$wan_conditions_met.x == 'true', 'WAN', 
                                                  ifelse(cross.2015$isp_conditions_met.x == 'true', 'ISP', 'Unknown'))))
cross.2015$rec_elig_cost <- as.numeric(cross.2015$raw_rec_elig_cost)
cross.2015$one_time_elig_cost <- as.numeric(cross.2015$raw_one_time_eligible_cost)

cross.2015$num_lines <- as.character(cross.2015$num_lines)
cross.2015$num_lines <- as.integer(cross.2015$num_lines)
cross.2015$cost_per_circuit <- (cross.2015$rec_elig_cost+(cross.2015$one_time_elig_cost/12))/cross.2015$num_lines
cross.2015$cost_per_mbps <- cross.2015$cost_per_circuit/cross.2015$bandwidth_in_mbps

cross.2015 <- cross.2015[is.finite(cross.2015$cost_per_circuit),]

cross.2015$category <-  ifelse( grepl('Electric', as.character(cross.2015$category)), 'Electric', as.character(cross.2015$category))
cross.2015$category <-  ifelse( grepl('State', as.character(cross.2015$category)), 'State Network / REN', as.character(cross.2015$category))
cross.2015$category <-  ifelse( cross.2015$category=='Enterprise', 'Other', as.character(cross.2015$category))
cross.2015$category <- as.factor(cross.2015$category)

#cross.2015 <- cross.2015[cross.2015$orig_purpose != 'Unknown',]
#include if running for 2016, exclude if running for 2016
cross.2015 <- cross.2015[cross.2015$applicant_type != 'No data',]
cross.2015$applicant_type.y <- droplevels(cross.2015$applicant_type)
cross.2015$recipient_schools <- ifelse(is.na(cross.2015$recipient_schools),0,cross.2015$recipient_schools)
cross.2015$count_recipient_districts <- ifelse(is.na(cross.2015$count_recipient_districts),0,cross.2015$count_recipient_districts)
cross.2015$recipient_schools_per_district <- ifelse(cross.2015$count_recipient_districts==0,0,
                                                    as.integer(cross.2015$recipient_schools/cross.2015$count_recipient_districts))

cross.2015$category<-factor(cross.2015$category, levels=levels(cross.randomforest.train$category))
cross.2015$orig_purpose<-factor(cross.2015$orig_purpose, levels=levels(cross.randomforest.train$orig_purpose))
cross.2015$applicant_type.y<-factor(cross.2015$applicant_type.y, levels=levels(cross.randomforest.train$applicant_type.y))
cross.2015$connect_category.y<-factor(cross.2015$connect_category, levels=levels(cross.randomforest.train$connect_category.y))
cross.2015$isp_indicator<-factor(cross.2015$isp_indicator, levels=levels(cross.randomforest.train$isp_indicator))
cross.2015$wan_indicator<-factor(cross.2015$wan_indicator, levels=levels(cross.randomforest.train$wan_indicator))
cross.2015$upstream_indicator<-factor(cross.2015$upstream_indicator, levels=levels(cross.randomforest.train$upstream_indicator))
cross.2015$connect_type.y <- factor(cross.2015$raw_connect_type.x, levels=levels(cross.randomforest.train$connect_type.y))

cross.2015$bandwidth_in_mbps.y <- cross.2015$bandwidth_in_mbps
cross.2015$num_lines.y <- cross.2015$num_lines

##prediction checking
predict.purpose.forest.2015.all <- predict(purpose.forest.2016, cross.2015)
predict.prob.purpose.forest.2015.all <- predict(purpose.forest.2016, cross.2015, "prob")

cross.2015$predicted_purpose <- predict.purpose.forest.2015.all
cross.2015$probability_purpose <- predict.prob.purpose.forest.2015.all
cross.2015$purpose_same <- as.character(cross.2015$orig_purpose) == as.character(cross.2015$predicted_purpose)
write.csv(cross.2015, "orig_verif_predict_cross_all_2015.csv", row.names = FALSE) #prediction for all verified line items

##importing and merging files for 2016
# orig.2016 <- read.csv('ml_2016_staging.csv')
# orig.2016 <- unique(orig.2016)
# str(orig.2016)
# 
# ##creating variables for 2016
# orig.2016$orig_purpose <-   ifelse(orig.2016$internet_conditions_met == 'true', 'Internet',
#                                ifelse(orig.2016$upstream_conditions_met == 'true', 'Upstream', 
#                                       ifelse(orig.2016$wan_conditions_met == 'true', 'WAN', 
#                                              ifelse(orig.2016$isp_conditions_met == 'true', 'ISP', 'Unknown'))))
# orig.2016$rec_elig_cost <- as.numeric(orig.2016$rec_elig_cost)
# orig.2016$one_time_elig_cost <- as.numeric(orig.2016$one_time_elig_cost)
# 
# orig.2016$num_lines <- as.character(orig.2016$num_lines)
# orig.2016$num_lines <- as.integer(orig.2016$num_lines)
# orig.2016$cost_per_circuit <- (orig.2016$rec_elig_cost+(orig.2016$one_time_elig_cost/12))/orig.2016$num_lines
# orig.2016$cost_per_mbps <- orig.2016$cost_per_circuit/orig.2016$bandwidth_in_mbps
# 
# orig.2016 <- orig.2016[is.finite(orig.2016$cost_per_circuit),]
# 
# orig.2016$category <-  ifelse( grepl('Electric', as.character(orig.2016$category)), 'Electric', as.character(orig.2016$category))
# orig.2016$category <-  ifelse( grepl('State', as.character(orig.2016$category)), 'State Network / REN', as.character(orig.2016$category))
# orig.2016$category <-  ifelse( orig.2016$category=='Enterprise', 'Other', as.character(orig.2016$category))
# orig.2016$category <- as.factor(orig.2016$category)
# 
# orig.2016$connect_category.y <-  ifelse(orig.2016$connect_category == 'Other/Uncategorized', 'Other / Uncategorized', as.character(orig.2016$connect_category) )
# orig.2016$connect_category.y <- as.factor(orig.2016$connect_category.y)
# orig.2016$orig_purpose <- as.factor(orig.2016$orig_purpose)
# orig.2016 <- orig.2016[orig.2016$orig_purpose != 'Unknown',]
# orig.2016 <- orig.2016[orig.2016$applicant_type != 'No data',]
# orig.2016$applicant_type.y <- droplevels(orig.2016$applicant_type)
# orig.2016$recipient_schools <- ifelse(is.na(orig.2016$recipient_schools),0,orig.2016$recipient_schools)
# orig.2016$count_recipient_districts <- ifelse(is.na(orig.2016$count_recipient_districts),0,orig.2016$count_recipient_districts)
# orig.2016$recipient_schools_per_district <- ifelse(orig.2016$count_recipient_districts==0,0,
#                                                    as.integer(orig.2016$recipient_schools/orig.2016$count_recipient_districts))
# 
# orig.2016$category<-factor(orig.2016$category, levels=levels(cross.randomforest.train$category))
# orig.2016$orig_purpose<-factor(orig.2016$orig_purpose, levels=levels(cross.randomforest.train$orig_purpose))
# orig.2016$applicant_type.y<-factor(orig.2016$applicant_type.y, levels=levels(cross.randomforest.train$applicant_type.y))
# orig.2016$connect_category.y<-factor(orig.2016$connect_category.y, levels=levels(cross.randomforest.train$connect_category.y))
# orig.2016$isp_indicator<-factor(orig.2016$isp_indicator, levels=levels(cross.randomforest.train$isp_indicator))
# orig.2016$wan_indicator<-factor(orig.2016$wan_indicator, levels=levels(cross.randomforest.train$wan_indicator))
# orig.2016$upstream_indicator<-factor(orig.2016$upstream_indicator, levels=levels(cross.randomforest.train$upstream_indicator))
# 
# orig.2016$bandwidth_in_mbps.y <- orig.2016$bandwidth_in_mbps
# orig.2016$num_lines.y <- orig.2016$num_lines
# 
# orig.2016.short <- orig.2016[,c("category","orig_purpose","applicant_type.y",
#                        "isp_indicator","wan_indicator","upstream_indicator",
#                        "bandwidth_in_mbps.y","recipient_schools", "connect_category.y",
#                        "num_lines.y", "cost_per_circuit", "cost_per_mbps", "recipient_schools_per_district",
#                        "count_recipient_districts", "frn", "frn_line_item_no", "num_open_flags")]
# write.csv(orig.2016.short, "orig_2016.csv", row.names = FALSE)
# 
# 
# ##prediction checking for 2016
# predict.purpose.forest.2016.data <- predict(purpose.forest.2016, orig.2016.short)
# predict.prob.purpose.forest.2016.data <- predict(purpose.forest.2016, orig.2016.short, "prob")
# 
# orig.2016.short$predicted_category <- predict.purpose.forest.2016.data
# orig.2016.short$probability <- predict.prob.purpose.forest.2016.data
# write.csv(orig.2016.short, "orig_2016_predict.csv", row.names = FALSE)
