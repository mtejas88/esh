## =========================================
##
## QA
##
## =========================================

## Clearing memory
rm(list=ls())

## READ IN DATA
form_470_numbers_for_districts_in_universe <- read.csv("data/raw/form_470_numbers_for_districts_in_universe.csv", as.is=T, header=T, stringsAsFactors=F)
joe_f.2017 <- read.csv("data/interim/joe_f.2017.csv", as.is=T, header=T, stringsAsFactors=F)

names(form_470_numbers_for_districts_in_universe)

#joining form 470s to joe's data
new_joe_f.2017 <- merge(x = joe_f.2017, y = form_470_numbers_for_districts_in_universe, by.x = 'form_470', by.y = "X470.Number")

sum(new_joe_f.2017$Estimated.Special.construction, na.rm = T)
