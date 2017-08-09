
# clear the console
cat("\014")
rm(list=ls())

packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv","dplyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

library(rJava)
library(RJDBC)
library(DBI)
library(dotenv)
library(dplyr)

##function to source the environment variables for the QA DB - the variables need to be added to you .env
source_env_Test <- function(path){
  load_dot_env(path)
  ## assign url for DB if available
  if (Sys.getenv("QA_URL") != ""){
    assign("qa_url", Sys.getenv("QA_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("QA_USER") != ""){
    assign("qa_user", Sys.getenv("QA_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("QA_PASSWORD") != ""){
    assign("qa_password", Sys.getenv("QA_PASSWORD"), envir=.GlobalEnv)
  }
}
source_env_Test("~/.env")

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste('~/Documents/ESH/ficher/General_Resources/postgres_driver/', "postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=qa_url, user=qa_user, password=qa_password)

options(java.parameters = "-Xmx1000m")

## retrieve list of all service provider reporting names
reporting_names=as.data.frame(dbGetQuery(con,"select reporting_name from public.fy2017_services_received_matr group by 1 order by 1;"))
reporting_names=as.data.frame(reporting_names[2:nrow(reporting_names),])
names(reporting_names)=c("reporting_name")

## load raw list from DQT
overrides=read.csv("data/raw/Large and Mega Review - 2017.csv", header=T, as.is=T)

## replace non-names
overrides$Dominant.SP=ifelse(grepl("clean", tolower(overrides$Dominant.SP)), "", 
                             (ifelse(tolower(overrides$Dominant.SP) %in% c("dirty", "none", "unknown","nonerate line","charter and att"), "",
                              overrides$Dominant.SP)))

sum(overrides$Dominant.SP=="") #191

## filter them out
overrides_filled=overrides %>% filter(Dominant.SP!="")

## replace service provider in overrides that matches EXACTLY with a reporting name with the exact reporting name
overrides_filled$lowered=tolower(gsub("[[:punct:]]", "", overrides_filled$Dominant.SP))
reporting_names$lowered=tolower(gsub("[[:punct:]]", "", reporting_names$reporting_name))

reporting_names = reporting_names %>% filter(reporting_name!="ATT")

merged=merge(overrides_filled,reporting_names,by="lowered",all.x=T)
merged=merged %>% filter(reporting_name != "")

final_merge=unique(merge(overrides_filled,merged,by="esh_id"))

  #add column to indicate if matching reporting name
overrides_filled <- overrides_filled[order(overrides_filled$Dominant.SP),] 

overrides_filled$is_reporting_name=
  ifelse(overrides_filled$esh_id %in% final_merge$esh_id,1,0)

overrides_filled$Dominant.SP[overrides_filled$is_reporting_name==1]=
  sort(as.character(final_merge[final_merge$esh_id %in% overrides_filled$esh_id,'reporting_name']))

## Low hanging fruit/adhoc
overrides_filled$Dominant.SP=ifelse(overrides_filled$lowered %in% c("timwarner", "time warner"), "Time Warner Cable Business LLC",
                                     overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$Dominant.SP %in% c("AT&T Corp."), "AT&T",
                                    overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("comcast", overrides_filled$lowered), "Comcast", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$lowered=="icn", "ICN - Integrated Communication Networks Inc.", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$lowered=="la county office of education lacoe", "LACOE", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$lowered %in% c("sunesys", "susesys"), "Sunesys, LLC",
                                    overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("wavedivision", overrides_filled$lowered), "WAVEDIVISION", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("wilshire connection", overrides_filled$lowered), "Wilshire Connection", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("city of palo alto", overrides_filled$lowered), "City of Palo Alto", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("city of seattle", overrides_filled$lowered), "City of Seattle", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$Dominant.SP %in% c('Charter Communications','Charter Fiberlink CA-CCO, LLC'), "Charter", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("consolidated communications", overrides_filled$lowered), "Consolidated Comm", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("cox", overrides_filled$lowered), "Cox", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(overrides_filled$Dominant.SP %in% c('NCDPI'), "NC Office", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("pacific bell", overrides_filled$lowered), "AT&T", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("wisconsin bell", overrides_filled$lowered), "AT&T", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("ventura coe", overrides_filled$lowered), "VCedNet", overrides_filled$Dominant.SP)

overrides_filled$Dominant.SP=ifelse(grepl("alameda", overrides_filled$lowered), "Alameda Co Office", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("bright", overrides_filled$lowered), "Bright House Net", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("brown county", overrides_filled$lowered), "Brown County", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("butte county", overrides_filled$lowered), "Butte County", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("cablevision", overrides_filled$lowered), "Cablevision", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("centurylink centurytel", overrides_filled$lowered), "CenturyLink", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("centurylink qwest", overrides_filled$lowered), "CenturyLink Qwest", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("contra costa", overrides_filled$lowered), "Contra Costa", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("foothills", overrides_filled$lowered), "Foothills", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("fresno", overrides_filled$lowered), "Fresno County", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("kings", overrides_filled$lowered), "Kings County", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("metropolitcan", overrides_filled$lowered), "Metropolitan Ed", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("northern illinois", overrides_filled$lowered), "Northern Illinois", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("san luis obispo", overrides_filled$lowered), "San Luis Obispo", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("santa cruz", overrides_filled$lowered), "Santa Cruz", overrides_filled$Dominant.SP)
overrides_filled$Dominant.SP=ifelse(grepl("solano", overrides_filled$lowered), "Solano Co", overrides_filled$Dominant.SP)

## Add one back
overrides_filled=overrides_filled[,1:10]
overrides_filled=rbind(overrides_filled,overrides[overrides$esh_id==949585,])
overrides_filled$Dominant.SP[overrides_filled$esh_id==949585]="OARnet"

## Corrent connectivity goals
overrides_filled$Connectivity.goal.override=ifelse(grepl("not meeting", tolower(overrides_filled$Connectivity.goal.override)), 'FALSE', 
                                                   ifelse(overrides_filled$Connectivity.goal.override !="", 'TRUE','NULL'))

#**************************************************************************************************
## CREATE AND INSERT INTO POSTGRES TABLE - doesn't work, had to use Excel

script <- 
"CREATE TABLE public.large_mega_dqt_overrides (
esh_id INTEGER PRIMARY KEY ,
postal_cd varchar(2),
name varchar(250),
district_size varchar(100),
num_schools integer,
num_students integer,
status_2017 varchar(50),
status_2016 varchar(50),
service_provider_assignment varchar(250),
connectivity_goal_override boolean,
create_dt timestamp NOT NULL,
end_dt timestamp
); 

insert into public.large_mega_dqt_overrides values "

script_values <- paste("(",overrides_filled$esh_id,",'",
                       overrides_filled$postal_cd,"','",
                       overrides_filled$name,"','",
                       overrides_filled$district_size,"',",
                       overrides_filled$num_schools,",",
                       overrides_filled$num_students,",'",
                       overrides_filled$status_2017,"','",
                       overrides_filled$status_2016,"','",
                       overrides_filled$Dominant.SP,"',",
                       overrides_filled$Connectivity.goal.override,",",
                       "current_timestamp,",
                       "NULL","),",sep="",collapse="\n")

script <- paste0(script,substr(script_values,1,nchar(script_values)-1),";")

fileConn<-file("create_table.sql")
writeLines(script, fileConn)
close(fileConn)
