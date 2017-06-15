# header
# please refer to https://educationsuperhighway.atlassian.net/wiki/pages/editpage.action?pageId=86605836
# for details on DB access throguh R

# run source code
## set the current directory as the working directory
wd <- setwd(".") 
setwd(wd)

#this is my github path. DONT FORGET TO COMMENT OUT
github_path <- '~/Documents/ESH/ficher/'


## read in libraries
library(rJava)
library(RJDBC)
library(DBI)

## read in functions
func.dir <- "functions/"
func.list <- list.files(func.dir)
for (file in func.list[grepl('.R', func.list)]){
  source(paste(func.dir, file, sep=''))
}

source(paste(github_path, "General_Resources/common_functions/source_env_Staging.R", sep=""))
source_env_Staging("~/.env")

source("sql_script_builder.R")



## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)
## QUERY THE DB -- SQL

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=s_url, user=s_user, password=s_password)

## query function
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## execute function
executedb <- function(script_name) {
  print("made it into the execute block")
  query <- readChar(script_name, file.info(script_name)$size)
  data <- dbExecute(con, query)
  return(data)
}


options(java.parameters = "-Xmx1000m")


##retrieve outlier use cases
outlier_use_cases <- querydb("../sql/retrieve_use_cases.SQL")

new_use_cases <- data.frame("outlier_use_case_cd"=setdiff(master_output$outlier_use_case_cd,outlier_use_cases$outlier_use_case_cd))

print(paste0("length of use cases is...",length(new_use_cases$outlier_use_case_cd)))

if (length(new_use_cases$outlier_use_case_cd) != 0){
  print("New Use Cases Found:")
  print(new_use_cases)
  
  
  dml_script <- dml_builder(new_use_cases,"insert","outlier_use_cases" )
  print("Running the following command")
  print(dml_script)
  
  fileConn<-file(paste0("../sql/insert_outlier_use_case_", Sys.Date(), ".SQL"))
  writeLines(dml_script, fileConn)
  close(fileConn)
  
}else{
  print("No new use cases")
}


insert_error <- tryCatch(dbExecute(con,dml_script),error=function(e) e)
#print(lines_inserted)


## Look for new Outlier Use Cases
print("Loading use case detail candidates")
load_script <- load_candidate_details(master_output,"outlier_use_case_details")

print("Writing Script to file")
scriptName <- paste0("../sql/create_temp_outlier_use_case_detail", Sys.Date(), ".SQL")
fileConn<-file(scriptName)
writeLines(load_script, fileConn, sep = "\n")
close(fileConn)

print("Running Load Script")
insert_error <- tryCatch(executedb(scriptName),error=function(e) e)

print("Determining New Use Cases")
new_use_case_detail_script <- find_new_cases("outlier_use_case_details")
print(new_use_case_detail_script)

print("Writing new use cases sql file")
queryName <- paste0("../sql/retrieve_new_use_case_details_", Sys.Date(), ".SQL")
fileConn<-file(queryName)
writeLines(new_use_case_detail_script, fileConn, sep = "\n")
close(fileConn)

print("Running new use case finder")
new_outlier_use_case_details <- querydb(queryName)
new_outlier_use_case_details <- unique(new_outlier_use_case_details)


print("Inserting New Outlier Use Case Details:")
if (length(new_outlier_use_case_details$outlier_use_case_id) != 0){
  print("New Use Cases Found:")
  print(new_outlier_use_case_details)
  
  
  dml_script_outlier_use_case_details <- dml_builder(new_outlier_use_case_details,"insert","outlier_use_case_details" )
  print("Running the following command")
  print(dml_script_outlier_use_case_details)
  
  fileConn<-file(paste0("../sql/insert_outlier_use_case_details_", Sys.Date(), ".SQL"))
  writeLines(dml_script_outlier_use_case_details, fileConn)
  close(fileConn)
  
}else{
  print("No new use case details")
}

insert_error <- tryCatch(dbExecute(con,dml_script_outlier_use_case_details),error=function(e) e)
dml_script_outlier_use_case_details=NULL

## Look for outliers to upsert
print("Loading use case detail candidates")
load_script <- load_candidate_details(master_output,"outliers")

print("Writing Script to file")
scriptName <- paste0("../sql/create_temp_outlier_", Sys.Date(), ".SQL")

fileConn<-file(scriptName)
writeLines(load_script, fileConn, sep = "\n")
close(fileConn)

print("Running Load Script")
insert_error <- tryCatch(executedb(scriptName),error=function(e) e)

print("Determining New Use Cases")
new_outliers_script <- find_new_cases("outliers")

print("Writing new use cases sql file")
queryName <- paste0("../sql/retrieve_new_outliers_", Sys.Date(), ".SQL")
fileConn<-file(queryName)
writeLines(new_outliers_script, fileConn, sep = "\n")
close(fileConn)

print("Running new use case finder")
new_outliers <- querydb(queryName)
new_outliers <- unique(new_outliers)
 

print("Inserting New Outliers:")
if (length(new_outliers$outlier_use_case_detail_id) != 0){
  print("New Use Cases Found:")
  print(new_outliers)
  
  update_ids <- new_outliers[which(new_outliers$outlier_action =="update"),c("outlier_id")]
  update_ids <- unique(update_ids)
  
  print("Endating existing outliers for updates")
  if(length(update_ids) !=0){
    print("Outliers Id's for update...")
    print(update_ids)
    dml_script_outliers_for_update <- dml_builder(update_ids,"update","outliers" ) 
    
    fileConn<-file(paste0("../sql/update_outliers_", Sys.Date(), ".SQL"))
    writeLines(dml_script_outliers_for_update, fileConn)
    close(fileConn)
  
    insert_error <- tryCatch(dbExecute(con,dml_script_outliers_for_update),error=function(e) e)
    dml_script_outliers_for_update=NULL
  }else{
    print("No updates")
  }

  print("Inserting new outliers")  
  dml_script_outliers <- dml_builder(new_outliers,"insert","outliers" )
  print("Running the following command")
  print(dml_script_outliers)
  
  fileConn<-file(paste0("../sql/insert_outliers_", Sys.Date(), ".SQL"))
  writeLines(dml_script_outliers, fileConn)
  close(fileConn)
  
}else{
  print("No new use cases")
}

insert_error <- tryCatch(dbExecute(con,dml_script_outliers),error=function(e) e)
dml_script_outliers=NULL

print("Deleting outliers that no longer exist in master_output")
del_script <- delete_no_longer_outliers()

print("Writing Script to file")
scriptName <- paste0("../sql/delete_no_longer_outliers", Sys.Date(), ".SQL")
fileConn<-file(scriptName)
writeLines(del_script, fileConn, sep = "\n")
close(fileConn)

print("Running Delete Script")
deteterror=tryCatch(dbSendUpdate(con,del_script),error=function(e) e)

# con <- dbConnect(pgsql, url=s_url, user=s_user, password=s_password)
# table=dbGetQuery(con,"select*from outliers")
# delete_error <- tryCatch(dbSendUpdate(con,"DELETE FROM outliers"),error=function(e) e)
# oucd=dbGetQuery(con,"select*from outlier_use_case_details")
# ouc=dbGetQuery(con,"select*from outlier_use_cases")

# disconnect from database  
dbDisconnect(con)
