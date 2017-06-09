## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

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

dd.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL", sep=""))
dd.2016 <- correct.dataset(dd.2016, sots.flag=0, services.flag=0)
frn.status <- querydb("src/frn_statuses.sql")
negative.barriers <- querydb("src/negative_barriers.sql")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd.2016, "data/raw/districts_deluxe.csv", row.names=F)
write.csv(frn.status, "data/raw/frn_statuses.csv", row.names=F)
write.csv(negative.barriers, "data/raw/negative_barriers.csv", row.names=F)
