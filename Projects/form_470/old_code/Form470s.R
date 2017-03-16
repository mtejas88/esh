## =====================================================================================================
##
## OKR #2: FORM 470
## DEFINE WHETHER A FORM 470 IS MEETING GOALS FOR BOTH IA AND WAN
## EVENTUALLY RUN ON THE AWS SERVER AND MERGED INTO THE DB AND SALESFORCE
##
## =====================================================================================================

## Clearing memory
rm(list=ls())

## running locally or on the server:
local <- 1

## set the current directory as the working directory
if (local == 1){
  setwd("~/Documents/ESH-Code/ficher/Projects/form_470/code/")
} else{
  wd <- setwd(".")
  setwd(wd)
}

## load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava","RJDBC", "dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(rJava)
library(RJDBC)
library(DBI)
library(dotenv)
options(java.parameters = "-Xmx4g" )

## retrieve date (in order to accurately timestamp files)
date <- Sys.time()
date <- gsub("PST", "", date)
date <- gsub(" ", "_", date)
date <- gsub(":", ".", date)

## source function
source("source_env.R")
source_env("~/.env")

source(paste(github_path, "General_Resources/common_functions/correct_dataset.R", sep=""))
source(paste(github_path, "General_Resources/common_functions/db_credentials.R", sep=""))

##*********************************************************************************************************
## QUERY THE DB -- SQL

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", paste(github_path, "General_Resources/R_database_access/postgresql-9.4.1212.jre7.jar", sep=""), "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dta.470 <- querydb(paste(github_path, "General_Resources/SQL Scripts/Form470s.SQL", sep=""))
bens <- querydb(paste(github_path, "General_Resources/SQL Scripts/Entity_Bens.SQL", sep=""))
dd.2016 <- querydb(paste(github_path, "General_Resources/SQL Scripts/2016_deluxe_districts_crusher_materialized_all.SQL", sep=""))
dd.2016 <- correct.dataset(dd.2016, sots.flag = 0, services.flag = 0)

## disconnect from database
dbDisconnect(con)

## format the column names (take out capitalization and spaces)
names(dta.470) <- tolower(names(dta.470))
names(dta.470) <- gsub(" ", ".", names(dta.470))
## rename column "function"
names(dta.470)[names(dta.470) == 'function'] <- 'function1'
## rename column "470.number"
names(dta.470)[names(dta.470) == '470.number'] <- 'X470.number'
## convert capacity to numeric
dta.470$maximum.capacity.reported <- dta.470$maximum.capacity
dta.470$maximum.capacity <- suppressWarnings(ifelse(grepl('Mbps', dta.470$maximum.capacity), as.numeric(gsub('Mbps', '', dta.470$maximum.capacity)),
                                   as.numeric(gsub('Gbps', '', dta.470$maximum.capacity))*1000))
## merge in BENs to DD
dd.2016 <- merge(dd.2016, bens, by.x='esh_id', by.y='entity_id', all.x=T)

## merge in number of students and number of campuses
dta.470 <- merge(dta.470, dd.2016[,c('ben', 'esh_id', 'num_students', 'num_campuses')], by='ben', all.x=T)

## the possible missing BENS (NA number of students),
## could be things we don't care about (ie Libraries)
## OR could be one-school districts that used their school BEN instead of their district BEN
## for now, take them out
dta.470.na.students <- dta.470[which(is.na(dta.470$num_students)),]
dta.470 <- dta.470[which(!is.na(dta.470$num_students)),]

## take out the BENs that file multiple 470s and subset to the most recent one filed (as long as the same service)

##**************************************************************************************************************************************************

## IA Meeting Goals
## Service Type = 'Internet Access and/or Telecommunications' 
dta.470.ia <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications"),]
## AND Function in ('Internet Access: ISP Service Only', 'Internet Access and Transport Bundled')
dta.470.ia <- dta.470.ia[which(dta.470.ia$function1 == 'Internet Access and Transport Bundled' |
                                 dta.470.ia$function1 == 'Internet Access: ISP Service Only' & is.na(dta.470.ia$quantity)),]
dta.470.ia <- dta.470.ia[which(dta.470.ia$quantity == 1 | is.na(dta.470.ia$quantity)),]
dta.470.ia2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                               dta.470$function1 == 'Other'),]
dta.470.ia <- rbind(dta.470.ia, dta.470.ia2)
## AND maximum capacities are meeting the 2014 connectivity goal
## find the max of the maximum capacities reported for each ID
max.capacity <- suppressWarnings(aggregate(dta.470.ia$maximum.capacity, by=list(dta.470.ia$X470.number), FUN=max, na.rm=T))
names(max.capacity) <- c('X470.number', 'maximum.capacity')
## merge in the number of students
max.capacity <- merge(max.capacity, dta.470.ia[,c('X470.number', 'num_students')], by='X470.number', all.x=T)
max.capacity$bw_per_student <- (max.capacity$maximum.capacity*1000) / max.capacity$num_students
max.capacity$meeting_goals_ia_2014 <- ifelse(max.capacity$bw_per_student >= 100, TRUE, FALSE)
max.capacity$meeting_goals_ia_2018 <- ifelse(max.capacity$bw_per_student >= 1000, TRUE, FALSE)
## how many are meeting goals?
table(max.capacity$meeting_goals_ia_2014)
ia.meeting.goals <- max.capacity$X470.number[max.capacity$meeting_goals_ia_2014 == TRUE]
## merge in the meeting goal status
dta.470.ia <- merge(dta.470.ia, max.capacity[,c('X470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')],
                    by='X470.number', all.x=T)
## overwrite the goal meeting status if the function is Other
dta.470.ia$meeting_goals_ia_2014 <- ifelse(dta.470.ia$function1 == 'Other', NA, dta.470.ia$meeting_goals_ia_2014)
dta.470.ia$meeting_goals_ia_2018 <- ifelse(dta.470.ia$function1 == 'Other', NA, dta.470.ia$meeting_goals_ia_2018)

## the number of forms meeting goals
length(unique(dta.470.ia$X470.number[which(dta.470.ia$meeting_goals_ia_2014 == TRUE)]))
length(unique(dta.470.ia$X470.number[which(dta.470.ia$meeting_goals_ia_2014 == FALSE)]))
length(unique(dta.470.ia$X470.number))

length(unique(dta.470.ia$X470.number[which(dta.470.ia$meeting_goals_ia_2018 == TRUE)]))
length(unique(dta.470.ia$X470.number[which(dta.470.ia$meeting_goals_ia_2018 == FALSE)]))
length(unique(dta.470.ia$X470.number))

## define unknown status
dta.470.ia.unknown <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                      dta.470$function1 == 'Internet Access and Transport Bundled' &
                                      dta.470$quantity > 1),]
dta.470.ia.unknown2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                        dta.470$function1 == 'Internet Access and Transport Bundled' &
                                        dta.470$quantity == 0),]
dta.470.ia.unknown <- rbind(dta.470.ia.unknown, dta.470.ia.unknown2)
dta.470.ia.unknown <- dta.470.ia.unknown[which(!dta.470.ia.unknown$X470.number %in% dta.470.ia$X470.number),]
dta.470.ia.unknown$meeting_goals_ia_2014 <- 'UNKNOWN'
dta.470.ia.unknown$meeting_goals_ia_2018 <- 'UNKNOWN'
length(unique(dta.470.ia.unknown$X470.number))


## WAN Meeting Goals
## Service Type = 'Internet Access and/or Telecommunications' 
dta.470.wan <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications"),]
## AND Function = ‘Transport Only - No ISP Service Included’ OR ‘Lit Fiber Service’
dta.470.wan <- dta.470.wan[which(dta.470.wan$function1 %in% c('Transport Only - No ISP Service Included', 'Lit Fiber Service', 'Other')),]
## AND quantity is >= (num_campuses - 1)
dta.470.wan$meeting_goals_wan <- ifelse(dta.470.wan$quantity >= (dta.470.wan$num_campuses - 1), TRUE, FALSE)
## overwrite the goal meeting status if the function is Other
dta.470.wan$meeting_goals_wan <- ifelse(dta.470.wan$function1 == 'Other', NA, dta.470.wan$meeting_goals_wan)

## the number of forms meeting goals
length(unique(dta.470.wan$X470.number[which(dta.470.wan$meeting_goals_wan == TRUE)]))
length(unique(dta.470.wan$X470.number[which(dta.470.wan$meeting_goals_wan == FALSE)]))
length(unique(dta.470.wan$X470.number))

## define unknown status
dta.470.wan.unknown <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" & 
                                       dta.470$function1 %in% c('Dark Fiber', 'Self-provisioning')),]
dta.470.wan.unknown2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                       dta.470$function1 == 'Internet Access and Transport Bundled' &
                                        dta.470$quantity == 0),]
dta.470.wan.unknown <- rbind(dta.470.wan.unknown, dta.470.wan.unknown2)
dta.470.wan.unknown <- dta.470.wan.unknown[which(!dta.470.wan.unknown$X470.number %in% dta.470.wan$X470.number),]
dta.470.wan.unknown$meeting_goals_wan <- 'UNKNOWN'
length(unique(dta.470.wan.unknown$X470.number))


## merge together the indicators
dta.470.ia.sub <- dta.470.ia[,c('esh_id', 'X470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')]
dta.470.ia.sub <- unique(dta.470.ia.sub)
dta.470.ia.sub <- rbind(dta.470.ia.sub, dta.470.ia.unknown[,c('esh_id', 'X470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')])
dta.470.sub <- merge(dta.470.ia.sub, dta.470.wan[,c('esh_id', 'X470.number', 'meeting_goals_wan')], by=c('esh_id', 'X470.number'), all=T)
dta.470.wan.unknown$meeting_goals_ia_2014 <- NA
dta.470.wan.unknown$meeting_goals_ia_2018 <- NA
dta.470.wan.unknown <- dta.470.wan.unknown[,c('esh_id', 'X470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018', 'meeting_goals_wan')]
dta.470.sub <- rbind(dta.470.sub, dta.470.wan.unknown)
dta.470.sub <- unique(dta.470.sub)

##=====================================================================================================
## TAKE SAMPLE

## IA
## export 5% sample for QA -- form, add row numbers
#dta.470.ia.qa <- dta.470.ia[which(dta.470.ia$X470.number %in%
#                                    sample(dta.470.ia$X470.number, .05*length(unique(dta.470.ia$X470.number)), replace=F)),]
## also for unknown
#dta.470.ia.qa.unknown <- dta.470.ia.unknown[which(dta.470.ia.unknown$X470.number %in%
#                                                    sample(dta.470.ia.unknown$X470.number, .05*length(unique(dta.470.ia.unknown$X470.number)), replace=F)),]
## combine datasets
#dta.470.ia.qa <- rbind(dta.470.ia.qa, dta.470.ia.qa.unknown)
## assign row names
#dta.470.ia.qa <- dta.470.ia.qa[order(dta.470.ia.qa$X470.number),]
#dta.470.ia.qa$row.number <- seq(1:nrow(dta.470.ia.qa))
#dta.470.ia.qa <- dta.470.ia.qa[,c(ncol(dta.470.ia.qa), 1:(ncol(dta.470.ia.qa)-1))]


## WAN
## export 5% sample for QA -- form, add row numbers
#dta.470.wan.qa <- dta.470.wan[which(dta.470.wan$X470.number %in%
#                                    sample(dta.470.wan$X470.number, .05*length(unique(dta.470.wan$X470.number)), replace=F)),]
## also for unknown
#dta.470.wan.qa.unknown <- dta.470.wan.unknown[which(dta.470.wan.unknown$X470.number %in%
#                                                    sample(dta.470.wan.unknown$X470.number, .05*length(unique(dta.470.wan.unknown$X470.number)), replace=F)),]
## combine datasets
#dta.470.wan.qa <- rbind(dta.470.wan.qa, dta.470.wan.qa.unknown)
## assign row names
#dta.470.wan.qa <- dta.470.wan.qa[order(dta.470.wan.qa$X470.number),]
#dta.470.wan.qa$row.number <- seq(1:nrow(dta.470.wan.qa))
#dta.470.wan.qa <- dta.470.wan.qa[,c(ncol(dta.470.wan.qa), 1:(ncol(dta.470.wan.qa)-1))]

## read in QA'd file
#qa1 <- read.csv("~/Downloads/470_ia_qa.csv - 470_ia_qa.csv.csv", as.is=T, header=T, stringsAsFactors=F)
#qa1.sub <- qa1[which(grepl("eeds", qa1$QA.Check)),]
#qa1.sub <- unique(qa1.sub[,which(names(qa1.sub) != 'row.number')])
## subset to the 470s in the QA
#dta.470.ia <- dta.470.ia[which(dta.470.ia$X470.number %in% qa1.sub$X470.number),]
#dta.470.ia <- unique(dta.470.ia)


## take out the BENs that file multiple 470s and subset to the most recent one filed (as long as the same service)

##=====================================================================================================
## WRITE OUT DATASETS

#write.csv(dta.470, "../data/470_all.csv", row.names=F)
#write.csv(dta.470.ia, "../data/470_ia_meeting_not_meeting_goals.csv", row.names=F)
#write.csv(dta.470.ia.unknown, "../data/470_ia_unknown.csv", row.names=F)
#write.csv(dta.470.ia.qa, "../data/470_ia_qa.csv", row.names=F)
#write.csv(dta.470.wan, "../data/470_wan_meeting_not_meeting_goals.csv", row.names=F)
#write.csv(dta.470.wan.unknown, "../data/470_wan_unknown.csv", row.names=F)
#write.csv(dta.470.wan.qa, "../data/470_wan_qa.csv", row.names=F)

write.csv(dta.470.sub, "../data/470_status.csv", row.names=F)
