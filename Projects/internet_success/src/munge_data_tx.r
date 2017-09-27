## MUNGE DATA

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
broadband_data <- read.csv("data/broadband_data.csv", as.is=T, header=T, stringsAsFactors=F)

tx_16 <- read.csv("data/external/tx_2016.csv", as.is = T, header = T, stringsAsFactors = F)
tx_15 <- read.csv("data/external/tx_2015.csv", as.is = T, header = T, stringsAsFactors = F)
tx_nces_num <- read.csv("data/external/tx_nces_num.csv", as.is = T, header = T, stringsAsFactors = F)

## load packages
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv","dplyr","secr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)
library(dplyr)
library(secr)

## limiting graduation rates calculated for federal accountability purposes and not state accountability 
tx_16 <- tx_16[which(tx_16$CALC_FOR_STATE_ACCT=="No"),]
tx_15 <- tx_15[which(tx_15$CALC_FOR_STATE_ACCT=="No"),]

## limiting to necessary data fields - DIST_ALLR_GRAD = "District all students graduation rate" 
tx_16 <- tx_16[,c("DISTRICT","DISTNAME","DIST_ALLR_GRAD")]
tx_15 <- tx_15[,c("DISTRICT","DISTNAME","DIST_ALLR_GRAD")]

## renaming graduation rates to be unique
colnames(tx_16)[3] <- "grad_rate_16"
colnames(tx_15)[3] <- "grad_rate_15"

## merging grad data
tx_grad <- merge(tx_15,tx_16)

## calc percent change from 2015 to 2016
tx_grad$grad_percent_change <- (tx_grad$grad_rate_16 - tx_grad$grad_rate_15)/tx_grad$grad_rate_15

## merge in TX district info to get NCES 
tx_grad <- merge(tx_nces_num[,c("DISTRICT_C","NCES_DISTR")],tx_grad, by.x = "DISTRICT_C", by.y = "DISTRICT")


## merge in broadband data 
tx_data <- merge(tx_grad,broadband_data, by.x="NCES_DISTR", by.y= "nces_cd")

## check that they're aren't any nulls
any(is.na(tx_data))

summary(tx_data)

tx_data[is.na(tx_data$frl_percent),]

# removing district with NA for frl_percent
tx_data <- tx_data[is.na(tx_data$frl_percent)==FALSE,]

any(is.na(tx_data))


## write out
write.csv(tx_data, "data/tx_data.csv", row.names = FALSE)

