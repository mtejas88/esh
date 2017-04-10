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
spekC.joeF <- read.csv("data/external/special_construction_funding_decisions_joeF.csv", as.is=T, header=T)
spekC.eshClean <- read.csv("data/external/special_construction_data.csv", as.is=T, header=T)

##merge data
speKC.frns <- merge(spekC.eshClean, spekC.joeF, by.x = "application_number", by.y = "Application.Number", all.x=TRUE, all.y=TRUE)

##assign reason based exclusion
##assume everything joe is including is SC
speKC.frns$comment <- ifelse(is.na(speKC.frns$Fiber.Type), '', 'include - from Joe F')

##assume cancelled line items were not always on Joe's radar
##assume line items not in DRT are cancelled per DRT instructions
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$frn_status == 'Cancelled' | speKC.frns$frn_status == '', 
                               'include - cancelled', 
                               ''))
##assume if current data is updated with SC, then it is SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$fiber_sub_type_current == 'Special Construction', 
                               'include - special construction in current', 
                               ''))
##assume specicially tagged by DQT as SC is SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$open_sc_tag > 0, 
                               'include - special construction tag', 
                               ''))
##assume not specifically tagged by DQT, and also not on joe's list, is not SC
speKC.frns$comment <- ifelse(!(speKC.frns$comment == ''), 
                             speKC.frns$comment,
                        ifelse(speKC.frns$open_sc_flag > 0, 
                               'exclude - open special construction flag only', 
                               ''))
write.csv(speKC.frns, file = "data/interim/frns_with_inclusion_reasons.csv")

##create list of SpekC applications
speKC.includedFrns <- filter(speKC.frns, grepl("^include", comment))
speKC.includedApps <- distinct(select(speKC.includedFrns, application_number, applicant_ben, applicant_name, billed_entity_address_1, 
                                      billed_entity_city, billed_entity_state, billed_entity_zipcode))
paste0("Number of SpekC Apps: ", nrow(speKC.includedApps))
write.csv(speKC.includedApps, file = "data/interim/special_construction_applications.csv")
