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
source("../../General_Resources/common_functions/source_env.R")
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

dd.2017 <- querydb(paste(github_path, "General_Resources/sql_scripts/2017_deluxe_districts.SQL", sep=""))

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## TESTING AGGREGATE

dd.2017.all <- dd.2017
dd.2017.all$counter <- 1
length(unique(dd.2017.all$esh_id))
dd.2017 <- dd.2017.all[which(dd.2017.all$include_in_universe_of_districts == 't'),]
dd.2017.upgrade <- dd.2017.all[which(dd.2017.all$include_in_universe_of_districts == 't' & dd.2017.all$upgrade_indicator == 't'),]
dd.2017.bw.sub <- dd.2017.all[which(dd.2017.all$include_in_universe_of_districts == 't' & dd.2017.all$meeting_2014_goal_no_oversub == 't'),]
dd.2017.afford.sub <- dd.2017.all[which(dd.2017.all$include_in_universe_of_districts == 't' & dd.2017.all$meeting_knapsack_affordability_target == 't'),]

districts.pop <- aggregate(dd.2017.all$counter, by=list(dd.2017.all$postal_cd), FUN=sum, na.rm=T)
schools.pop <- aggregate(dd.2017.all$num_schools, by=list(dd.2017.all$postal_cd), FUN=sum, na.rm=T)
students.pop <- aggregate(dd.2017.all$num_students, by=list(dd.2017.all$postal_cd), FUN=sum, na.rm=T)

districts <- aggregate(dd.2017$counter, by=list(dd.2017$postal_cd), FUN=sum, na.rm=T)
schools <- aggregate(dd.2017$num_schools, by=list(dd.2017$postal_cd), FUN=sum, na.rm=T)
students <- aggregate(dd.2017$num_students, by=list(dd.2017$postal_cd), FUN=sum, na.rm=T)

districts.upgrade <- aggregate(dd.2017.upgrade$counter, by=list(dd.2017.upgrade$postal_cd), FUN=sum, na.rm=T)
schools.upgrade <- aggregate(dd.2017.upgrade$num_schools, by=list(dd.2017.upgrade$postal_cd), FUN=sum, na.rm=T)
students.upgrade <- aggregate(dd.2017.upgrade$num_students, by=list(dd.2017.upgrade$postal_cd), FUN=sum, na.rm=T)

districts.meeting.bw <- aggregate(dd.2017.bw.sub$counter, by=list(dd.2017.bw.sub$postal_cd), FUN=sum, na.rm=T)
schools.meeting.bw <- aggregate(dd.2017.bw.sub$num_schools, by=list(dd.2017.bw.sub$postal_cd), FUN=sum, na.rm=T)
students.meeting.bw <- aggregate(dd.2017.bw.sub$num_students, by=list(dd.2017.bw.sub$postal_cd), FUN=sum, na.rm=T)

districts.meeting.afford <- aggregate(dd.2017.afford.sub$counter, by=list(dd.2017.afford.sub$postal_cd), FUN=sum, na.rm=T)
schools.meeting.afford <- aggregate(dd.2017.afford.sub$num_schools, by=list(dd.2017.afford.sub$postal_cd), FUN=sum, na.rm=T)
students.meeting.afford <- aggregate(dd.2017.afford.sub$num_students, by=list(dd.2017.afford.sub$postal_cd), FUN=sum, na.rm=T)


##*********************************************************************************************************
## DEPLOY TOOL

options(repos=c(CRAN="https://cran.rstudio.com"))
rsconnect::setAccountInfo(name='educationsuperhighway',
                            token='0199629F81C4DEC2466F106048613D4E',
                            secret='AZuGIeV6axGnzmBI1GQ6hFLdHN0ojUaA+U/wi8YT')
rsconnect::deployDoc("tool/2017_State_Metrics_Dashboard.Rmd")


