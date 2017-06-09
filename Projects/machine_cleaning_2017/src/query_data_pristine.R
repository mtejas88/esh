## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

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

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=url_pris2016, user=user_pris2016, password=password_pris2016)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## raw line item data (as it comes in from USAC)
frn.line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_frn_line_items.SQL", sep=""))
#frn.line.items.2016 <- correct.dataset(frn.line.items.2016, sots.flag=0, services.flag=0)
frn.meta.data.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_frns.SQL", sep=""))
#frn.meta.data.2016 <- correct.dataset(frn.meta.data.2016, sots.flag=0, services.flag=0)

## pristine line item data
line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_line_items.SQL", sep=""))
#line.items.2016 <- correct.dataset(line.items.2016, sots.flag=0, services.flag=0)

## service provider data (for reporting name)
sp.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_service_providers.SQL", sep=""))
sp.2016 <- unique(sp.2016[,c('name', 'reporting_name')])
names(sp.2016)[names(sp.2016) == 'name'] <- 'service_provider_name'
sp.2016 <- sp.2016[!is.na(sp.2016$reporting_name),]

## disconnect from database
dbDisconnect(con)

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## cleaned line item data
clean.line.items.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_line_items.SQL", sep=""))
#clean.line.items.2016 <- correct.dataset(clean.line.items.2016, sots.flag=0, services.flag=0)

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(frn.meta.data.2016, "data/raw/frn_meta_data_2016.csv", row.names=F)
write.csv(line.items.2016, "data/raw/line_items_2016.csv", row.names=F)
write.csv(sp.2016, "data/raw/service_providers_2016.csv", row.names=F)
write.csv(clean.line.items.2016, "data/raw/clean_line_items_2016.csv", row.names=F)
