## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

#setwd("~/Documents/ESH-Code/ficher/Projects/smd_2017/")
#setwd("~/Documents/R_WORK/ficher/Projects/smd_2017/")

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
## read in outliers
outlier_output <- read.csv("../../General_Resources/datasets/outlier_output.csv")
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
## State Aggregation
smd_2017 <- querydb("../../General_Resources/sql_scripts/2017_smd.SQL")
smd_2016 <- querydb("../../General_Resources/sql_scripts/2016_smd.SQL")
## Districts Deluxe
dd_2017 <- querydb("../../General_Resources/sql_scripts/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
dd_2016 <- querydb("../../General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL")
dd_2016 <- correct.dataset(dd_2016, sots.flag=0, services.flag=0)
## Outlier Flags
resolved_outliers <- querydb("../../General_Resources/sql_scripts/resolved_outliers_smd.SQL")
## Merge outliers
dd_2017 <- merge(x = dd_2017, y = resolved_outliers, by = "esh_id", all.x = TRUE)
dd_2017 <- merge(x = dd_2017, y = outlier_output, by = "esh_id", all.x = TRUE)
## disconnect from database
dbDisconnect(con)


## Connect to 2016 Frozen DB -- PINK
#con <- dbConnect(pgsql, url=url_pink, user=user_pink, password=password_pink)
#smd_2016_froz <- querydb("../../General_Resources/sql_scripts/2016_smd.SQL")
#dd_2016_froz <- querydb("../../General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL")
#dd_2016_froz <- correct.dataset(dd_2016_froz, sots.flag=0, services.flag=0)
#dd_2015_froz <- querydb("../../General_Resources/sql_scripts/2015_deluxe_districts_crusher_materialized.SQL")
#dd_2015_froz <- correct.dataset(dd_2015_froz, sots.flag=0, services.flag=0)
## disconnect from database
#dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

## store the datasets daily for now
if (weekday == 'Monday'){
  ## State Aggregation
  write.csv(smd_2017, paste("data/raw/2017_state_aggregation_", date, ".csv", sep=''), row.names=F)
  write.csv(smd_2016, paste("data/raw/2016_state_aggregation_", date, ".csv", sep=''), row.names=F)
  ## Districts Deluxe
  write.csv(dd_2017, paste("data/raw/2017_deluxe_districts_", date, ".csv", sep=''), row.names=F)
  write.csv(dd_2016, paste("data/raw/2016_deluxe_districts_", date, ".csv", sep=''), row.names=F)
}

## write out generically
## State Aggregation
write.csv(smd_2017, "data/raw/2017_state_aggregation.csv", row.names=F)
write.csv(smd_2016, "data/raw/2016_state_aggregation.csv", row.names=F)
#write.csv(smd_2016_froz, "data/raw/2016_2015_frozen_state_aggregation.csv", row.names=F)
## Districts Deluxe
write.csv(dd_2017, "data/raw/2017_deluxe_districts.csv", row.names=F)
write.csv(dd_2016, "data/raw/2016_deluxe_districts.csv", row.names=F)
#write.csv(dd_2016_froz, "data/raw/2016_frozen_deluxe_districts.csv", row.names=F)
#write.csv(dd_2015_froz, "data/raw/2015_frozen_deluxe_districts.csv", row.names=F)
#write.csv(outlier_output, "data/raw/outlier_output.csv", row.names=F)
## Date
date.dta <- data.frame(matrix(NA, nrow=1, ncol=1))
names(date.dta) <- 'date'
date.dta$date <- strsplit(date, "_")[[1]][1]
write.csv(date.dta, "data/raw/date.csv", row.names=F)
