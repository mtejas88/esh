## =========================================
##
## QUERY DATA FROM THE DB
##  for Comparison Check #2
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

## source function to correct dataset
source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url="jdbc:postgresql://ec2-34-205-194-0.compute-1.amazonaws.com:5432/dai3g95tesvtj9?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory",
                 user="ua5lmu5p5luic5",
                 password="p622de66700bbed4fd999364da5605ae5ec5c4c5124239c9e0bb0fa368be850ab")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dd.2016 <- querydb(paste(github_path, "General_Resources/sql_scripts/2016_deluxe_districts_crusher_materialized.SQL", sep=""))
dd.2016 <- correct.dataset(dd.2016, sots.flag=F, services.flag=F)
cck12.ds <- querydb(paste(github_path, "General_Resources/sql_scripts/endpoint_fy2016_cck12_district_summary.SQL", sep=""))
compare.di <- querydb(paste(github_path, "General_Resources/sql_scripts/endpoint_fy2016_compare_districts_info.SQL", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd.2016, "data/processed/deluxe_districts_2016.csv", row.names=F)
write.csv(cck12.ds, "data/processed/fy2016_cck12_district_summary.csv", row.names=F)
write.csv(compare.di, "data/processed/fy2016_compare_districts_info.csv", row.names=F)
