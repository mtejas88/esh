## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-94/")

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

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

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
## Services Received
sr_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_services_received_endpoint.SQL")
sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)

## test SQL logic for unscalable
## merged version
uc_2017 <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_unscalable_line_items_v01.sql", sep=""))
## broken up into two different queries
#uc_wan <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_unscalable_wan.sql", sep=""))
#uc_ia <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_unscalable_ia.sql", sep=""))

## test SQL logic for scalable
sc_2017 <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_scalable_line_items_v01.sql", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out data

write.csv(dd_2017, "data/raw/2017_deluxe_districts.csv", row.names=F)
write.csv(sr_2017, "data/raw/2017_services_recieved.csv", row.names=F)
write.csv(uc_2017, "data/raw/2017_unscalable_line_items.csv", row.names=F)
#write.csv(uc_wan, "data/raw/2017_unscalable_wan.csv", row.names=F)
#write.csv(uc_ia, "data/raw/2017_unscalable_ia.csv", row.names=F)
write.csv(sc_2017, "data/raw/2017_scalable_line_items.csv", row.names=F)
