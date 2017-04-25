## ==============================================
##
## SPECIAL CONSTRUCTION DECISIONS
## 
## OBJECTIVES:
##    -- compare funding decisions: DRT to Joe F 
##    -- Analysis of SpekC decisions
##
## ==============================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/")

## load the package into your environment (you need to do this for each script)
library(dplyr)

## read in data 
speKC.includedApps <- read.csv("data/interim/special_construction_applications_0405.csv", as.is=T, header=T)
speKC.frns <- read.csv("data/interim/frns_with_inclusion_reasons_0405.csv", as.is=T, header=T)

##determine funding status
speKC.includedFrns <- filter(speKC.frns, grepl("^include", comment))
speKC.includedFrnsAgg <- speKC.includedFrns %>% group_by(application_number, 
                                                         frn_status, 
                                                         Decision) %>% summarise(count=n(),
                                                                                 resolved_sc_flag = sum(resolved_sc_flag),
                                                                                 open_sc_tag = sum(open_sc_tag),
                                                                                 open_sc_flag = sum(open_sc_flag))
#see all FRN funding decisions vs Joe's Decisions 
table(speKC.includedFrnsAgg$Decision, speKC.includedFrnsAgg$frn_status)

#see all apps and their FRN funding decisions vs Joe's Decisions
speKC.includedFrnsAgg$funded_frn_status <- ifelse(speKC.includedFrnsAgg$frn_status == 'Funded',1,0)
speKC.includedFrnsAgg$denied_frn_status <- ifelse(speKC.includedFrnsAgg$frn_status == 'Denied',1,0)
speKC.includedFrnsAgg$pending_frn_status <- ifelse(speKC.includedFrnsAgg$frn_status == 'Pending',1,0)
speKC.includedFrnsAgg$cancelled_frn_status <- ifelse(speKC.includedFrnsAgg$frn_status == 'Cancelled',1,0)
speKC.includedFrnsAgg$no_frn_status <- ifelse(speKC.includedFrnsAgg$frn_status == '',1,0)
speKC.includedAppsAgg <- speKC.includedFrnsAgg %>% group_by(application_number,
                                                            Decision) %>% summarise(funded_frn_status = sum(funded_frn_status),
                                                                                    denied_frn_status = sum(denied_frn_status),
                                                                                    cancelled_frn_status = sum(cancelled_frn_status),
                                                                                    pending_frn_status = sum(pending_frn_status),
                                                                                    no_frn_status = sum(no_frn_status))
write.csv(speKC.includedAppsAgg, file = "data/interim/special_construction_decisions_0405.csv")

##because joe's decisions have higher matches for a larger quantity of FRNs, we will use his unless they are unavailable
table(speKC.includedAppsAgg$Decision, speKC.includedAppsAgg$no_frn_status)
table(speKC.includedAppsAgg$Decision, speKC.includedAppsAgg$cancelled_frn_status)
table(speKC.includedAppsAgg$Decision, speKC.includedAppsAgg$denied_frn_status)
table(speKC.includedAppsAgg$Decision, speKC.includedAppsAgg$funded_frn_status)
table(speKC.includedAppsAgg$Decision, speKC.includedAppsAgg$pending_frn_status)

##aggregate decisions, removing whitespace
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
speKC.includedAppsAgg$finalDecision <- ifelse(is.na(speKC.includedAppsAgg$Decision),
                                              ifelse(speKC.includedAppsAgg$cancelled_frn_status > 0 | speKC.includedAppsAgg$no_frn_status > 0,
                                                     'Cancelled',
                                                     ifelse(speKC.includedAppsAgg$denied_frn_status > 0,
                                                            'Denied',
                                                            ifelse(speKC.includedAppsAgg$funded_frn_status > 0,
                                                                   'Funded',
                                                                   ifelse(speKC.includedAppsAgg$pending_frn_status > 0,
                                                                          'Pending',
                                                                          'unknown')))),
                                              ifelse(speKC.includedAppsAgg$Decision == '',
                                                     'Pending',
                                                     trim(speKC.includedAppsAgg$Decision)))
table(speKC.includedAppsAgg$finalDecision)
prop.table(table(speKC.includedAppsAgg$finalDecision))
nrow(speKC.includedAppsAgg)
