## ==============================================
##
## Boys and Girls Club Analysis
## 
## OBJECTIVES:
##    -- Compare BandG with fiber and bw targets
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/")

## load the package into your environment (you need to do this for each script)
library(dplyr)

## read in data 
districts <- read.csv("data/interim/districts.csv", as.is=T, header=T)
schools_bgca <- read.csv("data/external/BGCA_School_Sites_NCES_Identified.csv", as.is=T, header=T)

districts <- select(districts, nces_cd, fiber_target_status, bw_target_status)

schools_upd <- inner_join(schools_bgca, districts, 
                        by = c("NCES.District.ID" = "nces_cd"))

write.table(schools_upd, 
            "data/processed/schools_bgca.csv", 
            col.names=TRUE, row.names = FALSE,
            sep=",")

schools_upd %>%
  group_by(fiber_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
schools_upd %>%
  group_by(bw_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
schools_upd %>%
  group_by(bw_target_status, fiber_target_status) %>%
  summarize(schools = n(),
            districts = n_distinct(NCES.District.ID))
