## =========================================
##
## QUERY DATA FROM THE DB
## AND COMPARE SAME DATASETS FROM DIFFERENT DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-103_resolve_ficher_mg/")

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
source("../../General_Resources/common_functions/correct_dataset.R")

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
## Districts Deluxe
dd_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts.SQL")
dd_2017 <- correct.dataset(dd_2017, sots.flag=0, services.flag=0)
## Services Received
sr_2017 <- querydb("../../General_Resources/sql_scripts/2017/2017_services_received_crusher_materialized.SQL")
sr_2017 <- correct.dataset(sr_2017, sots.flag=0, services.flag=1)
## disconnect from database
dbDisconnect(con)


## Connect to QA DB
con <- dbConnect(pgsql, url=url_temp, user=user_temp, password=password_temp)
## Districts Deluxe
dd_2017_end <- querydb("../../General_Resources/sql_scripts/2017/2017_deluxe_districts_endpoint.SQL")
dd_2017_end <- correct.dataset(dd_2017_end, sots.flag=0, services.flag=0)
## Services Received
sr_2017_end <- querydb("../../General_Resources/sql_scripts/2017/2017_services_received_endpoint.SQL")
sr_2017_end <- correct.dataset(sr_2017_end, sots.flag=0, services.flag=1)
## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## compare by columns




compare <- function(dta, dta_end, id_col){
  
  ## first, check if the dimensions are the same
  ## rows
  nrow(dta) == nrow(dta_end)
  dta_end[!dta_end[,id_col] %in% dta[,id_col],id_col]
  dta[!dta[,id_col] %in% dta_end[,id_col],id_col]
  
  ## subset to overlapping rows
  dta_end <- dta_end[which(dta_end[,id_col] %in% dta[,id_col]),]
  dta <- dta[which(dta[,id_col] %in% dta_end[,id_col]),]
  
  ## cols
  ncol(dta) == ncol(dta_end)
  names(dta_end)[!names(dta_end) %in% names(dta)]
  names(dta)[!names(dta) %in% names(dta_end)]
  
  ## order the same way
  dta <- dta[order(dta[,id_col]),]
  dta_end <- dta_end[order(dta_end[,id_col]),]
  
  ## subset to overlapping columns
  dta <- dta[,which(names(dta) %in% names(dta_end))]
  dta_end <- dta_end[,which(names(dta_end) %in% names(dta))]
  
  dta.compare <- data.frame(matrix(NA, nrow=nrow(dta), ncol=ncol(dta)))
  names(dta.compare) <- names(dta)
  diff.array <- NULL
  num.diff <- NULL
  
  for (i in 1:ncol(dta)){
    names(dta[,i])
    names(dta_end[,i])
    dta.compare[,i] <- dta[,i] == dta_end[,i]
    if (FALSE %in% dta.compare[,i]){
      diff.array <- append(diff.array, names(dta.compare)[i])
      num.diff <- append(num.diff, nrow(dta.compare[dta.compare[,i]== FALSE,]))
    }
  }
}

compare(dd_2017, dd_2017_end, "esh_id")
compare(sr_2017, sr_2017_end, "line_item_id")

dta <- dd_2017
dta_end <- dd_2017_end

dta.diff <- data.frame(cols=diff.array, num_diff=num.diff)

##**************************************************************************************************************************************************
## write out the datasets

## Districts Deluxe
write.csv(dd_2017, "data/raw/2017_deluxe_districts_ficher.csv", row.names=F)
write.csv(dd_2017_end, "data/raw/2017_deluxe_districts_endpoint.csv", row.names=F)

## Services Received
write.csv(sr_2017, "data/raw/2017_services_received_ficher.csv", row.names=F)
write.csv(sr_2017_end, "data/raw/2017_services_received_endpoint.csv", row.names=F)
