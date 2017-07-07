git## =========================================
##
## QUERY DATA FROM THE DB
## Takes 10-15 minutes since we need to export large Form 477 data
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
source(paste(github_path, "General_Resources/common_functions/source_env.R", sep=""))
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

#time warning for these
dta.477s_fiber <- querydb("sql/form477s-fiber3.sql")
dta.477s_fiber_bg <- querydb("sql/form477s-fiber-bg3.sql")
dta.477s_fiber_ct <- querydb("sql/form477s-fiber-ct3.sql")


## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets
write.csv(dta.477s_fiber, "../data/raw/form_477s_fiber_bc3.csv", row.names=F)
write.csv(dta.477s_fiber_bg, "../data/raw/form_477s_fiber_bg3.csv", row.names=F)
write.csv(dta.477s_fiber_ct, "../data/raw/form_477s_fiber_ct3.csv", row.names=F)
