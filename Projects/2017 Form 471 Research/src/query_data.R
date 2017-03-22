# clear the console
cat("\014")

rm(list=ls())

args = commandArgs(trailingOnly=TRUE)
github_path <- args[1]

## load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv", "gridExtra")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)
library(gridExtra)

#this is my github path. DONT FORGET TO COMMENT OUT
#github_path <- '~/Documents/Analysis/ficher/'
setwd(paste(github_path, 'Projects/2017 Form 471 Research', sep=''))


options(java.parameters = "-Xmx4g" )

## source environment variables
source(paste(github_path, "General_Resources/common_functions/source_env.R", sep=""))
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

frn_line_items <- querydb('src/frn_line_items.sql')
basic_informations <- querydb('src/basic_informations.sql')
recipients_of_services <- querydb('src/recipients_of_services.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************


write.csv(frn_line_items, 'data/raw/frn_line_items_2017.csv', row.names = FALSE)
write.csv(basic_informations, 'data/raw/basic_informations_2017.csv', row.names = FALSE)
write.csv(recipients_of_services, 'data/raw/recipients_2017.csv', row.names = FALSE)
