## ==============================================
##
## Boys and Girls Club Analysis
## 
## OBJECTIVES:
##    -- Determine school level circuit determinations
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/")

## load the package into your environment (you need to do this for each script)
library(dplyr)

## read in data 
schools_bgca <- read.csv("data/processed/schools_bgca.csv", as.is=T, header=T)
campus_mapping <- read.csv("data/interim/campus_mapping.csv", as.is=T, header=T)
campuses <- read.csv("data/interim/campuses.csv", as.is=T, header=T)

schools_bgca_campus <- left_join(schools_bgca, campus_mapping, 
                                 by = c("NCES.School.ID" = "school_nces_code"))
schools_bgca_campus <- left_join(schools_bgca_campus, campuses, 
                                 by = c("campus_id" = "campus_id", "NCES.District.ID" = "nces_cd"))

##write joined dataset for bgca
write.table(schools_bgca_campus, 
            "data/processed/schools_bgca_campuses.csv", 
            col.names=TRUE, row.names = FALSE,
            sep=",")

#campus_fiber_lines_alloc > 0 means they have fiber
#campus_nonfiber_lines_alloc > 0 means they have nonfiber
#campus_nonfiber_lines_w_dirty = 0 and campus_fiber_lines > 0 means likely fiber
#campus_nonfiber_lines > 0 means likely nonfiber
#otherwise unknown
