## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app")

## load the package into your environment (you need to do this for each script)
library(dplyr)
library(elrm)

## read in data 
lowcost_applications <- read.csv("data/interim/lowcost_applications.csv", as.is=T, header=T)

## elrm regression  
x <- xtabs(~denied_indicator + interaction(no_consultant_indicator, category_2), data = lowcost_applications)
cdat <- data.frame(category_2 = rep(0:1, 2), no_consultant_indicator = rep(0:1, each = 2),
                   denied_indicator = x[2, ], ntrials = colSums(x))

regr <- elrm(formula = denied_indicator/ntrials ~ no_consultant_indicator + category_2, 
             interest = ~no_consultant_indicator+ category_2, 
             iter = 5050000, dataset = cdat, burnIn = 5000, r=2)
summary(regr)
