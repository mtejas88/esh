## =====================================================================================
##
## BREAKDOWN OF 470 FORMS FOR DISTRICTS THAT WERE TARGETS
## Methodology: (NOTE: Currently NOT looking at clean in 2016 and 2017 overlap)
##              Looking at all known Targets in 2016 and how many filed a Fiber 470.
##
## =====================================================================================

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

## FRNs
frns <- read.csv("data/raw/frns.csv", as.is=T, header=T, stringsAsFactors=F)

## state info
states <- read.csv("../../../General_Resources/datasets/state_statuses.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FORMAT DATA

## subset to only 2016 Targets
dd_2016 <- dd_2016[which(dd_2016$include_in_universe_of_districts == TRUE &
                           dd_2016$district_type == 'Traditional' &
                           dd_2016$exclude_from_ia_analysis == FALSE),]
## merge in state info
dd_2016 <- merge(dd_2016, states, by='postal_cd', all.x=T)
targets <- dd_2016[which(dd_2016$fiber_target_status == 'Target'),]

## Form 470 (format)
## see if a target district requested a Fiber Form 470
dta_470 <- form_470[which(form_470$Service.Type == 'Internet Access and/or Telecommunications'),]
## format minimum capacity
## for items that are not NA
minimum <- dta_470[!is.na(dta_470$Minimum.Capacity),]
elems <- unlist(strsplit(minimum$Minimum.Capacity, "\\ "))
m <- data.frame(matrix(elems, ncol=2, byrow=TRUE))
names(m) <- c('total_bw', 'units')
m$total_bw_numeric <- as.numeric(as.character(m$total_bw))
m$total_bw_min <- ifelse(m$units == 'Gbps', m$total_bw_numeric*1000, ifelse(m$units == 'Kbps', m$total_bw_numeric*0.001, m$total_bw_numeric))
minimum$total_bw_min <- m$total_bw_min
## merge back in
dta_470 <- merge(dta_470, minimum[,c('id', 'total_bw_min')], by='id', all.x=T)

## merge in number of bids received for a Form 470
dta_470 <- merge(dta_470, frns[,c('establishing_fcc_form470', 'num_bids_received')], by.x='X470.Number', by.y='establishing_fcc_form470', all.x=T)

##**************************************************************************************************************************************************
## LOGIC FOR FIBER 470

## filter Form 470 data further
dta_470 <- dta_470[which(dta_470$Function %in% c('Dark Fiber', 'Lit Fiber Service') |
                           (!dta_470$Function %in% c('Internet Access: ISP Service Only',
                                                     'Other', 'Cellular Data Plan/Air Card Service',
                                                     'Cellular Voice', 
                                                     'Voice Service (Analog, Digital, Interconnected VOIP, etc)') & dta_470$total_bw_min >= 200)),]
## create fiber indicator
dta_470$fiber <- TRUE

## merge in BENS to applicant_id in services_received
sr_2017 <- merge(sr_2017, bens[,c('entity_id', 'ben')], by.x='applicant_id', by.y='entity_id', all.x=T)
## merge in BENS to esh_id in districts_deluxe
targets <- merge(targets, bens[,c('entity_id', 'ben')], by.x='esh_id', by.y='entity_id', all.x=T)
## subset to the consortia applications
sr_2017_con <- sr_2017[which(sr_2017$ben %in% dta_470$BEN),]
sr_2017_con <- sr_2017_con[which(sr_2017_con$inclusion_status %in% c('clean_no_cost', 'clean_with_cost') &
                                   sr_2017_con$recipient_include_in_universe_of_districts == TRUE),]
## collect all of the districts served by the consortias that applied for fiber
districts_fiber <- unique(sr_2017_con$recipient_id)
## create an indicator for whether a district had consortia apply for fiber
targets$fiber_470 <- ifelse(targets$esh_id %in% districts_fiber, TRUE, FALSE)
## also if the district became a Non-Target in 2017, they must have filed a Form 470
targets$fiber_470 <- ifelse(targets$esh_id %in% dd_2017$esh_id[dd_2017$fiber_target_status == 'Not Target' &
                                                                 dd_2017$include_in_universe_of_districts == TRUE &
                                                                 dd_2017$district_type == "Traditional" &
                                                                 dd_2017$exclude_from_ia_analysis == FALSE], TRUE, targets$fiber_470)
## 688/1239 (55%) requested Fiber 470
table(targets$fiber_470)
fiber_470 <- targets[which(targets$fiber_470 == TRUE),]
table(fiber_470$postal_cd)

## Engagement Status
## create indicator for engaged states
targets$engaged <- ifelse(targets$engagement_status == 'Engaged', TRUE, FALSE)
## no pattern
table(targets$engaged, targets$fiber_470)

## State Pattern
## aggregate by state
targets$counter <- 1
agg.states <- aggregate(targets$counter, by=list(targets$postal_cd), FUN=sum)
names(agg.states) <- c('postal_cd', 'total')
targets$counter <- ifelse(targets$fiber_470 == TRUE, 1, 0)
agg.states.filed <- aggregate(targets$counter, by=list(targets$postal_cd), FUN=sum)
names(agg.states.filed) <- c('postal_cd', 'filed_fiber_470')
## merge
agg.states <- merge(agg.states, agg.states.filed, by='postal_cd', all.x=T)
agg.states$filed_fiber_470_perc <- agg.states$filed_fiber_470 / agg.states$total
## order by decreasing percentage
agg.states <- agg.states[order(agg.states$filed_fiber_470_perc, decreasing=T),]

## Procurement Pattern
table(targets$predom_procurement_cat, targets$fiber_470)

##**************************************************************************************************************************************************
## LOGIC FOR BIDS ON FIBER 470s

## subset to the districts that filed for themself
## for the districts that filed a Fiber 470, what percentage got 0 bids? 
## only 319 / 688 Forms

## there may be different num_bids_received for the same Form 470
bids_sub <- dta_470[which(dta_470$BEN %in% fiber_470$ben),]
agg.470s.ben <- aggregate(bids_sub$num_bids_received, by=list(bids_sub$BEN), FUN=median, na.rm=T)
names(agg.470s.ben) <- c('BEN', 'num_bids_received')
## replace NAs with 0
agg.470s.ben$num_bids_received[is.na(agg.470s.ben$num_bids_received)] <- 0

## 73% received at least more than one bid, 27% received 0 bids -- OF THE FORM 470S
table(agg.470s.ben$num_bids_received == 0) / nrow(agg.470s.ben)
table(agg.470s.ben$num_bids_received == 0) 

## subset to the districts that filed 470s that received bids
bids.districts <- targets[which(targets$ben %in% agg.470s.ben$BEN),]
## create indicator for 0 bids
bids.districts$zero_bids <- ifelse(bids.districts$ben %in% agg.470s.ben$BEN[agg.470s.ben$num_bids_received == 0], TRUE, FALSE)

## Engagement Status
## create indicator for engaged states
bids.districts$engaged <- ifelse(bids.districts$engagement_status == 'Engaged', TRUE, FALSE)
## possible pattern
table(bids.districts$engaged, bids.districts$zero_bids)

## State Pattern
## aggregate by state
bids.districts$counter <- 1
agg.states <- aggregate(bids.districts$counter, by=list(bids.districts$postal_cd), FUN=sum)
names(agg.states) <- c('postal_cd', 'total')
bids.districts$counter <- ifelse(bids.districts$zero_bids == TRUE, 1, 0)
agg.states.filed <- aggregate(bids.districts$counter, by=list(bids.districts$postal_cd), FUN=sum)
names(agg.states.filed) <- c('postal_cd', 'filed_zero_bids')
## merge
agg.states <- merge(agg.states, agg.states.filed, by='postal_cd', all.x=T)
agg.states$filed_zero_bids_perc <- agg.states$filed_zero_bids / agg.states$total
## order by decreasing percentage
agg.states <- agg.states[order(agg.states$filed_zero_bids_perc, decreasing=T),]

## Procurement Pattern
table(bids.districts$predom_procurement_cat, bids.districts$zero_bids)





