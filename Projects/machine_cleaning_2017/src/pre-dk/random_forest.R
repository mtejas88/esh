## ==========================================================================
##
## RANDOM FOREST: run the classifier model, using OOB error estimate
##
## ==========================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("caret", "randomForest")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(caret)
library(randomForest)

##**************************************************************************************************************************************************
## READ IN DATA

dta.ml <- read.csv("data/interim/ml_connect_type_2016.csv", as.is=T, header=T)

##**************************************************************************************************************************************************

## need to recast character variables to factors as they do not hold when you write them out to csv and read them back in
character_vars <- lapply(dta.ml, class) == "character"
dta.ml[,character_vars] <- lapply(dta.ml[,character_vars], as.factor)

## NOTE: no need to split into train/test datasets since randomForest package uses out-of-bag (OOB) error estimates
## by growing trees on two thirds and testing on one third of the data. So you should use the whole dataset.
## split both datasets into train and test (66% and 34%)
#set.seed(310)
#num.train <- floor(.66*nrow(dta.ml))
#sample.rows <- sample(nrow(dta.ml), num.train)
#dta.train <- dta.ml[sample.rows,]
#dta.test <- dta.ml[-sample.rows,]
dta.train <- dta.ml


## Random Forest -- Conditional Inference Trees
##-----------------------------------------------
set.seed(111)
system.time(
  ## use randomForest(predictors, decision) vs randomForest(decision~., data=input) to speed up time
  ## ntree specifies the number of trees, picking an odd number helps break ties
  ## do.trace=TRUE prints the trees to screen
  ## importance=TRUE allows us to inspect variable importance
  ## note: mtry doesn't usually need to be changed as the default is the square root of the number of all variables, which is fine
  rforrest <- randomForest(dta.train[,which(!names(dta.train) %in% c("class"))], dta.train[,"class"], ntree=1001, do.trace=TRUE, importance=TRUE)
)
pdf("figures/num_trees_by_error.pdf", height=5, width=5)
plot(rforrest, main="Error Rate by Number of Trees")
dev.off()

## variable importance
(VI_F=importance(rforrest))
pdf("figures/variable_importance.pdf", height=12, width=14)
## represents the mean decrease in node impurity
varImpPlot(rforrest, pch=16, color=rgb(0,0,0,0.7), main="Variable Rank")
dev.off()

summary(rforrest)

save.image(file="rf_connect_category_ntree_1001.RData")


## Precision is a measure of how on point the classification is. For instance, out of all the
## positive matches the model finds, how many of them were correct?
## Precision = True Positives / (True Positives + False Positives)

## Recall can be thought of as the sensitivity of the model. It is a measure of whether all
## the relevant instances were actually looked at.
## Recall = True Positives / (True Positives + False Negatives)

## Accuracy as we know it is simply an error rate of the model.
## How well does it do in aggregate?
## Accuracy = (True Positives + True Negatives) / (Number of all responses)
