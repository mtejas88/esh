## =========================================
##
## PLOT MAJOR SPs
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/visulizations/")

## load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv", "plotly")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)
library(plotly)
options(java.parameters = "-Xmx4g" )

## source environment variables
source("../../General_Resources/common_functions/source_env.R")
source_env("~/.env")

## source function to correct dataset
source("../../General_Resources/common_functions/correct_dataset.R")

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## Connect to current DB -- ONYX
con <- dbConnect(pgsql, url=url, user=user, password=password)

sp_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_service_providers_agg.SQL")
sp_2016 <- querydb("../../General_Resources/sql_scripts/2016/2016_service_providers_agg.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## create subset

sp_2017 <- sp_2017[order(sp_2017$students_population, decreasing=T),]
sp_2016 <- sp_2016[order(sp_2016$students_population, decreasing=T),]

names(sp_2016)[names(sp_2016) == 'median_ia_monthly_cost_per_mbps'] <- 'median_ia_monthly_cost_per_mbps_2016'

dta <- merge(sp_2017[,c('service_provider_assignment', 'median_ia_monthly_cost_per_mbps',
                        'students_clean_ia_sample', 'students_meeting_2014_bw_goal',
                        'districts_clean_ia_sample', 'districts_meeting_2014_bw_goal')],
             sp_2016[,c('service_provider_assignment', 'median_ia_monthly_cost_per_mbps_2016')],
             by='service_provider_assignment', all.x=T)

## calculate percentage of students not meeting goal
dta$students_not_meeting_2014_bw_goal <- dta$students_clean_ia_sample - dta$students_meeting_2014_bw_goal
dta$students_not_meeting_2014_bw_goal_perc <- dta$students_not_meeting_2014_bw_goal / dta$students_clean_ia_sample

#plot(dta$median_ia_monthly_cost_per_mbps, dta$median_ia_monthly_cost_per_mbps_2016, pch=16,
#     xlim=c(0,100), ylim=c(0,100), xlab="Cost per Mbps (2016)", ylab="Cost per Mbps (2017)",
#     cex)

p <- plot_ly(dta, x=~median_ia_monthly_cost_per_mbps, y=~median_ia_monthly_cost_per_mbps_2016,
             text=~service_provider_assignment, type='scatter', mode='markers',
             color=~students_not_meeting_2014_bw_goal_perc, colors='Reds',
             marker=list(size=~(districts_clean_ia_sample/10), opacity=0.7)) %>%
  layout(title = 'Service Provider Landscape',
         xaxis = list(showgrid = FALSE, range=c(0,50)),
         yaxis = list(showgrid = FALSE, range=c(0,50)))

p




