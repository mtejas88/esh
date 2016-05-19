# run source code
wd <- "~/Google Drive/R/DB/"
source(paste0(wd, "database_setup.R"))

# run a query 
deluxe_districts <- querydb("deluxe_districts.SQL")

# list columns in table in the second argument
dbListFields(con, "line_item_flag_notes")

# list tables in the database
dbListTables(con)

# disconnect from database  
dbDisconnect(con)

# Unload Driver
dbUnloadDriver(pgsql)
