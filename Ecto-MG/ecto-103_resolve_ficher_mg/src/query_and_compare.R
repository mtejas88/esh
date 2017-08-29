## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-103_resolve_ficher_mg/")

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
source("../../General_Resources/common_functions/correct_dataset.R")

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## Connect to current DB -- ONYX
con <- dbConnect(pgsql, url=url, user=user, password=password)
## Districts Deluxe
dd_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
## Districts Deluxe (Endpoint)
dd_2017_end <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts_endpoint.SQL")
dd_2017_end <- correct.dataset(dd_2017_end, sots.flag=0, services.flag=0)
## Services Received
#sr_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_services_received_crusher_materialized.SQL")
#sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)
## disconnect from database
dbDisconnect(con)


## Connect to QA DB
#con <- dbConnect(pgsql, url=url_temp, user=user_temp, password=password_temp)
## Districts Deluxe
#dd_2017_end <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts_endpoint.SQL")
#dd_2017_end <- correct.dataset(dd_2017_end, sots.flag=0, services.flag=0)
## Services Received
#sr_2017_end <- querydb("../../General_Resources/sql_scripts/2017/2017_services_received_endpoint.SQL")
#sr_2017_end <- correct.dataset(sr_2017_end, sots.flag=0, services.flag=1)
## disconnect from database
#dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

## Districts Deluxe
write.csv(dd_2017, "data/raw/2017_deluxe_districts_ficher.csv", row.names=F)
write.csv(dd_2017_end, "data/raw/2017_deluxe_districts_endpoint.csv", row.names=F)

## Services Received
#write.csv(sr_2017, "data/raw/2017_services_received_ficher.csv", row.names=F)
#write.csv(sr_2017_end, "data/raw/2017_services_received_endpoint.csv", row.names=F)
