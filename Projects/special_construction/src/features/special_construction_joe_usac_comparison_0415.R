## ==============================================
##
## SPECIAL CONSTRUCTION DECISION COMPARISON
## 
## OBJECTIVES:
##    -- compare FRN level decisions: DRT to Joe F
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/")

## load the package into your environment (you need to do this for each script)
library(dplyr)
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

## read in data 
decisions.joe <- read.csv("data/external/special_construction_funding_decisions_joeF_04152017.csv", as.is=T, header=T)
decisions.drt <- read.csv("data/external/frn_decisions_joes_applications_04172017.csv", as.is=T, header=T)

decisions_only.drt <- select(decisions.drt, application_number, frn_status)
decisions_only.drt$funded_frn_status <- ifelse(decisions_only.drt$frn_status == 'Funded',1,0)
decisions_only.drt$denied_frn_status <- ifelse(decisions_only.drt$frn_status == 'Denied',1,0)
decisions_only.drt$pending_frn_status <- ifelse(decisions_only.drt$frn_status == 'Pending',1,0)
decisions_only.drt$cancelled_frn_status <- ifelse(decisions_only.drt$frn_status == 'Cancelled',1,0)

decisions_only.drt.by_application <- group_by(decisions_only.drt, application_number)
decisions_only.drt.applications <- summarise(decisions_only.drt.by_application,
                                             funded = sum(funded_frn_status),
                                             denied = sum(denied_frn_status),
                                             cancelled = sum(cancelled_frn_status),
                                             pending = sum(pending_frn_status))


## merge data 
decisions.merged <- merge(decisions.joe, decisions_only.drt.applications, 
                          by.x="Application.Number", by.y = "application_number",
                          all.x = TRUE, all.y = TRUE, sort = TRUE)
decisions.merged$Decision <- trim(decisions.merged$Decision)
decisions.merged$question <- ifelse(decisions.merged$Decision == 'Funded', 
                                    ifelse(decisions.merged$denied + decisions.merged$cancelled + decisions.merged$pending> 0, 
                                           TRUE,
                                           ifelse(decisions.merged$funded > 0, FALSE, TRUE)),
                                    ifelse(decisions.merged$Decision == 'Denied', 
                                           ifelse(decisions.merged$funded + decisions.merged$cancelled + decisions.merged$pending> 0, 
                                                  TRUE,
                                                  ifelse(decisions.merged$denied > 0, FALSE, TRUE)),
                                           ifelse(decisions.merged$Decision == 'Cancelled', 
                                                  ifelse(decisions.merged$denied + decisions.merged$funded + decisions.merged$pending> 0, 
                                                         TRUE,
                                                         ifelse(decisions.merged$cancelled > 0, FALSE, TRUE)),
                                                  ifelse(decisions.merged$denied + decisions.merged$funded + decisions.merged$cancelled> 0, 
                                                         TRUE,
                                                         ifelse(decisions.merged$pending > 0, FALSE, TRUE)))))
decisions.merged.question <- filter(decisions.merged, question == TRUE)
decisions.merged.question <- decisions.merged.question[1:25]
write.csv(decisions.merged.question, "data/interim/joe_applications_drt_decisions.csv", row.names=FALSE)
