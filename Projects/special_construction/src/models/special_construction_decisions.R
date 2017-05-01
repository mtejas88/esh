## ==============================================
##
## SPECIAL CONSTRUCTION DECISION ANALYSIS
## 
## OBJECTIVES:
##    -- Determine size of funding
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
decisions.drt <- read.csv("data/raw/fiber_applications_with_results.csv", as.is=T, header=T)
districts <- read.csv("data/interim/districts_for_sc_reg.csv", as.is=T, header=T)
districts <- filter(districts, esh_id, fiber_target_status, 
                    frns_0_bid_indicator, frns_1_bid_indicator, frns_2_bid_indicator, frns_3p_bid_indicator)

#summarize application data
decisions.joe %>%
  group_by(Fiber.Type, Fiber.Sub.Type) %>%
  summarize(applications = n()) %>%
  mutate(apps_pct = applications / sum(applications)) %>%
  arrange(Fiber.Sub.Type)

## merge data
decisions <- inner_join(decisions.joe, decisions.drt, 
                        by = c("Application.Number" = "application_number"), 
                        suffix = c(".joe", ".drt"))

## Special Construction for analysis only
specK.decisions <- filter(decisions, trim(Fiber.Sub.Type) == 'Special Construction')
specK.decisions <- select(specK.decisions, 
                          Application.Number, Fiber.Type, frn_status, frns, requested_amount, committed_amount, 
                          FRN.COUNT, district_esh_id)

##analysis for districts only
specK.decisions.apps <- specK.decisions %>% distinct(Application.Number, Fiber.Type, district_esh_id)
specK.decisions.apps <- inner_join(specK.decisions.apps, districts, 
                                   by = c("district_esh_id" = "esh_id"))
table(specK.decisions.apps$fiber_target_status, specK.decisions.apps$frns_0_bid_indicator, specK.decisions.apps$frns_1_bid_indicator)

districts.fiber <- filter(districts, fiber_target_status == 'Target' | fiber_target_status == 'Not Target')
specK.decisions.apps.fiber <- filter(specK.decisions.apps, fiber_target_status == 'Target' | fiber_target_status == 'Not Target')
prop.table(table(districts.fiber$fiber_target_status))
prop.table(table(specK.decisions.apps.fiber$fiber_target_status))

districts.fiber2 <- filter(districts, fiber_target_status == 'Target' | fiber_target_status == 'Not Target' | fiber_target_status == 'Potential Target')
specK.decisions.apps.fiber2 <- filter(specK.decisions.apps, fiber_target_status == 'Target' | fiber_target_status == 'Not Target' | fiber_target_status == 'Potential Target')
prop.table(table(districts.fiber2$fiber_target_status))
prop.table(table(specK.decisions.apps.fiber2$fiber_target_status))

districts.bids <- filter(districts, fiber_target_status != 'No Data')
prop.table(table(districts.bids$frns_0_bid_indicator))
prop.table(table(specK.decisions.apps$frns_0_bid_indicator))

prop.table(table(districts.bids$frns_1_bid_indicator))
prop.table(table(specK.decisions.apps$frns_1_bid_indicator))


#check FRN.COUNT field
specK.decisions.check <- 
  specK.decisions %>%
  group_by(Application.Number, FRN.COUNT) %>% 
  summarize(frns = sum(frns)) %>%
  mutate(check = FRN.COUNT - frns)
table(specK.decisions.check$check)
#not trustworthy -- use USAC FRNs

#aggregate data
specK.decisions %>%
  group_by(Fiber.Type) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount))  %>%
  mutate(frns_pct = frns / sum(frns),
         requested_pct = requested_amount / sum(requested_amount),
         committed_pct = committed_amount / sum(committed_amount))

specK.decisions.byfibertype <-  
  specK.decisions %>%
  group_by(Fiber.Type, frn_status) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount))
specK.decisions.darkfiber <- filter(specK.decisions.byfibertype, trim(Fiber.Type) == 'Dark Fiber') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.litfiber <- filter(specK.decisions.byfibertype, trim(Fiber.Type) == 'Lit Fiber') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.selfprov <- filter(specK.decisions.byfibertype, trim(Fiber.Type) == 'Self Provisioned') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.agg <-  
  specK.decisions %>%
  group_by(frn_status) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount)) %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount),
         Fiber.Type = 'Agg')
specK.decisions.agg <- select(specK.decisions.agg, 
                              Fiber.Type, frn_status, frns, requested_amount, committed_amount, 
                              frns_percent, requested_percent)

#aggregate data - no outlier
specK.decisions.outlier <- filter(specK.decisions, Application.Number != '161056139')

specK.decisions.outlier %>%
  group_by(Fiber.Type) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount))  %>%
  mutate(frns_pct = frns / sum(frns),
         requested_pct = requested_amount / sum(requested_amount),
         committed_pct = committed_amount / sum(committed_amount))

specK.decisions.outlier.byfibertype <-  
  specK.decisions.outlier %>%
  group_by(Fiber.Type, frn_status) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount))
specK.decisions.outlier.darkfiber <- filter(specK.decisions.outlier.byfibertype, trim(Fiber.Type) == 'Dark Fiber') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.outlier.litfiber <- filter(specK.decisions.outlier.byfibertype, trim(Fiber.Type) == 'Lit Fiber') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.outlier.selfprov <- filter(specK.decisions.outlier.byfibertype, trim(Fiber.Type) == 'Self Provisioned') %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount))
specK.decisions.outlier.agg <-  
  specK.decisions.outlier %>%
  group_by(frn_status) %>%
  summarize(frns = sum(frns),
            requested_amount = sum(requested_amount),
            committed_amount = sum(committed_amount)) %>%
  mutate(frns_percent = frns/sum(frns),
         requested_percent = requested_amount/sum(requested_amount),
         Fiber.Type = 'Agg')
specK.decisions.outlier.agg <- select(specK.decisions.outlier.agg, 
                                      Fiber.Type, frn_status, frns, requested_amount, committed_amount, 
                                      frns_percent, requested_percent)

#append all tables' with rows as columns and write to csv
cuts <- c('darkfiber', 'litfiber', 'selfprov')

write.table(specK.decisions.agg, 
            "data/processed/decisions_summary.csv", 
            col.names=TRUE, row.names = FALSE,
            sep=",")
for (i in cuts){
  write.table(eval(as.name(paste("specK.decisions.", tolower(i), sep=""))), 
              file = "data/processed/decisions_summary.csv", 
              col.names=FALSE, row.names = FALSE
              , sep=",", append=TRUE)
}

write.table(specK.decisions.outlier.agg, 
            "data/processed/decisions_summary_no_outlier.csv", 
            col.names=TRUE, row.names = FALSE,
            sep=",")
for (i in cuts){
  write.table(eval(as.name(paste("specK.decisions.outlier.", tolower(i), sep=""))), 
              file = "data/processed/decisions_summary_no_outlier.csv", 
              col.names=FALSE, row.names = FALSE
              , sep=",", append=TRUE)
}
