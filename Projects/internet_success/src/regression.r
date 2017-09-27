## REGRESSION

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
tx_data <- read.csv("data/tx_data.csv", as.is=T, header=T, stringsAsFactors=F)

## load packages
library(caTools)

str(tx_data)

## set a seed
set.seed(101)

sample <- sample.split(tx_data$grad_percent_change, SplitRatio = .7)

train <- subset(tx_data,sample == TRUE)

test <- subset(tx_data,sample == FALSE)

modelA <- lm(grad_percent_change ~ num_students + num_schools + num_campuses + district_size +
               locale + frl_percent + percent_bw_per_student_change, data = train)

print(summary(modelA))




