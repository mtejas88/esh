## =========================================
## 
## QUERY DATA FROM DB 
##
## =========================================

## clear memory
rm(list=ls())

args = commandArgs(trailingOnly=TRUE)
github_path <- args[1]

## load packages (if not already in the environment)
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
setwd(paste(github_path, 'Projects/charter_research', sep=''))

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

campus <- querydb("src/charter_classification/regular_campus_classification.SQL")
applied_received <- querydb("src/charter_classification/services_received_applied_for_classification.SQL")



## disconnect from database
dbDisconnect(con)

## write out datasets
write.csv(campus, "data/campus.csv", row.names = FALSE)
write.csv(applied_received, "data/applied_received.csv", row.names = FALSE)
