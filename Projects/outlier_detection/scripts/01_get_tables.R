
# clear the console
cat("\014")
rm(list=ls())

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

# set up workding directory -- it is currently set up to the folder which contains all scripts
#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/sat_r_programs/R_database_access/'

## source environment variables
source(paste('~/Documents/ESH/ficher/General_Resources/common_functions/', "source_env.R", sep=""))
source_env("~/.env")

##**************************************************************************************************************************************************
## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste('~/Documents/ESH/ficher/General_Resources/postgres_driver/', "postgresql-9.4.1212.jre7.jar", sep=""), "`")
#pgsql <- JDBC("org.postgresql.Driver", "/home/sat/db_utils/R_database_access/postgresql-9.4.1212.jre7.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

crusher_sr_fy2016 <- querydb('../sql/crusher_fy2016_sr.sql')
crusher_dd_fy2016 <- querydb('../sql/crusher_fy2016_dd.sql')
# placeholder for 2017 tables
 crusher_sr_fy2017 <- querydb('../sql/crusher_fy2017_sr.sql')
 crusher_dd_fy2017 <- querydb('../sql/crusher_fy2017_dd.sql')

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************

write.csv(crusher_dd_fy2016, paste0("../data/mode/crusher_dd_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
write.csv(crusher_sr_fy2016, paste0("../data/mode/crusher_sr_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
# placeholder for 2017 tables 
write.csv(crusher_dd_fy2017, paste0("../data/mode/crusher_dd_fy2017_", Sys.Date(), ".csv"), row.names = FALSE)
write.csv(crusher_sr_fy2017, paste0("../data/mode/crusher_sr_fy2017_", Sys.Date(), ".csv"), row.names = FALSE)
