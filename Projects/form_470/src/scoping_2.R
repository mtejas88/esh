## ===========================================================================================================================
##
## SCOPING 2: Districts have a Form 470 where Service Type = 'Internet Access and/or Telecommunications'
##            AND Function = ‘Lit Fiber Service'
##                AND there are no other Form 470s on the district that are “Meeting 2014 IA Goals’ = ‘True’ or ‘False’
##  (i.e. they have no other Form 470s at all, or their Form 470s are listed as ’N/A’ or ‘Unknown’ for “Meeting 2014 IA Goals”)
##
## ===========================================================================================================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

dta.470 <- read.csv("data/interim/470_all.csv", as.is=T, header=T, stringsAsFactors=F)
dta.470.ia <- read.csv("data/interim/470_ia_status.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## apply criteria

sub <- dta.470[which(dta.470$service.type == "Internet Access and/or Telecommunications" &
                          dta.470$function1 == "Lit Fiber Service"),]

## find districts that only have 1 Form 470 that was evaluated as Meeting 2014 IA Goals 
sub.ia.eval <- dta.470.ia[dta.470.ia$meeting_goals_ia_2014 %in% c(TRUE, FALSE),]
ids.with.470 <- unique(sub.ia.eval$esh_id)

sub <- sub[which(!sub$esh_id %in% ids.with.470),]

#sub <- merge(sub, dta.470.ia[c('x470.number', 'meeting_goals_ia_2014')], by='x470.number', all.x=T)
#sub <- sub[which(!is.na(sub$meeting_goals_ia_2014)),]

##**************************************************************************************************************************************************
## write out datasets

write.csv(sub, "data/interim/scoping_2_districts_ia_fiber_only_1_470_eligible_for_ia_meeting_goals.csv", row.names=F)
