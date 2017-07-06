## clear memory
rm(list=ls())

# load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)

## source environment variables
source("~/GitHub/ficher/General_Resources/common_functions/source_env.R")
source_env("~/.env")

## set working directory
setwd(paste(github_path, 'Projects/cross_yr_frn_match', sep=''))

# read in data
matches <- read.csv("data/matches.csv", as.is=T, header=T, stringsAsFactors=F)

# removing above threshold discussed with Marques
matches <- matches[which(matches$match_score >= 215),]

## update connect_type
for (i in 1:nrow(matches)){
  if (matches$old_purpose[i] == "ISP"){
    matches$mu_connect_type[i] <- NA 
  } else if (is.na(matches$updated_connect_type[i])==FALSE){
    matches$mu_connect_type[i] <- matches$old_connect_type[i]
  } else matches$mu_connect_type[i] <- NA
}

## update function
for (i in 1:nrow(matches)){
  if (matches$old_purpose[i] == "ISP"){
    matches$mu_function[i] <- NA
  } else if (is.na(matches$updated_function[i]) == FALSE){
    matches$mu_function[i] <- matches$old_function[i]
  } else {
    matches$mu_function[i] <- NA
  }
}

## not going to update connect category since that is meta data field dependant on connect_type and function

## update num lines for new 2017 that have the value of 1
for (i in 1:nrow(matches)){
  if (is.na(matches$updated_num_lines[i]) == TRUE){
    matches$mu_num_lines[i] <- NA
  } else if (matches$updated_num_lines[i] == "1" | matches$updated_num_lines[i]=="Unknown"){
    matches$mu_num_lines[i] <- matches$old_num_lines[i]
  } else {
    matches$mu_num_lines[i] <- NA
  }
}

## update purpose 
for (i in 1:nrow(matches)){
  if(is.na(matches$updated_purpose[i]) == FALSE){
    matches$mu_purpose[i] <- matches$old_purpose[i]
  } else {
    matches$mu_purpose[i] <- NA
  }
}

## update consortium_shared
for (i in 1:nrow(matches)){
  if(is.na(matches$updated_consortium_shared[i]) == FALSE){
    matches$mu_consortium_shared[i] <- matches$old_consortium_shared[i]
  } else {
    matches$mu_consortium_shared[i] <- NA
  }
}

## add note for engineering to allocated to recipients
for (i in 1:nrow(matches)){
  if (is.na(matches$updated_num_lines[i]) == TRUE){
    matches$mu_note[i] <- NA
  } else if (matches$updated_num_lines[i]=="Unknown"){
    matches$mu_note[i] <- "Allocate to recipients"
  } else {
    matches$mu_note[i] <- NA
  }
}

write.csv(matches, "data/mass_update_matches.csv", row.names = FALSE)
