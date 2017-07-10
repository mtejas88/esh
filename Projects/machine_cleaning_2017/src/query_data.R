## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/machine_cleaning_2017/")

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

##**************************************************************************************************************************************************
## QUERY THE DB

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")


## connect to the database: PRIS 2016
con <- dbConnect(pgsql, url=url_pris2016, user=user_pris2016, password=password_pris2016)
## raw line item data (as it comes in from USAC)
#frn.line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_frn_line_items.SQL", sep=""))
frn.meta.data.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_frns.SQL", sep=""))
## pristine line item data
line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_line_items.SQL", sep=""))
## service provider data (for reporting name)
sp.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_service_providers.SQL", sep=""))
sp.2016 <- unique(sp.2016[,c('name', 'reporting_name')])
names(sp.2016)[names(sp.2016) == 'name'] <- 'service_provider_name'
## disconnect from database
dbDisconnect(con)


## connect to the database: ONYX
con <- dbConnect(pgsql, url=url, user=user, password=password)
## cleaned 2016 line item data
cl.line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_line_items.SQL", sep=""))
## raw line item data (as it comes in from USAC)
cl.frn.meta.data.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_frns.SQL", sep=""))
## cleaned 2017 line item data
cl.line.items.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_line_items.SQL", sep=""))
## flags
cl.flags.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_line_item_flags.SQL", sep=""))
## disconnect from database
dbDisconnect(con)


## connect to the database: PRIS 2017
con <- dbConnect(pgsql, url=url_pris2017, user=user_pris2017, password=password_pris2017)
## raw line item data (as it comes in from USAC)
frn.meta.data.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_frns.SQL", sep=""))
## pristine line item data
line.items.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_line_items.SQL", sep=""))
## flags
flags.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_line_item_flags.SQL", sep=""))
## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(frn.meta.data.2016, "data/raw/frn_meta_data_2016.csv", row.names=F)
write.csv(line.items.2016, "data/raw/line_items_2016.csv", row.names=F)
write.csv(sp.2016, "data/raw/service_providers_2016.csv", row.names=F)
write.csv(cl.line.items.2016, "data/raw/clean_line_items_2016.csv", row.names=F)
write.csv(cl.frn.meta.data.2017, "data/raw/clean_frn_meta_data_2017.csv", row.names=F)
write.csv(cl.line.items.2017, "data/raw/clean_line_items_2017.csv", row.names=F)
write.csv(cl.flags.2017, "data/raw/clean_flags_2017.csv", row.names=F)
write.csv(frn.meta.data.2017, "data/raw/frn_meta_data_2017.csv", row.names=F)
write.csv(line.items.2017, "data/raw/line_items_2017.csv", row.names=F)
write.csv(flags.2017, "data/raw/flags_2017.csv", row.names=F)
