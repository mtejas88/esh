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
speKC.includedApps <- read.csv("data/interim/special_construction_applications.csv", as.is=T, header=T)
speKC.frns <- read.csv("data/interim/frns_with_inclusion_reasons.csv", as.is=T, header=T)

##determine funding status
##assume if any FRN is funded then the project is funded
speKC.includedFrns <- filter(speKC.frns, grepl("^include", comment))
speKC.includedFrnsAgg <- speKC.includedFrns %>% group_by(application_number, 
                                                         frn_status, 
                                                         Decision) %>% summarise(count=n(),
                                                                                 resolved_sc_flag = sum(resolved_sc_flag),
                                                                                 open_sc_tag = sum(open_sc_tag),
                                                                                 open_sc_flag = sum(open_sc_flag))
speKC.includedFrnsAgg.funded <- filter(speKC.includedFrnsAgg, frn_status == 'Funded')
##confirming all "decisions" from joe f are funded or unavailable
table(speKC.includedFrnsAgg.funded$Decision)

##applications not funded -- denied, pending, or cancelled
##not funded applications 
speKC.includedApps.notfunded <- merge(speKC.includedFrnsAgg.funded, speKC.includedApps, by = "application_number", all.x=TRUE, all.y=TRUE)
speKC.includedApps.notfunded <- filter(speKC.includedApps.notfunded, is.na(frn_status))

##number of FRNS falling under "funded" applications that were not funded 
speKC.includedFrnsAgg.notfunded <- merge(speKC.includedFrnsAgg.funded, speKC.includedFrnsAgg, by = "application_number", all.x=TRUE, all.y=TRUE)
speKC.includedFrnsAgg.fundedall <- filter(speKC.includedFrnsAgg.notfunded, !is.na(frn_status.x))
speKC.includedFrnsAgg.fundedall <- filter(speKC.includedFrnsAgg.fundedall, frn_status.y != 'Funded')
table(speKC.includedFrnsAgg.fundedall$frn_status.y)

##not funded FRNs
speKC.includedFrnsAgg.notfunded <- filter(speKC.includedFrnsAgg.notfunded, is.na(frn_status.x))
##comparing  not funded applications and FRNs -- since same number of rows, then all FRNs are for 1 application
nrow(speKC.includedFrnsAgg.notfunded) == nrow(speKC.includedApps.notfunded)

##because there are some Pending in Joe's data that are not in DRT, and none Pending in DRT that are not in Joe's,
##assume that DRT is more up to date than Joe
##additionally, aggregated counts between Joe and DRT are the same except between cancelled. Assigning unknowns to
##cancelled will remove them from analysis and is a sound determination
table(speKC.includedFrnsAgg.notfunded$frn_status.y, speKC.includedFrnsAgg.notfunded$Decision.y)

##denied, pending, cancelled FRNs
speKC.includedFrnsAgg.denied <- filter(speKC.includedFrnsAgg.notfunded, speKC.includedFrnsAgg.notfunded$frn_status.y == 'Denied')
speKC.includedFrnsAgg.pending <- filter(speKC.includedFrnsAgg.notfunded, speKC.includedFrnsAgg.notfunded$frn_status.y == 'Pending')
speKC.includedFrnsAgg.cancelled <- filter(speKC.includedFrnsAgg.notfunded, 
                                          speKC.includedFrnsAgg.notfunded$frn_status.y == 'Cancelled' | 
                                            speKC.includedFrnsAgg.notfunded$frn_status.y == '' | 
                                            is.na(speKC.includedFrnsAgg.notfunded$frn_status.y))


##aggregated decisions
speKC.includedFrnsAgg.funded <- select(speKC.includedFrnsAgg.funded, application_number, frn_status)
speKC.includedFrnsAgg.denied <- select(speKC.includedFrnsAgg.denied, application_number)
speKC.includedFrnsAgg.denied$frn_status <- 'Denied'
speKC.includedFrnsAgg.pending <- select(speKC.includedFrnsAgg.pending, application_number)
speKC.includedFrnsAgg.pending$frn_status <- 'Pending'
speKC.includedFrnsAgg.cancelled <- select(speKC.includedFrnsAgg.cancelled, application_number)
speKC.includedFrnsAgg.cancelled$frn_status <- 'Cancelled'

speKC.AppsDecisions.1 <- union(speKC.includedFrnsAgg.funded, speKC.includedFrnsAgg.denied)
speKC.AppsDecisions.2 <- union(speKC.includedFrnsAgg.pending, speKC.includedFrnsAgg.cancelled)

speKC.AppsDecisions <- union(speKC.AppsDecisions.1, speKC.AppsDecisions.2)
speKC.AppsDecisions <- merge(speKC.AppsDecisions, speKC.includedApps)

##decisions
table(speKC.AppsDecisions$frn_status)
write.csv(speKC.AppsDecisions, file = "data/interim/special_construction_decisions.csv")
