## REGRESSION

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
tx_data <- read.csv("data/tx_data.csv", as.is=T, header=T, stringsAsFactors=F)

rm_outliers_2 <- read.csv("data/rm_outliers_2.csv", as.is=T, header=T, stringsAsFactors=F)

rm_outliers_3 <- read.csv("data/rm_outliers_3.csv", as.is=T, header=T, stringsAsFactors=F)

## load packages
library(caTools)

str(tx_data)

## set a seed
set.seed(101)

## all data
sample <- sample.split(tx_data$grad_percent_change, SplitRatio = .7)
train <- subset(tx_data,sample == TRUE)
test <- subset(tx_data,sample == FALSE)

## 2 st dev from mean
sample <- sample.split(rm_outliers_2$grad_percent_change, SplitRatio = .7)
train_2 <- subset(rm_outliers_2,sample == TRUE)
test_2 <- subset(rm_outliers_2,sample == FALSE)

## 3 st dev from mean
sample <- sample.split(rm_outliers_3$grad_percent_change, SplitRatio = .7)
train_3 <- subset(rm_outliers_3,sample == TRUE)
test_3 <- subset(rm_outliers_3,sample == FALSE)

## -- MODEL A -- frl percent + percent bw per student

## model using all data where frl_percent is significant and positive 
model_a <- lm(grad_percent_change ~ frl_percent + percent_bw_per_student_change, data = train)
summary(model_a)

## data limited to 2 st dev frl_percent is no longer significant
model2_a <- lm(grad_percent_change ~ frl_percent + percent_bw_per_student_change, data = train_2)
summary(model2_a)

## data limited to 3 st dev frl_percent is no longer significant
model3_a <- lm(grad_percent_change ~ frl_percent + percent_bw_per_student_change, data = train_3)
summary(model3_a)

## -- OTHER MODELS --

## one of the models I tried where intercept was also significant and negative
modelB <- lm(grad_percent_change ~ num_students + num_schools +
               locale + frl_percent + percent_bw_per_student_change, data = train)





##variables to choose

num_students
num_schools
locale
ulocal
frl_percent
student_teacher_ratio
num_teachers
percent_c2_budget_used
percent_bw_per_student_change
percent_bw_change



