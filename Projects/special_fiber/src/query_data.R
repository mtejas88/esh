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

special_fiber_2017 <- querydb("src/special_fiber_2017.SQL")
applicant_470s <- querydb("src/applicant_470s.SQL")
special_fiber_2016 <- querydb("src/special_fiber_2016.SQL")
dd_2016 <- querydb("src/dd_2016.SQL")
dd_2015 <- querydb("src/dd_2015.SQL")
new_students_meeting <- querydb("src/new_students_meeting.SQL")
wifi_schools <- querydb("src/wifi_by_schools_disagg.SQL")
wifi_schools_2 <- querydb("src/wifi_by_schools_disagg_perf.SQL")
form_470s_2016 <- querydb("src/form_470s_2016.SQL")
sr_2016 <- querydb("src/sr_2016.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(special_fiber_2017, "data/raw/special_fiber_2017.csv", row.names=F)
write.csv(applicant_470s, "data/raw/applicant_470s_2017.csv", row.names=F)
write.csv(special_fiber_2016, "data/raw/special_fiber_2016.csv", row.names=F)
write.csv(dd_2016, "data/raw/dd_2016.csv", row.names=F)
write.csv(dd_2015, "data/raw/dd_2015.csv", row.names=F)
write.csv(new_students_meeting, "data/raw/new_students_meeting.csv", row.names=F)
write.csv(wifi_schools, "data/raw/wifi_schools.csv", row.names=F)
write.csv(wifi_schools_2, "data/raw/wifi_schools_2.csv", row.names=F)
write.csv(form_470s_2016, "data/raw/form_470s_2016.csv", row.names=F)
write.csv(sr_2016, "data/raw/sr_2016.csv", row.names=F)
