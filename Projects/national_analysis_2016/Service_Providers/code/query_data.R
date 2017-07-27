## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/national_analysis_2016/Service_Providers/")

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

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

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
dd_2016 <- querydb("../../../General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL")
dd_2016 <- correct.dataset(dd_2016, sots.flag=0, services.flag=0)
dd_2015 <- querydb("../../../General_Resources/sql_scripts/2015_deluxe_districts_crusher_materialized.SQL")
dd_2015 <- correct.dataset(dd_2015, sots.flag=0, services.flag=0)

## Services Received
sr_2017 <- querydb("../../../General_Resources/sql_scripts/2017_services_received_crusher_materialized.SQL")
sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)
sr_2016 <- querydb("../../../General_Resources/sql_scripts/2016_services_received_crusher_materialized.SQL")
sr_2016 <- correct.dataset(sr_2016, sots.flag=0, services.flag=1)
sr_2015 <- querydb("../../../General_Resources/sql_scripts/2015_services_received_crusher_materialized.SQL")
sr_2015 <- correct.dataset(sr_2015, sots.flag=0, services.flag=1)

## new assignments (Sierra's queries)
sp_assign_2017 <- querydb("../../../General_Resources/Views/2017/fy2017_districts_service_provider_assignments_matr.sql")
sp_assign_2016 <- querydb("../../../General_Resources/Views/2016/fy2016_districts_service_provider_assignments_matr.sql")
sp_assign_2015 <- querydb("../../../General_Resources/Views/2015/fy2015_districts_service_provider_assignments_matr.sql")

## new switchers (Sierra's query) -- takes a min
sp_switchers <- querydb("../../../General_Resources/sql_scripts/switchers.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

## Districts Deluxe
write.csv(dd_2017, "data/raw/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "data/raw/2016_deluxe_districts.csv", row.names=F)
write.csv(dd_2015, "data/raw/2015_deluxe_districts.csv", row.names=F)

## Services Received
write.csv(sr_2017, "data/raw/2017_services_received.csv", row.names=F)
write.csv(sr_2016, "data/raw/2016_services_received.csv", row.names=F)
write.csv(sr_2015, "data/raw/2015_services_received.csv", row.names=F)

## SP Assignments
write.csv(sp_assign_2017, "data/raw/2017_current_sp_assignments.csv", row.names=F)
write.csv(sp_assign_2016, "data/raw/2016_current_sp_assignments.csv", row.names=F)
write.csv(sp_assign_2015, "data/raw/2015_current_sp_assignments.csv", row.names=F)

## switchers
write.csv(sp_switchers, "data/raw/current_switchers.csv", row.names=F)
