# header
# please refer to https://educationsuperhighway.atlassian.net/wiki/pages/editpage.action?pageId=86605836
# for details on DB access throguh R

# clear the console
cat("\014")
rm(list=ls())
args = commandArgs(trailingOnly=TRUE)
github_path <- args[1]

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

# set up workding directory -- it is currently set up to the folder which contains all scripts
#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/Documents/Analysis/ficher/'
setwd(paste(github_path, 'Projects/outlier_detection', sep=''))


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

crusher_sr_fy2016 <- querydb('scripts/db/sql/crusher_fy2016_sr.sql')
crusher_dd_fy2016 <- querydb('scripts/db/sql/crusher_fy2016_dd.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

# services received
write.csv(crusher_dd_fy2016, paste0("data/mode/crusher_dd_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
write.csv(crusher_sr_fy2016, paste0("data/mode/crusher_sr_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
