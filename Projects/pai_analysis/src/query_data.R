# clear the console
cat("\014")

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

#this is my github path. DONT FORGET TO COMMENT OUT
#github_path <- '~/Documents/Analysis/ficher/'
setwd(paste(github_path, 'Projects/pai_analysis', sep=''))


options(java.parameters = "-Xmx4g" )

## source environment variables
source(paste(github_path, "General_Resources/common_functions/source_env.R", sep=""))
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

districts_deluxe <- querydb('src/districts_deluxe.sql')
total_funding_by_district <- querydb('src/total_funding_by_district.sql')
service_providers <- querydb('src/service_providers.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(districts_deluxe, 'data/raw/2016_districts.csv', row.names = FALSE)
write.csv(total_funding_by_district, 'data/raw/2016_total_funding_by_district.csv', row.names = FALSE)
write.csv(service_providers, 'data/raw/service_providers.csv', row.names = FALSE)
