# clear the console
cat("\014")

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

#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/Documents/Analysis/ficher/'
setwd(paste(github_path, 'Projects/USAC_data_comparisons', sep=''))


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

esh_li <- querydb('src/esh_li.sql')
original_frns <- querydb('src/original_frns.sql')
esh_allocations <- querydb('src/esh_allocations.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(esh_li, 'data/raw/fy2016_line_items.csv', row.names = FALSE)
write.csv(original_frns, 'data/raw/original_frns.csv', row.names = FALSE)
write.csv(esh_allocations, 'data/raw/fy2016_allocations.csv', row.names = FALSE)