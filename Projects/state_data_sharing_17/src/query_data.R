## =========================================
##
## QUERY DATA FROM THE DB
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

district <- querydb('src/district_dedicated_services.sql')
consortia <- querydb('src/consortia_filed_services.sql')
district_detailed <- querydb('src/district_dedicated_services_detail.sql')
consortia_detailed <- querydb('src/consortia_filed_services_detail.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(district, 'data/raw/districts.csv', row.names = FALSE)
write.csv(consortia, 'data/raw/consortia.csv', row.names = FALSE)
write.csv(district_detailed, 'data/raw/districts_detailed.csv', row.names = FALSE)
write.csv(consortia_detailed, 'data/raw/consortia_detailed.csv', row.names = FALSE)
