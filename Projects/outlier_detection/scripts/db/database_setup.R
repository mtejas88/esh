# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

# install packages
#install.packages("rJava", type="source")
#install.packages("RJDBC")

# load packages
# force rJava to load on Mac 10 El Capitan
# dyn.load('/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/jre/lib/server/libjvm.dylib')
options(java.parameters = "-Xmx1000m")
library(rJava)
library(RJDBC)

# load PostgreSQL Driver
#pgsql <- JDBC("org.postgresql.Driver", "~/Google Drive/ESH/DB/postgresql-9.4.1208.jar", "`")
pgsql <- JDBC("org.postgresql.Driver", "~/Documents/Saptarshi/EducationSuperHighway/R/outlier_detection/scripts/db/postgresql-9.4.1209.jar", "`")


#Source DB
source("/Users/saptarshighose/Documents/Saptarshi/EducationSuperHighway/R/Data/db_credentials.R")

# Connect to database - set to ONYX 1/31/2017 FOR REAL
con <- dbConnect(pgsql, url=url, user=user, password=password)


# Query function
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

# set working directory
wd <- "~/Documents/Saptarshi/EducationSuperHighway/R/outlier_detection/scripts/db/sql"
setwd(wd)

view(fy2016_districts_deluxe_matr)

# disconnect from database  
#dbDisconnect(con)

