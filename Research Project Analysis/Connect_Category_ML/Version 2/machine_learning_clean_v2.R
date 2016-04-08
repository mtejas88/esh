# Importing data and setting the current working directory.
# install.packages('caret', dependencies = TRUE)
library(class)
library(caret)
library(dplyr)
# install.packages('sqldf')
library(sqldf)
library(randomForest)
# install.packages('rfUtilities')
library(rfUtilities)
# install.packages('randomForestSRC')
library(randomForestSRC)
# install.packages('caret')



setwd("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/Version 3")

raw_lis <- read.csv("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/original_line_items.csv")
# View(raw_lis)

verified_lis <- read.csv("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/verified_line_items_real_v2.csv")
# View(verified_lis)

# Inner join both datasets
joined <- merge(raw_lis, verified_lis, by.x=c("frn_complete"), by.y=c("frn_complete"))
View(joined)

# Begin filtering out nulls. (filtering our NA's could introduce bias too, 
# so we want to be careful here about how we handle missing values.)
unique(is.na(joined$bandwidth_in_mbps.x))
nrow(joined)
joined <- joined[!is.na(joined$bandwidth_in_mbps.x),]
nrow(joined)

unique(is.na(joined$num_students.x))
joined <- joined[!is.na(joined$num_students.x),]
nrow(joined)

unique(is.na(joined$num_of_services))
joined <- joined[!is.na(joined$num_of_services),]
nrow(joined) # 2352 Observations before splitting

### Translate into current ML work ###

data.size <- nrow(joined)
train.size <- round(data.size *.8, 0)
test.size <- data.size - train.size
training_id_integers <- sample(data.size, train.size)


# Works which is great, might introduce unexpected biases though. Could be better to random sample as an optmization. ( Maybe line items from the lowest 80%
# line_item_id's in our data size are associated with a particular states. We'd want to make it random to get a fair training set across a lot of different states)

train_data <- joined[training_id_integers,]
test_data <- joined[-training_id_integers,]
nrow(train_data) # 1882 to train with
nrow(test_data) # 470 Observations for testing
# View(train_data)

### Creating Random Forest Model, with 9 variables ###

connect.forest <- randomForest(as.factor(connect_category.y) ~ bandwidth_in_mbps.x + cost_per_line.y 
                               + num_students.y + num_of_services 
                               + highest_connect_type + providers_typical_category 
                               + free_and_reduced + copper_line + consultants_typical_category, data=train_data, importance=T, ntree=501)

connect.forest$importance
varImpPlot(connect.forest)
predict.forest <- predict(connect.forest, test_data)

### Showing results:
results <- data.frame(verified_category = test_data$connect_category.y, predicted_category = predict.forest, raw_category = test_data$connect_category.x, test_data$frn_complete)
results$guessed_correctly <- results$verified_category == results$predicted_category
results$clean_the_line_item <- (results$verified_category == results$predicted_category) & (results$predicted_category != results$raw_category)


View(results)
confusionMatrix(predict.forest, reference=test_data$connect_category.y)


