
## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd('~/Documents/Analysis/ficher/Projects_SotS_2017/e-rate/AK_increase/')

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
source("../../../General_Resources/common_functions/source_env.R")
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

perc_IA <- querydb("src/perc_IA.sql")
total_sr <- querydb("src/total_sr.sql")
wtd_avg_bw <- querydb("src/wtd_avg_bw.sql")
one_mbps <- querydb("src/one_mbps_costs.sql")
wan <- querydb("src/wan.sql")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(perc_IA, "data/perc_IA.csv", row.names=F)
write.csv(total_sr, "data/total_sr.csv", row.names=F)
write.csv(wtd_avg_bw, "data/wtd_avg_bw.csv", row.names=F)
write.csv(one_mbps, "data/one_mbps.csv", row.names=F)
write.csv(wan, "data/wan.csv", row.names=F)
