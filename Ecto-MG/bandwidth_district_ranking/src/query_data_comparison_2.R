## =========================================
##
## QUERY DATA FROM THE DB
##  for Comparison Check #2
##
## =========================================

## Clearing memory
rm(list=ls())

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
source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url="jdbc:postgresql://ec2-34-203-91-0.compute-1.amazonaws.com:5432/da04sqvab68fml?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory",
                 user="uctpefpdiv4csp",
                 password="p7ea90f3d915733d53db7bd03a3624bfe5e1cacb50990595abd99aab1eb53dcf8")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dd.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL", sep=""))
dd.2016 <- correct.dataset(dd.2016, sots.flag=F, services.flag=F)
cck12.ds <- querydb(paste(github_path, "General_Resources/sql_scripts/endpoint_fy2016_cck12_district_summary.SQL", sep=""))
compare.di <- querydb(paste(github_path, "General_Resources/sql_scripts/endpoint_fy2016_compare_districts_info.SQL", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd.2016, "data/processed/deluxe_districts_2016.csv", row.names=F)
write.csv(cck12.ds, "data/processed/fy2016_cck12_district_summary.csv", row.names=F)
write.csv(compare.di, "data/processed/fy2016_compare_districts_info.csv", row.names=F)
