### SQL Console ###
library("RPostgreSQL")
library(sqldf)
setwd("C:/Users/Justine/Desktop")
setwd("C:/Users/Justine/Documents/SQL")
setwd("C:/Users/Justine/Documents/R")

### Connect to DB ###
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, host = "ec2-54-197-244-216.compute-1.amazonaws.com", port = 5572,
                 dbname = "daddkut7s5671q", user = "u3v583a3p2pp85", 
                 password = "p6omsea0tv60mlfjnosesb7ereu")



    pg_dsn = paste0(
        'dbname=', "daddkut7s5671q", ' ',
        'sslmode=verify-full'
    )
    
    dbConnect(RPostgreSQL::PostgreSQL(), dbname=pg_dsn, 
                  host = "ec2-54-204-38-194.compute-1.amazonaws.com", port = 5572,
                  user = "u3v583a3p2pp85", password = "p6omsea0tv60mlfjnosesb7ereu")

### Function for queries
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  View(data)
  data
}

### Queries ###
dbListFields(con, "districts")
dbListTables(con)
alldata <- querydb("Test_SQL.sql")
joined_allo <- querydb("allo_district_join.sql")


### Disconnect - always run at end of session ###
dbListConnections(drv)
dbDisconnect(con)

dbDisconnect(dbListConnections(drv)[[1]])
dbDisconnect(dbListConnections(drv)[[2]])

dbUnloadDriver(drv)

### Code ###
    ###Basic###
    c() ###vector of same data types
    c[position] ###one of the pieces of a vector
    list() ###vector of different data types
    list$variable ###one of the pieces of a list
    example("mean") ###gives an example of a function
    ###"apply" functions apply any of these functions to an entire array
    
    ###importing###
    DT_NH_clean <- read.csv("~/R/DT_NH_clean.csv") ##import csv
    View(DT_NH_clean) ##view csv
    summary(DT_NH_clean$highest_connect_type) ##count types in a column, percentiles if numeric
    
    ###numeric defining###
    seq(1,10,by=3) ##gives an array counting 1-10 by 3
    seq(1,10,length=5) ##gives an array counting 1-10, only length of 5
    
    ###string manipulation###
    any(x == "c") ###boolean of whether "c" is in array x
    grepl("[c!]", x)  ###boolean of whether ("%c%" or "%!%") is in array x
    
    which(x == "c") ###spot of where "c" is located in array x
    grep("c", x)  ###spot of where "%c%" is located in array x
    grep("[c!]", x)  ###spot of where ("%c%" or "%!%") is located in array x
    
    all(x == "c") ###checks if all of the elements of x are "c"
    
    paste("Hello", "World", sp = " ") ###concat with a "space" between (or specified character)
    strsplit("Hello World", split = " ") ##split into array
    substring("Hello World", 1, 5) ##get string between 1-5
    as.numeric(gsub(",","",totalcost)) ###to remove commas from string numbers and then convert
    
    
###Exercise###    
    districts <- read.csv("districts.csv", as.is = TRUE)
    names(districts)
    head(districts)
    districts$X <- NULL ### this deletes the column you don't want
    table(districts$internet_sp) ###"Illimois" exists in SP name!!!
    districts$internet_sp <- gsub("Illimois", "Illinois",districts$internet_sp)
    districts_fiber <- districts[grep("fiber",districts$all_ia_connectcat, ignore.case = TRUE),]
    View(districts_fiber)

    
