
## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd('~/Documents/Analysis/ficher/Projects/voice_ffl/')

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

spend <- querydb("src/voice_spend.sql")
spend.by.discount <- querydb("src/voice_spend_by_discount.sql")
spend.applicant <- querydb("src/voice_spend_applicant.sql")


## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(spend, "data/raw/spend.csv", row.names=F)
write.csv(spend.by.discount, "data/raw/spend_discount.csv", row.names=F)
write.csv(spend.applicant, "data/raw/spend_app.csv", row.names=F)

