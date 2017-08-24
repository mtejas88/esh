## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/scope_peer_district_logic/")

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

## Current CCK12 peer district logic
cck12_peer <- querydb("src/fy2017_fiber_ia_suggested_districts_v01.sql")

## Current SAT peer district logic
#sat_peer <- querydb("src/fy2017_bandwidth_suggested_districts_sat.sql")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## find out how many districts have 0 peers

dd_2017 <- dd_2017[c(dd_2017$include_in_universe_of_districts == TRUE &
                        dd_2017$exclude_from_ia_analysis == FALSE &
                        dd_2017$district_type == 'Traditional'),]

length(dd_2017$esh_id[!dd_2017$esh_id %in% unique(cck12_peer$esh_id)])



