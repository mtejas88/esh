## ====================================================================
##
## QUERY DATA FROM THE DB - had to use mode sometimes, R got overwhelmed
##
## ====================================================================

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

districts_notmeeting <- querydb("queries/not_meeting.sql")
districts_notmeeting <- querydb("queries/meeting.sql")

#making format compatible
logical <- c("exclude_from_ia_cost_analysis", 
             "meeting_2014_goal_no_oversub","frns_2p_bid_indicator","frns_0_bid_indicator" ,"frns_1_bid_indicator")
districts_notmeeting[, logical] <- sapply(districts_notmeeting[, logical], function(x) ifelse(x == "t", 'true', 
                                                                                              ifelse(x =="f", 'false', x)))
districts_meeting[, logical] <- sapply(districts_meeting[, logical], function(x) ifelse(x == "t", 'true', 
                                                                                              ifelse(x =="f", 'false', x)))

write.csv(districts_notmeeting, "../data/raw/districts_notmeeting.csv", row.names=F)
write.csv(districts_meeting, "../data/raw/districts_meeting.csv", row.names=F)
