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
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

nces <- querydb(paste(github_path, "General_Resources/sql_scripts/fy2014_fy2015_schools_membership.SQL", sep=""))
usac <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_entity_reports.SQL", sep=""))
schools <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_schools_demog.SQL", sep=""))
schools <- correct.dataset(schools, 0, 0)
bens <- querydb(paste(github_path, "General_Resources/sql_scripts/Entity_Bens.SQL", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(nces, "data/raw/nces_2014-15.csv", row.names=F)
write.csv(usac, "data/raw/usac_2016.csv", row.names=F)
write.csv(schools, "data/raw/schools.csv", row.names=F)
write.csv(bens, "data/raw/bens.csv", row.names=F)
