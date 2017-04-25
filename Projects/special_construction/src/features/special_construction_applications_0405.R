## =========================================
##
## SPECIAL CONSTRUCTION DATA SET
## 
## OBJECTIVES:
##    -- compare SpekC apps: ESH to Joe F 
##    -- Analysis of SpekC breadth
##
## =========================================

## Clearing memory
rm(list=ls())
## setting working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/")

## load the package into your environment (you need to do this for each script)
library(dplyr)

## read in data 
spekC.joeF <- read.csv("data/external/special_construction_funding_decisions_joeF_04052017.csv", as.is=T, header=T)
spekC.joeF <- filter(spekC.joeF, Fiber.Sub.Type == 'Special Construction')
spekC.eshClean <- read.csv("data/external/special_construction_data.csv", as.is=T, header=T)

##merge data
speKC.frns <- merge(spekC.eshClean, spekC.joeF, by.x = "application_number", by.y = "Application.Number", all.x=TRUE, all.y=TRUE)

##assign reason based exclusion
##assume everything joe is including is SC
speKC.frns$comment <- ifelse(is.na(speKC.frns$Fiber.Type), '', 'include - from Joe F')
speKC.frns$heirarchy <- ifelse(is.na(speKC.frns$Fiber.Type), 99, 1)

##assume cancelled line items were not always on Joe's radar
##assume line items not in DRT are cancelled per DRT instructions
##https://data.usac.org/publicreports/FRN/Status/FundYear
## The database used by this tool contains only non-canceled applications that meet the window filing
## requirements for that funding year.
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$frn_status == 'Cancelled' | speKC.frns$frn_status == '', 
                               'include - cancelled', 
                               ''))
speKC.frns$heirarchy <- ifelse(!(speKC.frns$heirarchy == 99), 
                             speKC.frns$heirarchy,
                             ifelse(speKC.frns$frn_status == 'Cancelled' | speKC.frns$frn_status == '', 
                                    2, 
                                    99))

##assume if current data is updated with SC, then it is SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$fiber_sub_type_current == 'Special Construction', 
                               'include - special construction in current', 
                               ''))
speKC.frns$heirarchy <- ifelse(!(speKC.frns$heirarchy == 99), 
                               speKC.frns$heirarchy,
                               ifelse(speKC.frns$fiber_sub_type_current == 'Special Construction', 
                                      3, 
                                      99))
##assume specicially tagged by DQT as SC is SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$open_sc_tag > 0, 
                               'include - special construction tag', 
                               ''))
speKC.frns$heirarchy <- ifelse(!(speKC.frns$heirarchy == 99), 
                               speKC.frns$heirarchy,
                               ifelse(speKC.frns$open_sc_tag > 0, 
                                      4, 
                                      99))
##assume not specifically tagged by DQT, and also not on joe's list, is not SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$open_sc_flag > 0, 
                               'exclude - open special construction flag only', 
                               ''))
speKC.frns$heirarchy <- ifelse(!(speKC.frns$heirarchy == 99), 
                               speKC.frns$heirarchy,
                               ifelse(speKC.frns$open_sc_flag > 0, 
                                      5, 
                                      99))
write.csv(speKC.frns, file = "data/interim/frns_with_inclusion_reasons_0405.csv")

##create list of applications with comments
speKC.apps <- speKC.frns %>% group_by(application_number) %>% slice(which.min(heirarchy))
table(speKC.apps$comment)

##create list of SpekC applications 
speKC.includedApps <- filter(speKC.apps, grepl("^include", comment))
speKC.includedApps <- select(speKC.includedApps,
                             application_number,
                             applicant_ben, Billed.Entity.Number,
                             applicant_name, Billed.Entity.Name,
                             billed_entity_state, State)
paste0("Number of SpekC Apps: ", nrow(speKC.includedApps))
speKC.includedApps <- mutate(speKC.includedApps,
                             applicant_ben = ifelse(is.na(applicant_ben),Billed.Entity.Number,applicant_ben),
                             applicant_name = ifelse(is.na(applicant_name),Billed.Entity.Name,applicant_name),
                             billed_entity_state = ifelse(is.na(billed_entity_state),State,billed_entity_state))
speKC.includedApps <- distinct(select(speKC.includedApps, application_number, applicant_ben, applicant_name, billed_entity_state))
write.csv(speKC.includedApps, file = "data/interim/special_construction_applications_0405.csv")
