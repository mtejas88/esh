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

remaining_wifi <- querydb('src/remaining_wifi.sql')
districts_remaining_wifi <- querydb('src/districts_remaining_wifi.sql')
receives_services <- querydb('src/receives_services.sql')
c1_spend <- querydb('src/c1_spend.sql')
wifi_and_upgrades <- querydb('src/wifi_and_upgrades.sql')


## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(remaining_wifi, 'data/raw/remaining_wifi.csv', row.names = FALSE)
write.csv(districts_remaining_wifi, 'data/raw/districts_remaining_wifi.csv', row.names = FALSE)
write.csv(receives_services, 'data/raw/receives_services.csv', row.names = FALSE)
write.csv(c1_spend, 'data/raw/c1_spend.csv', row.names = FALSE)
write.csv(wifi_and_upgrades, 'data/raw/wifi_and_upgrades.csv', row.names = FALSE)
