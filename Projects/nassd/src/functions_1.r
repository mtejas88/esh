## clear memory
rm(list=ls())

## read in data
setwd("~/GitHub/ficher/Projects/nassd")
#dd_union <- read.csv("data/dd_union.csv", as.is=T, header=T, stringsAsFactors=F)

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

#data <- dd_union[which(dd_union$year == 2016),]
#data$metric <- data$meeting_2014_goal_no_oversub
#data_sub <- data[which(data$metric >= 0),]


metric_overall <- function(data,data_sub){

  # Population
  
  population_district <- length(data$esh_id)
  population_campuses <- sum(data$num_campuses)
  population_schools <- sum(data$num_schools)
  population_students <- sum(data$num_students)
  
  pop_df <- data_frame(population_district,population_campuses,population_schools,population_students)
  
  # Subset to Metric
  
  A <- aggregate(esh_id ~ metric, data = data_sub, FUN = length)
  colnames(A)[2] <- "districts"
  B <- aggregate(num_campuses ~ metric, data = data_sub, FUN = sum)
  colnames(B)[2] <- "campuses"
  C <- aggregate(num_schools ~ metric, data = data_sub, FUN = sum)
  colnames(C)[2] <- "schools"
  D <- aggregate(num_students ~ metric, data = data_sub, FUN = sum)
  colnames(D)[2] <- "students"
  
  metric_df <- merge(A,B)
  metric_df <- merge(metric_df,C)
  metric_df <- merge(metric_df,D)
  
  # Sum the subset to get sample totals
  
  metric_df$sample_districts <- sum(metric_df$districts)
  metric_df$sample_campuses <- sum(metric_df$campuses)
  metric_df$sample_schools <- sum(metric_df$schools)
  metric_df$sample_students <- sum(metric_df$students)
  
  # Merge in population data
  metric_df <- merge(metric_df,pop_df)
  
  # Calculate percents
  metric_df$percent_districts <- (metric_df$districts/metric_df$sample_districts)
  metric_df$percent_campuses <- (metric_df$campuses/metric_df$sample_campuses)
  metric_df$percent_schools <- (metric_df$schools/metric_df$sample_schools)
  metric_df$percent_students <- (metric_df$students/metric_df$sample_students)
  
  # Extrapolate
  metric_df$extrap_districts <- metric_df$percent_districts*metric_df$population_district
  metric_df$extrap_campuses <- metric_df$percent_campuses*metric_df$population_campuses
  metric_df$extrap_schools <- metric_df$percent_schools*metric_df$population_schools
  metric_df$extrap_students <- metric_df$percent_students*metric_df$population_students
  
  #rm(population_district,population_campuses,population_schools,population_students,pop_df,A,B,C,D)
  print(metric_df)
}



metric_group <- function(data,data_sub){
  
  #Population within each group
  
  A <- aggregate(esh_id ~ group, data = data, FUN = length)
  colnames(A)[2] <- "population_districts"
  B <- aggregate(num_campuses ~ group, data = data, FUN = sum)
  colnames(B)[2] <- "population_campuses"
  C <- aggregate(num_schools ~ group, data = data, FUN = sum)
  colnames(C)[2] <- "population_schools"
  D <- aggregate(num_students ~ group, data = data, FUN = sum)
  colnames(D)[2] <- "population_students"
  
  pop_df <- merge(A,B)
  pop_df <- merge(pop_df,C)
  pop_df <- merge(pop_df,D)
  
  # Subset to Metric x Group
  
  A <- aggregate(esh_id ~ group + metric, data = data_sub, FUN = length)
  colnames(A)[3] <- "districts"
  B <- aggregate(num_campuses ~ group + metric, data = data_sub, FUN = sum)
  colnames(B)[3] <- "campuses"
  C <- aggregate(num_schools ~ group + metric, data = data_sub, FUN = sum)
  colnames(C)[3] <- "schools"
  D <- aggregate(num_students ~ group + metric, data = data_sub, FUN = sum)
  colnames(D)[3] <- "students"
  
  group_metric_df <- merge(A,B)
  group_metric_df <- merge(group_metric_df,C)
  group_metric_df <- merge(group_metric_df,D)
  
  # Sum the subset to get sample totals
  A <- aggregate(districts ~ group, data = group_metric_df, FUN = sum)
  colnames(A)[2] <- "sample_districts"
  B <- aggregate(campuses ~ group, data = group_metric_df, FUN = sum)
  colnames(B)[2] <- "sample_campuses"
  C <- aggregate(schools ~ group, data = group_metric_df, FUN = sum)
  colnames(C)[2] <- "sample_schools"
  D <- aggregate(students ~ group, data = group_metric_df, FUN = sum)
  colnames(D)[2] <- "sample_students"
  
  sample_df <- merge(A,B)
  sample_df <- merge(sample_df,C)
  sample_df <- merge(sample_df,D)
  
  ## merge in sample
  group_metric_df <- merge(group_metric_df,sample_df)
  
  ## merge in population
  group_metric_df <- merge(group_metric_df,pop_df)
  
  ## Calculate percents
  group_metric_df$percent_districts <- (group_metric_df$districts/group_metric_df$sample_districts)
  group_metric_df$percent_campuses <- (group_metric_df$campuses/group_metric_df$sample_campuses)
  group_metric_df$percent_schools <- (group_metric_df$schools/group_metric_df$sample_schools)
  group_metric_df$percent_students <- (group_metric_df$students/group_metric_df$sample_students)
  
  ## Extrapolate
  group_metric_df$extrap_districts <- group_metric_df$percent_districts*group_metric_df$population_district
  group_metric_df$extrap_campuses <- group_metric_df$percent_campuses*group_metric_df$population_campuses
  group_metric_df$extrap_schools <- group_metric_df$percent_schools*group_metric_df$population_schools
  group_metric_df$extrap_students <- group_metric_df$percent_students*group_metric_df$population_students
  
  #rm(A,B,C,D,pop_df,sample_df)  
  print(group_metric_df)
}

  



