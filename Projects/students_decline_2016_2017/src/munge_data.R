## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

dd_2016 <- read.csv("../data/interim/dd_2016.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2017 <- read.csv("../data/interim/dd_2017.csv", as.is=T, header=T, stringsAsFactors=F)
schools_demog <- read.csv("../data/interim/schools_demog.csv", as.is=T, header=T, stringsAsFactors=F)
sfdc <- read.csv("../data/interim/sfdc.csv", as.is=T, header=T, stringsAsFactors=F)

#filter for changes before the data freeze
library(dplyr)
sfdc$Updated.Date = as.Date(sfdc$Updated.Date)
sfdc = sfdc %>% filter(Updated.Date < "2017-08-14")
length(unique(sfdc$Facility.ESHID)) # 2458
unique_facilities = as.data.frame(unique(sfdc[, c("Facility.ESHID")]))
names(unique_facilities) = c("Facility.ESHID")

## merge sfdc modified facilities with schools demog
  # schools
sfdc_s=merge(x = unique_facilities, 
             y = schools_demog[ , c("district_esh_id", "school_esh_id")], 
             by.x = "Facility.ESHID", by.y="school_esh_id")


## merge above dataset with 2017 districts
modified_districts=merge(x = sfdc_s, 
             y = dd_2017, 
             by.x = "district_esh_id", by.y="esh_id")

## determine # of lost students 
  ## merge with 2016
  modified_districts_all=merge(x = modified_districts, 
                         y = dd_2016, 
                         by.x = "district_esh_id", by.y="esh_id")
## deduplicate
  modified_districts_all=as.data.frame(
    unique(modified_districts_all[,c("district_esh_id","num_students.x","num_students.y" )]))

  ## 2017 students
  sum(modified_districts_all$num_students.x) #4603523
  ## 2016 students
  sum(modified_districts_all$num_students.y) #4796402
  
  #diff
  4796402 - 4603523
  #192,879