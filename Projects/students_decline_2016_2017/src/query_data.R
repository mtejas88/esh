## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

args = commandArgs(trailingOnly=TRUE)
github_path <- args[1]

## load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv","xlsx")
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

source_env_Frozen <- function(path){
  load_dot_env(path)
  ## assign url for DB if available
  if (Sys.getenv("F_URL") != ""){
    assign("f_url", Sys.getenv("F_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("F_USER") != ""){
    assign("f_user", Sys.getenv("F_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("F_PASSWORD") != ""){
    assign("f_password", Sys.getenv("F_PASSWORD"), envir=.GlobalEnv)
  }
}
source_env_Frozen("~/.env")


##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=f_url, user=f_user, password=f_password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dd_2017 = dbGetQuery(con, 
"select esh_id, num_students from 
public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
")
dd_2016 = dbGetQuery(con, 
"select esh_id, num_students from 
public.fy2016_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
")

schools_demog = dbGetQuery(con, 
"select * from public.fy2016_schools_demog_matr
")

## disconnect from database
dbDisconnect(con)

## get salesforce modified schools

require(xlsx)
sfdc=read.xlsx("../data/raw/Facility and Account Field History_8.29.17.xlsx", sheetName = "Facility Changes")
sfdc$Facility.ESHID=as.character(sfdc$Facility.ESHID)

##**************************************************************************************************************************************************
## write out the datasets

write.csv(dd_2016, "../data/interim/dd_2016.csv", row.names=F)
write.csv(dd_2017, "../data/interim/dd_2017.csv", row.names=F)
write.csv(schools_demog, "../data/interim/schools_demog.csv", row.names=F)
write.csv(sfdc, "../data/interim/sfdc.csv", row.names=F)