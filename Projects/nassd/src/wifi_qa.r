## =========================================
## 
## NASSD QA
##
## =========================================

## clear memory
rm(list=ls())

## read in data
setwd("~/GitHub/ficher/Projects/nassd")
dd_union <- read.csv("data/dd_union.csv", as.is=T, header=T, stringsAsFactors=F)

## load packages (if not already in the environment) 
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
## not sure which if any are necessary, come back later


## subset data - need to subset to single year at a minimum, 
## can also subset to postal_cd and/or additional district classifications e.g. only looking at Megas & Larges
dd_union_sub <- dd_union[which(dd_union$year == 2017),]

# define district classification you will be dimensioning by. e.g. locale or district_size
# this is you can easily switch between different categories without having to replace the columns names

dd_union_sub$group <- dd_union_sub$fiber_target_status

## =========================================
## 
## POPULATION
##
## =========================================

## How many districts, campuses, schools, and students in subset population?

population_district <- length(dd_union_sub$esh_id)
population_campuses <- sum(dd_union_sub$num_campuses)
population_schools <- sum(dd_union_sub$num_schools)
population_students <- sum(dd_union_sub$num_students)

# merge into dataframe
pop <- data_frame(population_district,population_campuses,population_schools,population_students)

pop <- merge(population_district, population_campuses, population_schools,population_students)

## How many districts, campuses, schools, and students in subset population across group?
pop_districts_group <- aggregate(esh_id ~ group, data = dd_union_sub, FUN = length)
colnames(pop_districts_group)[2] <- "population_district"

pop_campuses_group <- aggregate(num_campuses ~ group, data = dd_union_sub, FUN = sum)
colnames(pop_campuses_group)[2] <- "population_campuses"

pop_schools_group  <- aggregate(num_schools ~ group, data = dd_union_sub, FUN = sum)
colnames(pop_schools_group)[2] <- "population_schools"

pop_students_group <- aggregate(num_students ~ group, data = dd_union_sub, FUN = sum)
colnames(pop_students_group)[2] <- "population_students"

# merge in all dataframes 
tables_to_merge <- c("pop_districts_group","pop_campuses_group","pop_schools_group","pop_students_group")
pop_group <- eval(parse(text = tables_to_merge[1]))
for (i in 2:length(tables_to_merge)){
  pop_group <- merge(pop_group, eval(parse(text = tables_to_merge[i])), by = "group")
}


## =========================================
## 
## 1. Wi-fi - Sufficiency Survey Only
##
## =========================================

#aggregate(dd_union_sub$num_students,by=list(locale = dd_union_sub$locale),FUN = sum)

## 1.1 Wifi Sufficiency Across Total Subset
## subset to districts that we have wi-fi sufficiency on 
dd_union_sub_wifi_surv <- dd_union_sub[which(dd_union_sub$needs_wifi >= 0),]

dd_union_sub_wifi_surv <- dd_union_sub[which(dd_union_sub$needs_wifi),]
 
## How many districts reported having insufficienct vs. sufficient wi-fi 
## (and how many campuses, schools, and students are in each - note: this student/campus/school methodology will likely change)

districts_wifi_surv <- aggregate(esh_id ~ needs_wifi, data = dd_union_sub_wifi_surv, FUN = length)
colnames(districts_wifi_surv)[2] <- "districts"
campuses_wifi_surv <- aggregate(num_campuses ~ needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(campuses_wifi_surv)[2] <- "campuses"
schools_wifi_surv <- aggregate(num_schools ~ needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(schools_wifi_surv)[2] <- "schools"
students_wifi_surv <- aggregate(num_students ~ needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(students_wifi_surv)[2] <- "students"
  
wifi_surv <- merge(districts_wifi_surv,campuses_wifi_surv,schools_wifi_surv)


# merge into dataframe
tables_to_merge <- c("districts_wifi_surv","campuses_wifi_surv","schools_wifi_surv","students_wifi_surv")
wifi_surv <- eval(parse(text = tables_to_merge[1]))
for (i in 2:length(tables_to_merge)){
  wifi_surv <- merge(wifi_surv, eval(parse(text = tables_to_merge[i])), by = "needs_wifi")
}

## How many districts are in the wifi survey sample/how many even reported on wi-fi
wifi_surv$sample_districts <- sum(wifi_surv$districts)
wifi_surv$sample_campuses <- sum(wifi_surv$campuses)
wifi_surv$sample_schools <- sum(wifi_surv$schools)
wifi_surv$sample_students <- sum(wifi_surv$students)

# merge in population data
wifi_surv <- cbind.data.frame(wifi_surv,pop)

#calculating percent
wifi_surv$percent_districts <- (wifi_surv$districts/wifi_surv$sample_districts)
wifi_surv$percent_campuses <- (wifi_surv$campuses/wifi_surv$sample_campuses)
wifi_surv$percent_schools <- (wifi_surv$schools/wifi_surv$sample_schools)
wifi_surv$percent_students <- (wifi_surv$students/wifi_surv$sample_students)

#extrapolating
wifi_surv$extrap_districts <- wifi_surv$percent_districts*wifi_surv$population_district
wifi_surv$extrap_campuses <- wifi_surv$percent_campuses*wifi_surv$population_campuses
wifi_surv$extrap_schools <- wifi_surv$percent_schools*wifi_surv$population_schools
wifi_surv$extrap_students <- wifi_surv$percent_students*wifi_surv$population_students

## 1.2 Wifi Sufficiency Across Subset by Group

## How many districts reported having insufficienct vs. sufficient wi-fi 
## (and how many campuses, schools, and students are in each - note: this student/campus/school methodology will likely change)

districts_wifi_surv_group <- aggregate(esh_id ~ group + needs_wifi, data = dd_union_sub_wifi_surv, FUN = length)
colnames(districts_wifi_surv_group)[3] <- "districts"
campuses_wifi_surv_group <- aggregate(num_campuses ~ group + needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(campuses_wifi_surv_group)[3] <- "campuses"
schools_wifi_surv_group <- aggregate(num_schools ~ group + needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(schools_wifi_surv_group)[3] <- "schools"
students_wifi_surv_group <- aggregate(num_students ~ group + needs_wifi, data = dd_union_sub_wifi_surv, FUN = sum)
colnames(schools_wifi_surv_group)[3] <- "students"

# merge
wifi_surv_group <- merge(districts_wifi_surv_group,campuses_wifi_surv_group)
wifi_surv_group <- merge(wifi_surv_group,schools_wifi_surv_group)
wifi_surv_group <- merge(wifi_surv_group,students_wifi_surv)

## How many districts are in the wifi survey sample/how many even reported on wi-fi across the group

sample_districts <- aggregate(districts ~ group, data = wifi_surv_group, FUN = sum)
colnames(sample_districts)[2] <- "sample_districts"
sample_campuses <- aggregate(campuses ~ group, data = wifi_surv_group, FUN = sum)
colnames(sample_campuses)[2] <- "sample_campuses"
sample_schools <- aggregate(schools ~ group, data = wifi_surv_group, FUN = sum)
colnames(sample_schools)[2] <- "sample_schools"
sample_students <- aggregate(schools ~ group, data = wifi_surv_group, FUN = sum)
colnames(sample_students)[2] <- "sample_students"

#merge in sample numbers
wifi_surv_group <- merge(wifi_surv_group, sample_districts)
wifi_surv_group <- merge(wifi_surv_group, sample_campuses)
wifi_surv_group <- merge(wifi_surv_group, sample_schools)
wifi_surv_group <- merge(wifi_surv_group, sample_students)

#merge in population numbers
wifi_surv_group <- merge (wifi_surv_group, pop_group)

#calculating percent
wifi_surv_group$percent_districts <- (wifi_surv_group$districts/wifi_surv_group$sample_districts)
wifi_surv_group$percent_campuses <- (wifi_surv_group$campuses/wifi_surv_group$sample_campuses)
wifi_surv_group$percent_schools <- (wifi_surv_group$schools/wifi_surv_group$sample_schools)
wifi_surv_group$percent_students <- (wifi_surv_group$students/wifi_surv_group$sample_students)

#extrapolating
wifi_surv_group$extrap_districts <- wifi_surv_group$percent_districts*wifi_surv_group$population_district
wifi_surv_group$extrap_campuses <- wifi_surv_group$percent_campuses*wifi_surv_group$population_campuses
wifi_surv_group$extrap_schools <- wifi_surv_group$percent_schools*wifi_surv_group$population_schools
wifi_surv_group$extrap_students <- wifi_surv_group$percent_students*wifi_surv_group$population_students
