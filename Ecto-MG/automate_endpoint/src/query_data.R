## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

github_path <- "~/Documents/ESH-Code/ficher/"
ecto_path <- "~/Documents/ESH-Code/ecto/"

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
options(java.parameters = "-Xmx4g" )

## source environment variables
source(paste(github_path, "General_Resources/common_functions/source_env.R", sep=""))
source_env("~/.env")

## source function to correct dataset
source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))

date <- Sys.time()
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

##**************************************************************************************************************************************************
## QUERY THE DB

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

suggested_districts <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_bandwidth_suggested_districts_v06.sql", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(suggested_districts, paste("data/suggested_districts_", date, ".csv", sep=""), row.names=F)
