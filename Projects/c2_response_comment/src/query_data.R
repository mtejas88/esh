
## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd('~/Documents/Analysis/ficher/Projects/c2_response_comment/')

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

wifi <- querydb("src/wifi.SQL")
suff.state <- querydb("src/suffiency_by_state.SQL")
remaining.hist <- querydb("src/wifi_remaining_hist.SQL")
make.17 <- querydb("src/make_model_17.sql")
make.17.districts <- querydb("src/make_model_17_districts.sql")
c2.consultants <- querydb("src/c2_consultants.SQL")
c1.consultants <- querydb("src/c1_consultants.SQL")
ffl <- querydb("src/ffl.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(wifi, "data/raw/wifi.csv", row.names=F)
write.csv(suff.state, "data/raw/suff_state.csv", row.names=F)
write.csv(remaining.hist, "data/raw/remaining_hist.csv", row.names=F)
write.csv(make.17, "data/raw/all_make_17.csv", row.names = F)
write.csv(make.17.districts, "data/raw/make_17_districts.csv", row.names = F)
write.csv(c2.consultants, "data/raw/c2_consultants.csv", row.names = F)
write.csv(c1.consultants, "data/raw/c1_consultants.csv", row.names = F)
write.csv(ffl, "data/raw/ffl.csv", row.names = F)

