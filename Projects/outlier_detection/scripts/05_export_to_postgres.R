# header
# please refer to https://educationsuperhighway.atlassian.net/wiki/pages/editpage.action?pageId=86605836
# for details on DB access throguh R

# run source code
## set the current directory as the working directory
wd <- setwd(".") 
setwd(wd)

#this is my github path. DONT FORGET TO COMMENT OUT
github_path <-'~/sat_r_programs/R_database_access/'


## read in libraries
library(rJava)
library(RJDBC)
library(DBI)
library(dotenv)

## read in functions
func.dir <- "functions/"
func.list <- list.files(func.dir)
for (file in func.list[grepl('.R', func.list)]){
  source(paste(func.dir, file, sep=''))
}

source_env_Mirror <- function(path){
  load_dot_env(path)
  ## assign url for DB if available
  if (Sys.getenv("P_URL") != ""){
    assign("p_url", Sys.getenv("P_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("P_USER") != ""){
    assign("p_user", Sys.getenv("P_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("P_PASSWORD") != ""){
    assign("p_password", Sys.getenv("P_PASSWORD"), envir=.GlobalEnv)
  }
}
source_env_Mirror("~/.env")

source_env_Test <- function(path){
  load_dot_env(path)
  ## assign url for DB if available
  if (Sys.getenv("T_URL") != ""){
    assign("t_url", Sys.getenv("T_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("T_USER") != ""){
    assign("t_user", Sys.getenv("T_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("T_PASSWORD") != ""){
    assign("t_password", Sys.getenv("T_PASSWORD"), envir=.GlobalEnv)
  }
}
source_env_Test("~/.env")

source("sql_script_builder.R")



## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)
## QUERY THE DB -- SQL

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste('~/Documents/ESH/ficher/General_Resources/postgres_driver/', "postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=p_url, user=p_user, password=p_password)

## query function
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

## execute function
executedb <- function(script_name) {
  query <- readChar(script_name, file.info(script_name)$size)
  data <- dbExecute(con, query)
  return(data)
}


options(java.parameters = "-Xmx1000m")


##retrieve outlier use cases
outlier_use_cases <- querydb("../sql/retrieve_use_cases.SQL")

new_use_cases <- data.frame("outlier_use_case_cd"=setdiff(master_output$outlier_use_case_cd,outlier_use_cases$outlier_use_case_cd))

if (length(new_use_cases$outlier_use_case_cd) != 0){

  dml_script <- dml_builder(new_use_cases,"insert","outlier_use_cases" )

  fileConn<-file(paste0("../sql/insert_outlier_use_case_", Sys.Date(), ".SQL"))
  writeLines(dml_script, fileConn)
  close(fileConn)

}else{
  print("No new use cases")
}


insert_error <- tryCatch(dbExecute(con,dml_script),error=function(e) e)


## Look for new Outlier Use Cases
load_script <- load_candidate_details(master_output,"outlier_use_case_details")

scriptName <- paste0("../sql/create_temp_outlier_use_case_detail", Sys.Date(), ".SQL")
fileConn<-file(scriptName)
writeLines(load_script, fileConn, sep = "\n")
close(fileConn)

insert_error <- tryCatch(executedb(scriptName),error=function(e) e)

new_use_case_detail_script <- find_new_cases("outlier_use_case_details")

queryName <- paste0("../sql/retrieve_new_use_case_details_", Sys.Date(), ".SQL")
fileConn<-file(queryName)
writeLines(new_use_case_detail_script, fileConn, sep = "\n")
close(fileConn)

new_outlier_use_case_details <- querydb(queryName)
new_outlier_use_case_details <- unique(new_outlier_use_case_details)


#print("Inserting New Outlier Use Case Details:")
if (length(new_outlier_use_case_details$outlier_use_case_id) != 0){


  dml_script_outlier_use_case_details <- dml_builder(new_outlier_use_case_details,"insert","outlier_use_case_details" )


  fileConn<-file(paste0("../sql/insert_outlier_use_case_details_", Sys.Date(), ".SQL"))
  writeLines(dml_script_outlier_use_case_details, fileConn)
  close(fileConn)

}else{
  print("No new use case details")
}

insert_error <- tryCatch(dbExecute(con,dml_script_outlier_use_case_details),error=function(e) e)
dml_script_outlier_use_case_details=NULL

## Look for outliers to upsert
load_script <- load_candidate_details(master_output,"outliers")

scriptName <- paste0("../sql/create_temp_outlier_", Sys.Date(), ".SQL")

fileConn<-file(scriptName)
writeLines(load_script, fileConn, sep = "\n")
close(fileConn)


insert_error <- tryCatch(executedb(scriptName),error=function(e) e)

new_outliers_script <- find_new_cases("outliers")

queryName <- paste0("../sql/retrieve_new_outliers_", Sys.Date(), ".SQL")
fileConn<-file(queryName)
writeLines(new_outliers_script, fileConn, sep = "\n")
close(fileConn)

new_outliers <- querydb(queryName)
new_outliers <- unique(new_outliers)


if (length(new_outliers$outlier_use_case_detail_id) != 0){

  update_ids <- new_outliers[which(new_outliers$outlier_action =="update"),c("outlier_id")]
  update_ids <- unique(update_ids)

  if(length(update_ids) !=0){
    dml_script_outliers_for_update <- dml_builder(update_ids,"update","outliers" )

    fileConn<-file(paste0("../sql/update_outliers_", Sys.Date(), ".SQL"))
    writeLines(dml_script_outliers_for_update, fileConn)
    close(fileConn)

    insert_error <- tryCatch(dbExecute(con,dml_script_outliers_for_update),error=function(e) e)
    dml_script_outliers_for_update=NULL
  }else{
    print("No updates")
  }

  dml_script_outliers <- dml_builder(new_outliers,"insert","outliers" )

  fileConn<-file(paste0("../sql/insert_outliers_", Sys.Date(), ".SQL"))
  writeLines(dml_script_outliers, fileConn)
  close(fileConn)

}else{
  print("No new use cases")
}

insert_error <- tryCatch(dbExecute(con,dml_script_outliers),error=function(e) e)
dml_script_outliers=NULL

print("Endating no longer outliers")
insert_error=tryCatch(dbExecute(con,update_no_longer_outliers('no longer found')),error=function(e) e)
print('no longer found done')
insert_error=tryCatch(dbExecute(con,update_no_longer_outliers('matches 2016')),error=function(e) e)
print('matches 2016 done')
insert_error=tryCatch(dbExecute(con,update_no_longer_outliers('cost exclude')),error=function(e) e)
print('cost exclude done')

print("Updating Tableau District Table")
dml_script_tableaud_for_update <- dml_builder(c(),"update","tableau_district" )
insert_error <- tryCatch(dbExecute(con,dml_script_tableaud_for_update),error=function(e) e)
dml_script_tableaud_for_update=NULL
dml_scripts_tableaud_for_insert <- dml_builder(ucd,"insert","tableau_district" )
for(i in 1:length(dml_scripts_tableaud_for_insert)) {
  insert_error <- tryCatch(dbExecute(con,dml_scripts_tableaud_for_insert[[i]]),error=function(e) e)
}
dml_scripts_tableaud_for_insert=NULL

print("Updating Tableau Line Item Table")
dml_script_tableaul_for_update <- dml_builder(c(),"update","tableau_line_item" )
insert_error <- tryCatch(dbExecute(con,dml_script_tableaul_for_update),error=function(e) e)
dml_script_tableaul_for_update=NULL
dml_script_tableaul_for_insert <- dml_builder(li_distributions,"insert","tableau_line_item" )
insert_error <- tryCatch(dbExecute(con,dml_script_tableaul_for_insert),error=function(e) e)
dml_script_tableaul_for_insert=NULL

# disconnect from database  
dbDisconnect(con)
