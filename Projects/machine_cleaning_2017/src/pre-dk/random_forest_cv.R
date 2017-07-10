## ==========================================================================
##
## RANDOM FOREST: run the classifier model, using k-fold CV error estimate
##
## ==========================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("plyr", "randomForest")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(plyr)
library(randomForest)

##**************************************************************************************************************************************************
## READ IN DATA

dta.ml <- read.csv("data/interim/ml_connect_type_2016.csv", as.is=T, header=T)

##**************************************************************************************************************************************************

## need to recast character variables to factors as they do not hold when you write them out to csv and read them back in
character_vars <- lapply(dta.ml, class) == "character"
dta.ml[,character_vars] <- lapply(dta.ml[,character_vars], as.factor)

## create 10 folds for Cross Validation
k <- 10
set.seed(887)
## sample from 1 to k, nrow times (the number of observations in the data)
dta.ml$fold <- sample(1:k, nrow(dta.ml), replace = TRUE)
list <- 1:k

## initialize prediction and testset data frames that we add to with each iteration over the folds
prediction <- data.frame()
testsetCopy <- data.frame()

## Creating a progress bar to know the status of CV
progress.bar <- create_progress_bar("text")
progress.bar$init(k)

for (i in 1:k){
  ## remove rows with fold i from dataframe to create training set
  trainingset <- dta.ml[which(dta.ml$fold %in% list[-i]),]
  ## select rows with fold i to create test set
  testset <- dta.ml[which(dta.ml$fold %in% c(i)),]

  ## run a random forest model
  mymodel <- randomForest(trainingset[,which(!names(trainingset) %in% c("class"))], trainingset[,"class"], ntree=501)

  ## remove the correct class column
  temp <- as.data.frame(predict(mymodel, testset[,which(!names(trainingset) %in% c("class"))]))
  ## append this iteration's predictions to the end of the prediction data frame
  prediction <- rbind(prediction, temp)

  ## append this iteration's test set to the test set copy data frame
  ## keep only the class
  testsetCopy <- rbind(testsetCopy, as.data.frame(testset[,"class"]))

  progress.bar$step()
}

## add predictions and actual class values
result <- cbind(prediction, testsetCopy[,"class"])
names(result) <- c("Predicted", "Actual")
result$Difference <- abs(result$Actual - result$Predicted)

# As an example use Mean Absolute Error as Evalution
summary(result$Difference)
