## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
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
options(java.parameters = "-Xmx4g" )

## source environment variables
source("../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## source function to correct dataset
source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## Connect to current DB
## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

smd_2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_smd.SQL", sep=""))
smd_2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_smd.SQL", sep=""))
dd_2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_deluxe_districts.SQL", sep=""))
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
dd_2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL", sep=""))
dd_2016 <- correct.dataset(dd_2016, sots.flag=0, services.flag=0)

## disconnect from database
dbDisconnect(con)


## Connect to 2016 Frozen DB
## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)


##**************************************************************************************************************************************************
## write out the datasets

## store the datasets daily for now
if (weekday == 'Monday'){
  write.csv(smd_2017, paste("data/raw/2017_state_aggregation_", date, ".csv", sep=''), row.names=F)
  write.csv(smd_2016, paste("data/raw/2016_state_aggregation_", date, ".csv", sep=''), row.names=F)
  write.csv(dd_2017, paste("data/raw/2017_deluxe_districts_", date, ".csv", sep=''), row.names=F)
  write.csv(dd_2016, paste("data/raw/2016_deluxe_districts_", date, ".csv", sep=''), row.names=F)
}

## write out generically
write.csv(smd_2017, paste("tool/data/2017_state_aggregation.csv", sep=""), row.names=F)
write.csv(smd_2016, paste("tool/data/2016_state_aggregation.csv", sep=""), row.names=F)
write.csv(dd_2017, paste("tool/data/2017_deluxe_districts.csv", sep=""), row.names=F)
write.csv(dd_2016, paste("tool/data/2016_deluxe_districts.csv", sep=""), row.names=F)
