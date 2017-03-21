# header
# please refer to https://educationsuperhighway.atlassian.net/wiki/pages/editpage.action?pageId=86605836
# for details on DB access throguh R

# run source code
wd <- "~/Documents/Saptarshi/EducationSuperHighway/R/outlier_detection/scripts/db/"
source(paste0(wd, "database_setup.R"))

# run a query 
options(java.parameters = "-Xmx1000m")
crusher_sr_fy2016 <- querydb("crusher_fy2016_sr.SQL")
crusher_dd_fy2016 <- querydb("crusher_fy2016_dd.SQL")

# disconnect from database  
dbDisconnect(con)

# export
export_dir <- "~/Documents/Saptarshi/EducationSuperHighway/R/outlier_detection/data/mode/"
# services received
write.csv(crusher_dd_fy2016, paste0(export_dir, "crusher_dd_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
write.csv(crusher_sr_fy2016, paste0(export_dir, "crusher_sr_fy2016_", Sys.Date(), ".csv"), row.names = FALSE)
#write.csv(crusher_sr_fy2016, paste0(export_dir, "crusher_sr_fy2016_frozen.csv"), row.names = FALSE)

# reset working directory
# set up workding directory
wd <- "~/Documents/Saptarshi/EducationSuperHighway/R/outlier_detection/scripts/"
setwd(wd)
