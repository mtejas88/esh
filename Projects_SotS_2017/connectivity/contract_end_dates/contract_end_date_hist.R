## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
#setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/connectivity/contract_end_dates")
setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/connectivity/contract_end_dates")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2", "reshape2", "plyr", "DBI", "rJava", "RJDBC", "dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)
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
pgsql <- JDBC("org.postgresql.Driver", "../../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## Connect to 2017 Frozen DB -- ICE
con <- dbConnect(pgsql, url=url_ice, user=user_ice, password=password_ice)

districts_not_meeting_goals <- querydb("contract_end_date.sql")

## disconnect from database
dbDisconnect(con)

## old code read in the data (sourced from python)
## import and filter
#districts_not_meeting_goals <- read.csv("data/districts_not_meeting.csv")

##**************************************************************************************************************************************************
## create the plot

## subset to just the first 3 years
subset_for_graph <- districts_not_meeting_goals[which(districts_not_meeting_goals$contract_end_time <= 3),]


## histogram of contract end time
p.contract <- ggplot(districts_not_meeting_goals, aes(contract_end_time))
p.contract + geom_histogram(binwidth=1, fill="#009296")+
  ylab("Number of districts")+
  #xlab("Years until contract end of soonest expiring internet contract")+
  xlab("Contract End Date")+
  scale_x_continuous(breaks = c(1,2,3,4,5,6,7))+ 
  geom_text(aes( label = scales::percent(..prop..),
                 y= ..prop.. ), stat= "count", vjust = -.5)+
  ggtitle("Districts not meeting goals")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))


