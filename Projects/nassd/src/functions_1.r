## clear memory
rm(list=ls())

## read in data
setwd("~/GitHub/ficher/Projects/nassd")
## remove when not testing
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

## ---- 1. FUNCTION: METRIC_OVERALL ----
## PURPOSE: to calculate what percent and extrapolated number of districts, campuses, schools, and students are in the different metric groups
## NOTE: the breakdown at the campus, school, and student level might not always be relevant or "accurate" depending on methodology

metric_overall <- function(population,sample){

  # Population
  
  population_district <- length(population$esh_id)
  population_campuses <- sum(population$num_campuses)
  population_schools <- sum(population$num_schools)
  population_students <- sum(population$num_students)
  
  pop_df <- data_frame(population_district,population_campuses,population_schools,population_students)
  
  # Subset to Metric
  
  A <- aggregate(esh_id ~ metric, data = sample, FUN = length)
  colnames(A)[2] <- "districts"
  B <- aggregate(num_campuses ~ metric, data = sample, FUN = sum)
  colnames(B)[2] <- "campuses"
  C <- aggregate(num_schools ~ metric, data = sample, FUN = sum)
  colnames(C)[2] <- "schools"
  D <- aggregate(num_students ~ metric, data = sample, FUN = sum)
  colnames(D)[2] <- "students"
  
  output <- merge(A,B)
  output <- merge(output,C)
  output <- merge(output,D)
  
  # Sum the subset to get sample totals
  
  output$sample_districts <- sum(output$districts)
  output$sample_campuses <- sum(output$campuses)
  output$sample_schools <- sum(output$schools)
  output$sample_students <- sum(output$students)
  
  # Merge in population data
  output <- merge(output,pop_df)
  
  # Calculate percents
  output$percent_districts <- (output$districts/output$sample_districts)
  output$percent_campuses <- (output$campuses/output$sample_campuses)
  output$percent_schools <- (output$schools/output$sample_schools)
  output$percent_students <- (output$students/output$sample_students)
  
  # Extrapolate
  output$extrap_districts <- output$percent_districts*output$population_district
  output$extrap_campuses <- output$percent_campuses*output$population_campuses
  output$extrap_schools <- output$percent_schools*output$population_schools
  output$extrap_students <- output$percent_students*output$population_students
  
  print(output)
}

## ---- 2. FUNCTION: METRIC_GROUP ----
## PURPOSE: same as metric_overall but subsets to the group column defined in the data, like locale or fiber target status
## NOTE: the breakdown at the campus, school, and student level might not always be relevant or "accurate" depending on methodology

metric_group <- function(population,sample){
  
  #Population within each group
  
  A <- aggregate(esh_id ~ group, data = population, FUN = length)
  colnames(A)[2] <- "population_districts"
  B <- aggregate(num_campuses ~ group, data = population, FUN = sum)
  colnames(B)[2] <- "population_campuses"
  C <- aggregate(num_schools ~ group, data = population, FUN = sum)
  colnames(C)[2] <- "population_schools"
  D <- aggregate(num_students ~ group, data = population, FUN = sum)
  colnames(D)[2] <- "population_students"
  
  pop_df <- merge(A,B)
  pop_df <- merge(pop_df,C)
  pop_df <- merge(pop_df,D)
  
  # Subset to Metric x Group
  
  A <- aggregate(esh_id ~ group + metric, data = sample, FUN = length)
  colnames(A)[3] <- "districts"
  B <- aggregate(num_campuses ~ group + metric, data = sample, FUN = sum)
  colnames(B)[3] <- "campuses"
  C <- aggregate(num_schools ~ group + metric, data = sample, FUN = sum)
  colnames(C)[3] <- "schools"
  D <- aggregate(num_students ~ group + metric, data = sample, FUN = sum)
  colnames(D)[3] <- "students"
  
  output <- merge(A,B)
  output <- merge(output,C)
  output <- merge(output,D)
  
  # Sum the subset to get sample totals
  A <- aggregate(districts ~ group, data = output, FUN = sum)
  colnames(A)[2] <- "sample_districts"
  B <- aggregate(campuses ~ group, data = output, FUN = sum)
  colnames(B)[2] <- "sample_campuses"
  C <- aggregate(schools ~ group, data = output, FUN = sum)
  colnames(C)[2] <- "sample_schools"
  D <- aggregate(students ~ group, data = output, FUN = sum)
  colnames(D)[2] <- "sample_students"
  
  sample_df <- merge(A,B)
  sample_df <- merge(sample_df,C)
  sample_df <- merge(sample_df,D)
  
  ## merge in sample
  output <- merge(output,sample_df)
  
  ## merge in population
  output <- merge(output,pop_df)
  
  ## Calculate percents
  output$percent_districts <- (output$districts/output$sample_districts)
  output$percent_campuses <- (output$campuses/output$sample_campuses)
  output$percent_schools <- (output$schools/output$sample_schools)
  output$percent_students <- (output$students/output$sample_students)
  
  ## Extrapolate
  output$extrap_districts <- output$percent_districts*output$population_district
  output$extrap_campuses <- output$percent_campuses*output$population_campuses
  output$extrap_schools <- output$percent_schools*output$population_schools
  output$extrap_students <- output$percent_students*output$population_students
  
  print(output)
}

## ---- 3. FUNCTION: METRIC_OVERALL_MEDIAN ----
## PURPOSE: to calculate what median of a field overall, while also giving context with population and sample numbers
##


metric_overall_median <- function(population,sample){
  
  # Population
  
  population_district <- length(population$esh_id)
  population_campuses <- sum(population$num_campuses)
  population_schools <- sum(population$num_schools)
  population_students <- sum(population$num_students)
  
  pop_df <- data_frame(population_district,population_campuses,population_schools,population_students)
  
  # Sample
  
  sample_district <- length(sample$esh_id)
  sample_campuses <- sum(sample$num_campuses)
  sample_schools <- sum(sample$num_schools)
  sample_students <- sum(sample$num_students)
  
  sample_df <- data_frame(sample_district,sample_campuses,sample_schools,sample_students)
  
  # Calculate Median
  
  median_metric <- median(sample$metric)
  
  output <- merge(median_metric,sample_df)
  output <- merge(output,pop_df)
  
  print(output)
} 

## ---- 4. FUNCTION: METRIC_GROUP_MEDIAN ----
## PURPOSE: to calculate what median of a field across specificed groups, while also giving context with population and sample numbers
##

metric_group_median <- function(population,sample){
  
  #Population within each group
  
  A <- aggregate(esh_id ~ group, data = population, FUN = length)
  colnames(A)[2] <- "population_districts"
  B <- aggregate(num_campuses ~ group, data = population, FUN = sum)
  colnames(B)[2] <- "population_campuses"
  C <- aggregate(num_schools ~ group, data = population, FUN = sum)
  colnames(C)[2] <- "population_schools"
  D <- aggregate(num_students ~ group, data = population, FUN = sum)
  colnames(D)[2] <- "population_students"
  
  pop_df <- merge(A,B)
  pop_df <- merge(pop_df,C)
  pop_df <- merge(pop_df,D)
  
  #Sample within each group
  A <- aggregate(esh_id ~ group, data = sample, FUN = length)
  colnames(A)[2] <- "sample_districts"
  B <- aggregate(num_campuses ~ group, data = sample, FUN = sum)
  colnames(B)[2] <- "sample_campuses"
  C <- aggregate(num_schools ~ group, data = sample, FUN = sum)
  colnames(C)[2] <- "sample_schools"
  D <- aggregate(num_students ~ group, data = sample, FUN = sum)
  colnames(D)[2] <- "sample_students"
  
  sample_df <- merge(A,B)
  sample_df <- merge(sample_df,C)
  sample_df <- merge(sample_df,D)
  
  # Median of metric within group 
  
  output <- aggregate(metric ~ group, data = sample, FUN = median)

  # Merge
  output <- merge(output,sample_df)
  output <- merge(output,pop_df)
  
  print(output)
}

## ---- 5. FUNCTION: METRIC_OVERALL_WEIGHTED_AVERAGE ----
## PURPOSE: to calculate weighted average of metric overall, while also giving context with population and sample numbers
##

metric_overall_weighted_average <- function(population,sample){

  # Population
  
  population_district <- length(population$esh_id)
  population_campuses <- sum(population$num_campuses)
  population_schools <- sum(population$num_schools)
  population_students <- sum(population$num_students)
  
  pop_df <- data_frame(population_district,population_campuses,population_schools,population_students)
  
  # Sample
  
  sample_district <- length(sample$esh_id)
  sample_campuses <- sum(sample$num_campuses)
  sample_schools <- sum(sample$num_schools)
  sample_students <- sum(sample$num_students)
  
  sample_df <- data_frame(sample_district,sample_campuses,sample_schools,sample_students)
  
  # Calculate Median
  
  weighted_average_metric <- sum(sample$metric_numer)/sum(sample$metric_denom)
  
  output <- merge(weighted_average_metric,sample_df)
  output  <- merge(output,pop_df)
  
  print(output)
} 


## ---- 6. FUNCTION: METRIC_GROUP_WEIGHTED_AVERAGE ----
## PURPOSE: to calculate what median of a field across specificed groups, while also giving context with population and sample numbers
##

metric_group_weighted_average <- function(population,sample){
  
  #Population within each group
  
  A <- aggregate(esh_id ~ group, data = population, FUN = length)
  colnames(A)[2] <- "population_districts"
  B <- aggregate(num_campuses ~ group, data = population, FUN = sum)
  colnames(B)[2] <- "population_campuses"
  C <- aggregate(num_schools ~ group, data = population, FUN = sum)
  colnames(C)[2] <- "population_schools"
  D <- aggregate(num_students ~ group, data = population, FUN = sum)
  colnames(D)[2] <- "population_students"
  
  pop_df <- merge(A,B)
  pop_df <- merge(pop_df,C)
  pop_df <- merge(pop_df,D)
  
  #Sample within each group
  A <- aggregate(esh_id ~ group, data = sample, FUN = length)
  colnames(A)[2] <- "sample_districts"
  B <- aggregate(num_campuses ~ group, data = sample, FUN = sum)
  colnames(B)[2] <- "sample_campuses"
  C <- aggregate(num_schools ~ group, data = sample, FUN = sum)
  colnames(C)[2] <- "sample_schools"
  D <- aggregate(num_students ~ group, data = sample, FUN = sum)
  colnames(D)[2] <- "sample_students"
  
  sample_df <- merge(A,B)
  sample_df <- merge(sample_df,C)
  sample_df <- merge(sample_df,D)
  
  # Sum of metric numerator (in weighted average calculation) within group 
  metric_group_numer <- aggregate(metric_numer ~ group, data = sample, FUN = sum)
  
  # Sum of metric denominator (in weighted average calculation) within group
  metric_group_denom <- aggregate(metric_denom ~ group, data = sample, FUN = sum)
  output <- merge(metric_group_numer,metric_group_denom)
  
  output$metric_weighted_average <- output$metric_numer/output$metric_denom
  
  # Merge
  output <- merge(output,sample_df)
  output <- merge(output,pop_df)
  
  output <- within(output,rm(metric_numer,metric_denom))
  
  print(output)
}
