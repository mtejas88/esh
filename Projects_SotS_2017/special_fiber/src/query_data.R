
## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

#setwd('~/Documents/Analysis/ficher/Projects_SotS_2017/special_fiber/')

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
url_ice
user_ice
password_ice
## connect to the database
con <- dbConnect(pgsql, url=url_ice, user=user_ice, password=password_ice)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

special_fiber_new_meth <- querydb("src/special_fiber_new_meth.sql")
special_fiber_16 <- querydb("src/special_fiber_new_meth_16.sql")
special_fiber_17 <- querydb("src/special_fiber_new_meth_17.sql")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(special_fiber_new_meth, "data/raw/special_fiber_new_meth.csv", row.names=F)
write.csv(special_fiber_16, "data/raw/special_fiber_new_meth_16.csv", row.names=F)
write.csv(special_fiber_17, "data/raw/special_fiber_new_meth_17.csv", row.names=F)


