## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/fiber/new_campuses_with_fiber/")

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

## Connect to 2017 Frozen DB -- ICE
con <- dbConnect(pgsql, url=url_ice, user=user_ice, password=password_ice)

## Deluxe Districts
dd_2017 <- querydb("../../../General_Resources/sql_scripts/2017/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
dd_2016 <- querydb("../../../General_Resources/sql_scripts/2016/2016_deluxe_districts_crusher_materialized.SQL")
dd_2016 <- correct.dataset(dd_2016, sots.flag=0, services.flag=0)

## Services Received
sr_2017 <- querydb("../../../General_Resources/sql_scripts/2017/2017_services_received_crusher_materialized.SQL")
sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)

## Fiber Campuses
campuses_on_fiber <- querydb("src/campuses_getting_fiber.sql")
campuses_on_fiber <- correct.dataset(campuses_on_fiber, sots.flag=0, services.flag=0)
bids_470 <- querydb("src/districts_470_bids.sql")
bids_470 <- correct.dataset(bids_470, sots.flag=0, services.flag=0)

## Form 470
form_470 <- querydb("../../../General_Resources/sql_scripts/2017/2017_form470s.SQL")
form_470_rfps <- querydb("../../../General_Resources/sql_scripts/2017/2017_form470_rfps.SQL")

## Entity BENs
bens <- querydb("../../../General_Resources/sql_scripts/2017/2017_entity_bens.SQL")

## FRNs
frns <- querydb("../../../General_Resources/sql_scripts/2017/2017_frns.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

## Districts Deluxe
write.csv(dd_2017, "data/raw/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "data/raw/2016_deluxe_districts.csv", row.names=F)

## Services Received
write.csv(sr_2017, "data/raw/2017_services_received.csv", row.names=F)

## Fiber Campuses
write.csv(campuses_on_fiber, "data/raw/campuses_on_fiber.csv", row.names=F)
write.csv(bids_470, "data/raw/bids_470.csv", row.names=F)

## Form 470s
write.csv(form_470, "data/raw/form_470.csv", row.names=F)
write.csv(form_470_rfps, "data/raw/form_470_rfps.csv", row.names=F)

## BENs
write.csv(bens, "data/raw/bens.csv", row.names=F)

## FRNs
write.csv(frns, "data/raw/frns.csv", row.names=F)
