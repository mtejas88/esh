## ==============================================================================================================================
##
## REFRESH STATE METRICS
##
## Refreshes the State Metrics with the new data, stores the data, and deploys the tool.
## To be used for the interactive state metrics tool devloped by Sujin, edited by Adrianna
##
## C2 info comes from two sources:
## 1) Current: https://modeanalytics.com/educationsuperhighway889/reports/0111c885c5aa/runs/310bd53edaa7
## 2) SoTS: \Google Drive\ESH Main Share\Strategic Analysis Team\Archived\2015\State of the States\State Snapshot\Final Workbooks\state_snap_static_1112 FINAL.xlsx, Summary tab, column AR
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

## set the current directory as the working directory
wd <- setwd(".") 
setwd(wd)

## install packages
#install.packages("DBI", repos="http://cran.rstudio.com/")
#install.packages("rJava", repos="http://cran.rstudio.com/")
#install.packages("RJDBC", repos="http://cran.rstudio.com/")

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
source("../../../R_database_access/db_credentials.R")

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
weekday <- weekdays(date)
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

##*********************************************************************************************************
## OPTIONS

## set 1 to also deploy state metric tool
deploy <- 1

## option to revert the tool to the previous data
revert <- 0

##*********************************************************************************************************
## QUERY THE DB -- SQL

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../../R_database_access/postgresql-9.4.1212.jre7.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name) {
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dd.2015 <- querydb("../../../R_database_access/SQL Scripts/2015_deluxe_districts_crusher_materialized.SQL")
fiber.2015 <- querydb("../../../R_database_access/SQL Scripts/2015_current_fiber_metrics.SQL")
ds.2015 <- querydb("../../../R_database_access/SQL Scripts/2015_deluxe_schools_crusher_materialized.SQL")
dd.2016 <- querydb("../../../R_database_access/SQL Scripts/2016_deluxe_districts_crusher_materialized.SQL")
ds.2016 <- querydb("../../../R_database_access/SQL Scripts/2016_deluxe_schools_crusher_materialized.SQL")

## Combine 2015 fiber metrics with 2015 DD
## take out ia_monthly_cost columns, except for "ia_monthly_cost"
monthly.cost.cols <- names(fiber.2015)[grepl("ia_monthly_cost", names(fiber.2015))]
monthly.cost.cols <- monthly.cost.cols[monthly.cost.cols != "ia_monthly_cost"]
fiber.2015 <- fiber.2015[,!names(fiber.2015) %in% monthly.cost.cols]
## also take out columns that already exist in dd.2015
fiber.2015 <- fiber.2015[,names(fiber.2015)[!names(fiber.2015) %in% names(dd.2015)]]
## sub in the new 2015 fiber files for the old ones in dd.2015
dd.2015 <- merge(dd.2015, fiber.2015, by.x='esh_id', by.y='district_esh_id', all.x=T)
dd.2015$ia_monthly_cost <- NULL

## correct the columns
dd.2015 <- correct.dataset(dd.2015, sots.flag = 0, services.flag = 0)
ds.2015 <- correct.dataset(ds.2015, sots.flag = 0, services.flag = 0)
dd.2016 <- correct.dataset(dd.2016, sots.flag = 0, services.flag = 0)
ds.2016 <- correct.dataset(ds.2016, sots.flag = 0, services.flag = 0)

## disconnect from database
dbDisconnect(con)

##*********************************************************************************************************
## READ IN DATA

## read in State of the States 2015 published data
sots.2015 <- read.csv("../data/raw/aggregated_metrics/2015_state_of_the_states.csv", as.is=T, header=T, stringsAsFactors=FALSE)
sots.2015.ranks <- read.csv("../data/raw/aggregated_metrics/sots15_ranks.csv", as.is=T, header=T, stringsAsFactors=FALSE)
sots.districts.2015 <- read.csv("../data/raw/deluxe_districts/2015_state_of_the_states_districts.csv", as.is=T, header=T, stringsAsFactors=FALSE)
#sots.sr.2015 <- read.csv("../data/raw/services_received/2015_state_of_the_states_services_received.csv", as.is=T, header=T, stringsAsFactors=FALSE)

## read in C2 info
## current 2015 & 2016
c2.current <- read.csv("../data/raw/c2/all_things_c2_fy_2015_and_2016-query_2016-11-03.csv", as.is=T, header=T, stringsAsFactors=FALSE)
c2.sots <- read.csv("../data/raw/c2/C2_state-of-the-states.csv", as.is=T, header=T, stringsAsFactors=FALSE)

## correct the columns
sots.districts.2015 <- correct.dataset(sots.districts.2015, sots.flag = 1, services.flag = 0)

##*********************************************************************************************************
## CALCULATE METRICS BY SOURCING FUNCTIONS

## make sure to subset to include_in_universe_of_districts first for 2016
dd.2016 <- dd.2016[dd.2016$include_in_universe_of_districts == TRUE,]
dd.2016 <- dd.2016[!dd.2016$district_type %in% c("BIE", "Charter"),]
dd.2016 <- dd.2016[!duplicated(dd.2016$esh_id),]
## take out DC in both years
#dd.2016 <- dd.2016[dd.2016$postal_cd != 'DC',]
#dd.2015 <- dd.2015[dd.2015$postal_cd != 'DC',]
## sub in "Small" to "Town"
dd.2016$locale[grepl("Town", dd.2016$locale)] <- gsub("Town", "Small Town", dd.2016$locale[grepl("Town", dd.2016$locale)])
## format service provider information
dd.2015 <- combine.sp(dd.2015)
dd.2016 <- combine.sp(dd.2016)
## fix dd.2015 monthly_ia_cost_per_mbps
dd.2015$ia_monthly_cost_per_mbps <- suppressWarnings(as.numeric(dd.2015$monthly_ia_cost_per_mbps, na.rm=T))

## merge in extra information for schools-level analysis
ds.2015 <- merge(ds.2015, dd.2015[,c('esh_id', 'locale', 'district_size', 'district_type', "address", "city", "zip",
                                    "frl_percent", "num_internet_upstream_lines", "bundled_and_dedicated_isp_sp", 'lines_w_dirty',
                                     "most_recent_ia_contract_end_date", "fiber_internet_upstream_lines")],
                 by.x='district_esh_id', by.y='esh_id', all.x=T)
ds.2016 <- merge(ds.2016, dd.2016[,c('esh_id', 'locale', 'district_size', 'district_type', "address", "city", "zip",
                                     'num_internet_upstream_lines', 'bundled_and_dedicated_isp_sp',
                                     'exclude_from_wan_analysis', 'exclude_from_ia_cost_analysis', 'lines_w_dirty', 'needs_wifi',
                                     "non_fiber_internet_upstream_lines_w_dirty", "fiber_internet_upstream_lines_w_dirty",
                                     "most_recent_ia_contract_end_date", "non_fiber_lines", "fiber_wan_lines", "fiber_internet_upstream_lines")],
                 by.x='district_esh_id', by.y='esh_id', all.x=T)

states.with.schools <- c('DE', 'HI', 'RI')
names(ds.2016)[names(ds.2016) %in% c('district_fiber_target_status', 'district_bw_target_status')] <- c('fiber_target_status', 'bw_target_status')
names(ds.2015)[names(ds.2015) == 'district_esh_id'] <- 'esh_id'
names(ds.2015)[names(ds.2015) == 'district_name'] <- 'name'
names(ds.2016)[names(ds.2016) == 'district_esh_id'] <- 'esh_id'
names(ds.2016)[names(ds.2016) == 'district_name'] <- 'name'

dd.2015 <- dd.2015[,names(dd.2015) %in% names(ds.2015)]
dd.2015$campus_id <- NA
dd.2015$school_esh_ids <- NA
ds.2015 <- ds.2015[,match(names(dd.2015), names(ds.2015))]

dd.2016 <- dd.2016[,names(dd.2016) %in% names(ds.2016)]
dd.2016$campus_id <- NA
dd.2016$school_esh_ids <- NA
ds.2016 <- ds.2016[,match(names(dd.2016), names(ds.2016))]

## assign datasets as masters since they'll get rewritten
dd.2016.master <- dd.2016
ds.2016.master <- ds.2016
dd.2015.master <- dd.2015
ds.2015.master <- ds.2015
sots.districts.2015.master <- sots.districts.2015

## generate dta for each subset: all data, rural, and urban districts
for (i in 1:3){
  print(i)
  if (i == 1){
    dd.2016 <- dd.2016.master
    ds.2016 <- ds.2016.master
    dd.2015 <- dd.2015.master
    ds.2015 <- ds.2015.master
    sots.districts.2015 <- sots.districts.2015.master
    dd.2016 <- dd.2016[dd.2016$locale == 'Rural',]
    ds.2016 <- ds.2016[ds.2016$locale == 'Rural',]
    dd.2015 <- dd.2015[dd.2015$locale == 'Rural',]
    ds.2015 <- ds.2015[ds.2015$locale == 'Rural',]
    sots.districts.2015 <- sots.districts.2015[sots.districts.2015$locale == 'Rural',]
    district.label <- "rural"
  }
  if (i == 2){
    dd.2016 <- dd.2016.master
    ds.2016 <- ds.2016.master
    dd.2015 <- dd.2015.master
    ds.2015 <- ds.2015.master
    sots.districts.2015 <- sots.districts.2015.master
    dd.2016 <- dd.2016[dd.2016$locale == 'Urban',]
    ds.2016 <- ds.2016[ds.2016$locale == 'Urban',]
    dd.2015 <- dd.2015[dd.2015$locale == 'Urban',]
    ds.2015 <- ds.2015[ds.2015$locale == 'Urban',]
    sots.districts.2015 <- sots.districts.2015[sots.districts.2015$locale == 'Urban',]
    district.label <- "urban"
  }
  if (i == 3){
    district.label <- ""
    dd.2016 <- dd.2016.master
    ds.2016 <- ds.2016.master
    dd.2015 <- dd.2015.master
    ds.2015 <- ds.2015.master
    sots.districts.2015 <- sots.districts.2015.master
  }
  
  ## prep dataset
  dta <- data.frame(postal_cd=c(sots.2015$postal_cd, "DC", "ALL"), state_name=c(sots.2015$state.name, "DC", "National"))
  
  ## call on functions to calculate stats
  population_and_samples(sots.2015, sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools)
  upgrades(dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools)
  connectivity(sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, dd.clean.compare, dd.2016.with.2015.leftover, states.with.schools)
  fiber(sots.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools)
  affordability(sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools)
  wifi(sots.2015, dd.2016, ds.2016, dta, c2.sots, c2.current, states.with.schools)
  
  ## reorder dta alphabetically by state
  ## first, take out national number
  national.dta <- dta[dta$postal_cd == 'ALL',]
  dta <- dta[dta$postal_cd != 'ALL',]
  ## order the dataset
  dta <- dta[order(dta$postal_cd),]
  ## add back in the national number
  dta <- rbind(dta, national.dta)
  ## make sure DC is out
  dta <- dta[dta$postal_cd != 'DC',]
  ## adjust the school level metrics
  dta <- adjust.school.level.metrics(dta, states.with.schools, dd.clean.compare, i)
  
  assign(paste("dta", district.label, sep=''), dta)
}

## also merge in the published numbers for SotS
published.sots.2015(dta, sots.2015)

## create the exportable snapshot dataset
snapshots(dta, dtarural, dtaurban)

##*********************************************************************************************************
## WRITE OUT FILES

if (weekday == 'Monday'){
  ## deluxe districts
  write.csv(dd.2015, paste("../data/raw/deluxe_districts/2015-districts-deluxe-crusher-materialized-", date, ".csv", sep=''), row.names=F)
  write.csv(ds.2015, paste("../data/raw/deluxe_districts/2015-schools-deluxe-crusher-materialized-", date, ".csv", sep=''), row.names=F)
  write.csv(dd.2016, paste("../data/raw/deluxe_districts/2016-districts-deluxe-endpoint-", date, ".csv", sep=''), row.names=F)
  write.csv(ds.2016, paste("../data/raw/deluxe_districts/2016-schools-deluxe-crusher-materialized-", date, ".csv", sep=''), row.names=F)
}

## LIVE
## also copy over the files to the state metrics tool data directory
tool.data.dir <- "../../tool/data/"
## deluxe districts
write.csv(sots.districts.2015, paste(tool.data.dir, "2015-state-of-the-states-districts.csv", sep=''), row.names=F)
write.csv(dd.2015, paste(tool.data.dir, "2015-districts-deluxe.csv", sep=''), row.names=F)
write.csv(dd.2016, paste(tool.data.dir, "2016-districts-deluxe.csv", sep=''), row.names=F)
## click-throughs
write.csv(current15.click.through.districts, paste(tool.data.dir, "current15_districts_click_through.csv", sep=''), row.names=F)
write.csv(current16.click.through.districts, paste(tool.data.dir, "current16_districts_click_through.csv", sep=''), row.names=F)
write.csv(connectivity.click.through, paste(tool.data.dir, "connectivity_click_through.csv", sep=''), row.names=F)
write.csv(fiber.click.through, paste(tool.data.dir, "fiber_click_through.csv", sep=''), row.names=F)
write.csv(affordability.click.through, paste(tool.data.dir, "affordability_click_through.csv", sep=''), row.names=F)
## targets
write.csv(connectivity.targets, paste(tool.data.dir, "connectivity_targets.csv", sep=''), row.names=F)
write.csv(fiber.targets, paste(tool.data.dir, "fiber_targets.csv", sep=''), row.names=F)
## upgrades
write.csv(dd.clean.compare, paste(tool.data.dir, "districts_upgraded.csv", sep=''), row.names=F)
## master metrics
write.csv(dta, paste(tool.data.dir, "master_metrics.csv", sep=''), row.names=F)
## snapshots
write.csv(snapshot, paste(tool.data.dir, "snapshots.csv", sep=''), row.names=F)
## write out the date from which the data has been updated
write.csv(date, paste(tool.data.dir, "date.csv", sep=''), row.names=F)

##*********************************************************************************************************
## DEPLOY TOOL

if (deploy == 1){
  options(repos=c(CRAN="https://cran.rstudio.com"))
  rsconnect::setAccountInfo(name='educationsuperhighway',
                          token='0199629F81C4DEC2466F106048613D4E',
                          secret='AZuGIeV6axGnzmBI1GQ6hFLdHN0ojUaA+U/wi8YT')
  rsconnect::deployDoc("../../tool/state_metric_dashboard.Rmd")
}
