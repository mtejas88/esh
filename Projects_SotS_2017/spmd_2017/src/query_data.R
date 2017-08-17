## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

#setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/spmd_2017/")
#setwd("~/Documents/R_WORK/ficher/Projects_SotS_2017/spmd_2017/")

#args = commandArgs(trailingOnly=TRUE)
#github_path <- args[1]

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

## Connect to Frozen 2017 DB -- ICE
con <- dbConnect(pgsql, url=url_ice, user=user_ice, password=password_ice)
## SP Aggregation
sp_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_service_providers_agg.SQL")
sp_2016 <- querydb("../../General_Resources/sql_scripts/2016/2016_service_providers_agg.SQL")
sp_2017_overlap <- querydb("../../General_Resources/sql_scripts/2017/2017_service_providers_agg_clean_both_years.SQL")
sp_2016_overlap <- querydb("../../General_Resources/sql_scripts/2016/2016_service_providers_agg_clean_both_years.SQL")

## Districts Deluxe
dd_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
dd_2016 <- querydb("../../General_Resources/sql_scripts/2016/2016_deluxe_districts_crusher_materialized.SQL")
dd_2016 <- correct.dataset(dd_2016, sots.flag=0, services.flag=0)

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

## SP Aggregation
write.csv(sp_2017, "data/raw/sp_aggregation/2017_sp_aggregation.csv", row.names=F)
write.csv(sp_2016, "data/raw/sp_aggregation/2016_sp_aggregation.csv", row.names=F)
write.csv(sp_2017_overlap, "data/raw/sp_aggregation/2017_sp_aggregation_clean_both_years.csv", row.names=F)
write.csv(sp_2016_overlap, "data/raw/sp_aggregation/2016_sp_aggregation_clean_both_years.csv", row.names=F)

## Districts Deluxe
write.csv(dd_2017, "data/raw/deluxe_districts/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "data/raw/deluxe_districts/2016_deluxe_districts.csv", row.names=F)

## Date
date.dta <- data.frame(matrix(NA, nrow=1, ncol=1))
names(date.dta) <- 'date'
date.dta$date <- as.Date("2016-08-16")
write.csv(date.dta, "data/raw/date.csv", row.names=F)
