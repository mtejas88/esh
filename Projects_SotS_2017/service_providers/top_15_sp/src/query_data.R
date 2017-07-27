## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/service_providers/top_15_sp/")

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
source("../../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## source function to correct dataset
source("../../../General_Resources/common_functions/correct_dataset.R")

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## Connect to current DB -- ONYX
con <- dbConnect(pgsql, url=url, user=user, password=password)
## Districts Deluxe
dd_2017 <- querydb("../../../General_Resources/sql_scripts/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
sr_2017 <- querydb("../../../General_Resources/sql_scripts/2017_services_received_crusher_materialized.SQL")
sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)
## disconnect from database
dbDisconnect(con)


## Connect to 2016 Frozen DB -- PINK
con <- dbConnect(pgsql, url=url_pink, user=user_pink, password=password_pink)
dd_2016_froz <- querydb("../../../General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL")
dd_2016_froz <- correct.dataset(dd_2016_froz, sots.flag=0, services.flag=0)
sr_2016_froz <- querydb("../../../General_Resources/sql_scripts/2016_services_received_crusher_materialized.SQL")
sr_2016_froz <- correct.dataset(sr_2016_froz, sots.flag=0, services.flag=1)
## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd_2017, "data/raw/2017_deluxe_districts.csv", row.names=F)
write.csv(sr_2017, "data/raw/2017_services_received.csv", row.names=F)
write.csv(dd_2016_froz, "data/raw/2016_frozen_deluxe_districts.csv", row.names=F)
write.csv(sr_2016_froz, "data/raw/2016_frozen_services_received.csv", row.names=F)
