## ============================================================
##
## SCOPING 1: 470s (with district applicant and esh id):
##          that are mtg 2014 IA goals,
##          where the min_capacity = 10 mbps,
##          and the max_capacity = 25 gbps
##
## ============================================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

dta.470 <- read.csv("data/processed/470_status.csv", as.is=T, header=T, stringsAsFactors=F)
dta.470.ia <- read.csv("data/interim/470_ia_status.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## apply criteria

sub <- dta.470.ia[which(dta.470.ia$meeting_goals_ia_2014 == TRUE &
                    dta.470.ia$minimum.capacity == "10 Mbps" &
                    dta.470.ia$maximum.capacity == 25000),]


##**************************************************************************************************************************************************
## write out datasets

write.csv(sub, "data/interim/scoping_1_mtg_2014_ia_min_10mbps_max_25gbps.csv", row.names=F)

