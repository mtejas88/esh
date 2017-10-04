## clear memory
rm(list=ls())

## load packages


## read in data
campus <- read.csv("data/campus.csv", as.is=T, header=T, stringsAsFactors=F)

applied_received <- read.csv("data/applied_received.csv", as.is=T, header=T, stringsAsFactors=F)