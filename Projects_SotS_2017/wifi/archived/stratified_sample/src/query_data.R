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

source("../../../../ficher/General_Resources/common_functions/source_env.R")
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

wifi_survey <- querydb('src/wifi_survey.sql')
dd <- querydb('src/dd.sql')
wifi_money <- querydb('src/wifi_districts_spent_money.sql')


## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(wifi_survey, 'data/raw/wifi_survey.csv', row.names = FALSE)
write.csv(dd, 'data/raw/dd.csv', row.names = FALSE)
write.csv(wifi_money, 'data/raw/wifi_money.csv', row.names = FALSE)

