## QUERY DATA FROM DB


## clear memory
rm(list=ls())

args = commandArgs(trailingOnly=TRUE)
github_path <- args[1]

## load packages
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

## source environment variables
source("~/GitHub/ficher/General_Resources/common_functions/source_env.R")
source_env("~/.env")

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## load postgresql driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}


## query
broadband_data <- querydb("src/two_yr_clean_sample.sql")

## disconnect from database
dbDisconnect(con)

## write out
write.csv(broadband_data, "data/broadband_data.csv", row.names = FALSE)




