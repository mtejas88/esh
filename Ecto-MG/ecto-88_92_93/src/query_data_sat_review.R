## =========================================
##
## QUERY DATA FROM THE DB
##  for Comparison Check #2
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-88_92_93/")

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

## source environment variables (overall)
source("../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## for local DB
source("../../General_Resources/common_functions/source_env_ecto.R")
source_env_ecto("src/.env")

## source function to correct dataset
source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## connect to the database -- ECTO QA
con <- dbConnect(pgsql, url=url_ecto_qa, user=user_ecto_qa, password=password_ecto_qa)
cck12_ds_qa <- dbGetQuery(con, "select * from endpoint.fy2017_cck12_district_summary")
## disconnect from database
dbDisconnect(con)

## connect to the database -- ONYX
con <- dbConnect(pgsql, url=url, user=user, password=password)
cck12_ds <- querydb(paste(ecto_path, "db_ecto/material_girl/endpoint/fy2017/fy2017_cck12_district_summary_v04.SQL", sep=""))
## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(cck12_ds_qa, "data/raw/fy2017_cck12_district_summary_qa.csv", row.names=F)
write.csv(cck12_ds, "data/raw/fy2017_cck12_district_summary.csv", row.names=F)
