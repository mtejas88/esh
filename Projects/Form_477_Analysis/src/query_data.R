## =========================================
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

dd.2016 <- querydb("sql/dd_2016.sql") 
dta.sr_sp <- querydb("sql/sr_2016.sql")
dd.2016 <- correct.dataset(dd.2016, sots.flag=0, services.flag=0)
districts_schools=querydb("sql/district_lookup.sql")
#time warning for dta.477s
dta.477s <- querydb("sql/form477s.sql")
dta.477s_fiber <- querydb("sql/form477s-fiber.sql")
#time warning for dta.477s_fiber_bg_ct
dta.477s_fiber_bg_ct <- querydb("sql/form477s-fiber-bg-ct.sql")


## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd.2016, "../data/raw/deluxe_districts_2016.csv", row.names=F)
write.csv(dta.sr_sp, "../data/raw/services_received_2016.csv", row.names=F)
write.csv(districts_schools, "../data/raw/districts_schools.csv", row.names=F)
write.csv(dta.477s, "../data/raw/form_477s.csv", row.names=F)
write.csv(dta.477s_fiber, "../data/raw/form_477s_fiber.csv", row.names=F)
write.csv(dta.477s_fiber_bg_ct, "../data/raw/form_477s_fiber_bg_ct.csv", row.names=F)
