# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

# install packages
#install.packages("rJava", type="source")
#install.packages("RJDBC")

# load packages
# force rJava to load on Mac 10 El Capitan
dyn.load('/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/jre/lib/server/libjvm.dylib')
library(rJava)
library(RJDBC)

# set working directory
wd <- "~/Google Drive/github/ficher/Shiny/prep_for_Shiny"
setwd(wd)

# load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "postgresql-9.4.1208.jar", "`")

# Connect to database
con <- dbConnect(pgsql, "jdbc:postgresql://ec2-54-204-38-194.compute-1.amazonaws.com:5572/daddkut7s5671q?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory", 
                password ="p6omsea0tv60mlfjnosesb7ereu", user = "u3v583a3p2pp85")

# Query function
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

# disconnect from database  
#dbDisconnect(con)

