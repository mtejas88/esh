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
# install.packages("RPostgreSQL")
# require("RPostgreSQL")


# loads the PostgreSQL driver



setwd("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/Version 4")



verified_lis <- read.csv("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/Version 4/verified_line_items_v4.csv")

raw_lis <- read.csv("~/Desktop/ESH/ficher/Research Project Analysis/Connect_Category_ML/Version 4/original_line_items_v4.csv")

nrow(verified_lis)
summary(verified_lis)
# View(verified_lis)

# left join both datasets
joined = merge(x = raw_lis, y = verified_lis, by = 'frn_complete', all.x = TRUE)


compacted_joined <- joined[, c('connect_category.y', 'connect_category.x', 'frn_complete', 'bandwidth_in_mbps.x', 'consultant_app', 'consultant_app', 'cost_per_line', 'num_students.x', 'num_of_services',
                               'highest_connect_type', 'providers_typical_category', 'free_and_reduced', 'copper_line', 'consultants_cat', 
                               'upstream_conditions_met.x', 'isp_conditions_met.x', 'ia_circuit_only', 
                               'wireless_service', 'wan_fiber_3_lines', 'likely_wan_fiber', 'exception_not_fiber', 'likely_other_uncategorized')]


# Begin filtering out nulls. (filtering our NA's could introduce bias too, 
# so we want to be careful here about how we handle missing values.)
# View(compacted_joined)
nrow(compacted_joined)
 
summary(compacted_joined)


compacted_joined <- na.omit(compacted_joined)


nrow(compacted_joined) # 6519 Observations before splitting

### Translate into current ML work ###

data.size <- nrow(compacted_joined)
train.size <- round(data.size *.8, 0)
test.size <- data.size - train.size
training_id_integers <- sample(data.size, train.size)


# Works which is great, might introduce unexpected biases though. Could be better to random sample as an optmization. ( Maybe line items from the lowest 80%
# line_item_id's in our data size are associated with a particular states. We'd want to make it random to get a fair training set across a lot of different states)

train_data <- compacted_joined[training_id_integers,]
test_data <- compacted_joined[-training_id_integers,]
nrow(train_data) # 5215 to train with
nrow(test_data) # 1304 Observations for testing
# View(train_data)

### Creating Random Forest Model, with 18 variables ###
connect.forest <- randomForest(as.factor(connect_category.y) ~ bandwidth_in_mbps.x + consultant_app + consultants_cat
                               + cost_per_line + num_students.x + num_of_services + highest_connect_type 
                               + providers_typical_category + free_and_reduced + copper_line + upstream_conditions_met.x
                               + isp_conditions_met.x + ia_circuit_only + wireless_service + wan_fiber_3_lines
                               + likely_wan_fiber + exception_not_fiber + likely_other_uncategorized,
                                data=train_data, importance=T, ntree=501)

connect.forest$importance
varImpPlot(connect.forest)
predict.forest <- predict(connect.forest, test_data)

### Showing results:
results <- data.frame(verified_category = test_data$connect_category.y, predicted_category = predict.forest, raw_category = test_data$connect_category.x, test_data$frn_complete)

results$guessed_correctly <- results$verified_category == results$predicted_category

# clean up factors issue

View(results)
confusionMatrix(predict.forest, reference=test_data$connect_category.y)


