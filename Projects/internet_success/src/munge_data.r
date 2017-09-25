## MUNGE DATA

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
broadband_data <- read.csv("data/broadband_data.csv", as.is=T, header=T, stringasAsFactors=F)

## external data add later

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



