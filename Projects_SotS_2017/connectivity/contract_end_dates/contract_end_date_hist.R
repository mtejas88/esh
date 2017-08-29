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

## take out NULL contract_end_time
districts_not_meeting_goals <- districts_not_meeting_goals[which(!is.na(districts_not_meeting_goals$contract_end_time)),]
districts_not_meeting_goals$contract_end_year <- ifelse(districts_not_meeting_goals$contract_end_time == 1, 2018,
                                                  ifelse(districts_not_meeting_goals$contract_end_time == 2, 2019,
                                                    ifelse(districts_not_meeting_goals$contract_end_time == 3, 2020, NA)))

districts_not_meeting_goals$counter <- 1

agg_year <- aggregate(districts_not_meeting_goals$counter, by=list(districts_not_meeting_goals$contract_end_year), FUN=sum, na.rm=T)
names(agg_year) <- c('year', 'count')
agg_year$total <- sum(districts_not_meeting_goals$counter)
agg_year$perc <- round((agg_year$count / agg_year$total) * 100, 0)

## histogram of contract end time
pdf("contract_end_date_districts_not_meting.pdf", height=5, width=7)
p.contract <- ggplot(agg_year, aes(x=year, y=count))
p.contract + geom_bar(stat = "identity", fill="#009296") +
  ylab("Number of districts")+
  #xlab("Years until contract end of soonest expiring internet contract")+
  xlab("Contract End Year")+
  scale_x_continuous(breaks = c(2018,2019,2020))+ 
  ylim(c(0,420))+
  geom_text(aes(label = paste(perc, "%", sep=" ")), vjust = -.5) +
  #geom_text(aes(label = scales::percent(..prop..),
  #               y= ..prop.. ), stat= "count", vjust = -.5)+
  ggtitle("Districts Not Meeting Goals") +
  theme_bw()+
  theme(plot.title = element_text(size = 15, face = "bold"),
        panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))
dev.off()
