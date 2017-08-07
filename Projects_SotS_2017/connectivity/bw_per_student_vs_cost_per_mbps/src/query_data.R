## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

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
source("../../../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

districts <- querydb("queries/districts.sql")
str(districts)
districts$ia_monthly_cost_per_mbps_15=as.numeric(districts$ia_monthly_cost_per_mbps_15)

districts_exp <- querydb("queries/districts_exp.sql")
str(districts_exp)

write.csv(districts, "../data/raw/districts.csv", row.names=F)
write.csv(districts_exp, "../data/raw/districts_exp.csv", row.names=F)

dbDisconnect(con)
