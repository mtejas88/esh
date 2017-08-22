## ===========================================================================
##
## BREAKDOWN OF 470 BIDS FOR CAMPUSES THAT GOT FIBER
## Make sure they ask for fiber (400 known targets)
## % (of the 400) of fiber targets that filed a 470 for fiber in 16/17
## More likely in engaged states? % of leader?
##
## ===========================================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/fiber/new_campuses_with_fiber/")

##**************************************************************************************************************************************************
## READ IN DATA

## Districts Deluxe
dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv")
dd_2016 <- read.csv("data/raw/2016_deluxe_districts.csv")

## Services Received
sr_2017 <- read.csv("data/raw/2017_services_received.csv")

## Fiber Campuses
campuses_on_fiber <- read.csv("data/raw/campuses_on_fiber.csv")
bids_470 <- read.csv("data/raw/bids_470.csv")

## Form 470s
form_470 <- read.csv("data/raw/form_470.csv")

##**************************************************************************************************************************************************

## combine
dta <- merge(campuses_on_fiber, bids_470, by='esh_id', all.x=T)
dta <- merge(dta, dd_2017[,c('esh_id', 'postal_cd')], by='esh_id', all.x=T)
## merge number of scalable campuses in 2016 (to see if districts already had fiber to some campuses)
##dta <- merge(dta, dd_2016[,c('esh_id', 'current_known_scalable_campuses', 'current_assumed_scalable_campuses')], by='esh_id', all.x=T)
##dta$scalable_present <- ifelse(dta$current_known_scalable_campuses > 0 | dta$current_assumed_scalable_campuses > 0, TRUE, FALSE)

dta$fiber_470_from_current_applicant[is.na(dta$fiber_470_from_current_applicant)] <- 0
table(dta$fiber_470_from_current_applicant)
dta$fiber_470_from_current_applicant_campuses <- dta$fiber_470_from_current_applicant * dta$unscalable_campuses_moved_to_fiber
## percent of campuses that filed a Fiber 470
## 44% of campuses
sum(dta$fiber_470_from_current_applicant_campuses) / sum(dta$unscalable_campuses_moved_to_fiber) * 100
## How did the rest secure fiber if not through a 470?
sub.no.470 <- dta[which(dta$fiber_470_from_current_applicant_campuses == 0),]
sum(sub.no.470$unscalable_campuses_moved_to_fiber)
#table(sub.no.470$scalable_present)
dta.470 <- dta[which(dta$fiber_470_from_current_applicant_campuses > 0),]
sum(dta.470$unscalable_campuses_moved_to_fiber)
sum(dta.470$lost_unscalable_campuses)
#table(dta.470$scalable_present)

table(dta$locale)
table(dta$locale[dta$unscalable_campuses_moved_to_fiber > 0])
table(dta$postal_cd)
prop.table(table(dta$postal_cd[dta$unscalable_campuses_moved_to_fiber > 0]))
## aggregate by state
dta$counter <- dta$unscalable_campuses_moved_to_fiber
total.states <- aggregate(dta$counter, by=list(dta$postal_cd), FUN=sum)
names(total.states) <- c('postal_cd', 'total_districts')
dta$counter <- ifelse(dta$unscalable_campuses_moved_to_fiber > 0, 1, 0)
fiber.states <- aggregate(dta$counter, by=list(dta$postal_cd), FUN=sum)
names(fiber.states) <- c('postal_cd', 'fiber_districts')
## combine
dta.states <- merge(total.states, fiber.states, by='postal_cd', all.x=T)
dta.states$percentage <- dta.states$fiber_districts / dta.states$total_districts
dta.states <- dta.states[order(dta.states$percentage, decreasing=T),]

## District-level stats
#table(dta$overall_switcher)
table(is.na(dta$overall_switcher))

table(dta$meeting_2014_goal_no_oversub_2016, dta$meeting_2014_goal_no_oversub_2017)







