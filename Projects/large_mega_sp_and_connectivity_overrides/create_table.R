packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

library(rJava)
library(RJDBC)
library(DBI)
library(dotenv)

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

##retrieve list of all service provider reporting names
reporting_names=dbGetQuery(con,"select reporting_name from public.fy2017_services_received_matr group by 1 order by 1;")