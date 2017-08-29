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
form_470 <- read.csv("data/raw/form_470.csv", as.is=T, header=T, stringsAsFactors=F)

## BENs
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

## Form 470 (format)
## create consortia subset
#consortia <- form_470[which(form_470$Applicant.Type == 'Consortium' &
#                            form_470$Service.Type == 'Internet Access and/or Telecommunications'),]
consortia <- form_470[which(form_470$Service.Type == 'Internet Access and/or Telecommunications'),]

## format minimum capacity
## for items that are not NA
consortia.minimum <- consortia[!is.na(consortia$Minimum.Capacity),]
elems <- unlist(strsplit(consortia.minimum$Minimum.Capacity, "\\ "))
m <- data.frame(matrix(elems, ncol=2, byrow=TRUE))
names(m) <- c('total_bw', 'units')
m$total_bw_numeric <- as.numeric(as.character(m$total_bw))
m$total_bw_min <- ifelse(m$units == 'Gbps', m$total_bw_numeric*1000, ifelse(m$units == 'Kbps', m$total_bw_numeric*0.001, m$total_bw_numeric))
consortia.minimum$total_bw_min <- m$total_bw_min
## merge back in
consortia <- merge(consortia, consortia.minimum[,c('id', 'total_bw_min')], by='id', all.x=T)

## combine
dta <- merge(campuses_on_fiber, bids_470, by='esh_id', all.x=T)
dta <- merge(dta, dd_2017[,c('esh_id', 'postal_cd')], by='esh_id', all.x=T)

dta$fiber_470_from_current_applicant[is.na(dta$fiber_470_from_current_applicant)] <- 0
table(dta$fiber_470_from_current_applicant)
dta$fiber_470_from_current_applicant_campuses <- dta$fiber_470_from_current_applicant * dta$unscalable_campuses_moved_to_fiber
dta$counter <- 1

## percent of campuses that filed a Fiber 470
## 44% of campuses
sum(dta$fiber_470_from_current_applicant_campuses) / sum(dta$unscalable_campuses_moved_to_fiber) * 100
## 32% of districts
sum(dta$counter[dta$fiber_470_from_current_applicant_campuses > 0]) / nrow(dta) * 100
## districts that get fiber
dta.470 <- dta[which(dta$fiber_470_from_current_applicant_campuses > 0),]
sum(dta.470$unscalable_campuses_moved_to_fiber)
sum(dta.470$lost_unscalable_campuses)


##--------------------------------------------------------------------------------------------------------
## How did the rest secure fiber if not through a 470?
sub.no.470 <- dta[which(dta$fiber_470_from_current_applicant_campuses == 0),]
sum(sub.no.470$unscalable_campuses_moved_to_fiber)

## Maybe the rest are applied for by a consortia:
## filter consortium subset further
consortia <- consortia[which(consortia$Function %in% c('Dark Fiber', 'Lit Fiber Service') |
                              consortia$total_bw_min >= 200),]
## create fiber indicator
consortia$fiber <- TRUE
consortia$applicant_id <- consortia$BEN

## merge in BENS to applicant_id in services_received
sr_2017 <- merge(sr_2017, bens[,c('entity_id', 'ben')], by.x='applicant_id', by.y='entity_id', all.x=T)
## subset to the consortia applications
sr_2017_con <- sr_2017[which(sr_2017$ben %in% consortia$applicant_id),]
sr_2017_con <- sr_2017_con[which(sr_2017_con$inclusion_status %in% c('clean_no_cost', 'clean_with_cost') &
                                 sr_2017_con$recipient_include_in_universe_of_districts == TRUE),]
## collect all of the districts served by the consortias that applied for fiber
districts_consortia_fiber <- unique(sr_2017_con$recipient_id)
## create an indicator for whether a district had consortia apply for fiber
sub.no.470$consortia_fiber_470 <- ifelse(sub.no.470$esh_id %in% districts_consortia_fiber, TRUE, FALSE)
## percent of campuses that had consortia file a Fiber 470
## 30% of campuses
sum(sub.no.470$unscalable_campuses_moved_to_fiber[sub.no.470$consortia_fiber_470 == TRUE]) / sum(dta$unscalable_campuses_moved_to_fiber) * 100
## 37% of districts
sum(sub.no.470$counter[sub.no.470$consortia_fiber_470 == TRUE]) / nrow(dta) * 100

## which are still not accounted for?
sub.no.470.no.consortia <- sub.no.470[which(sub.no.470$consortia_fiber_470 == FALSE),]
table(sub.no.470.no.consortia$postal_cd)
table(sub.no.470.no.consortia$locale)


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







