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

#qa <- read.csv("~/Downloads/470 stuff.csv")
#qa <- read.csv("~/Downloads/filed own 470 and needed fiber 16.csv")

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

## subset sr to the target districts
#sr_2017 <- sr_2017[which(sr_2017$recipient_id %in% targets$esh_id),]
## merge in BENS to applicant_id in services_received
sr_2017 <- merge(sr_2017, bens[,c('entity_id', 'ben')], by.x='applicant_id', by.y='entity_id', all.x=T)
## merge in BENS to esh_id in districts_deluxe
targets <- merge(targets, bens[,c('entity_id', 'ben')], by.x='esh_id', by.y='entity_id', all.x=T)
## subset to the consortia applications
sr_2017_con <- sr_2017[which(sr_2017$ben %in% dta_470$BEN),]
sr_2017_con <- sr_2017_con[which(sr_2017_con$recipient_include_in_universe_of_districts == TRUE &
                                  sr_2017_con$consortium_shared == FALSE &
                                   sr_2017_con$inclusion_status != 'dqs_excluded'),]
## collect all of the districts served by the consortias that applied for fiber
districts_fiber <- unique(sr_2017_con$recipient_id)
## create an indicator for whether a district had consortia apply for fiber
## look at whether a district's ben is the recipient in the services received table
targets$fiber_470 <- ifelse(targets$esh_id %in% districts_fiber, TRUE, FALSE)
## OR it filed its own 470 (and not a 471, which would mean it's missing from SR)
targets$fiber_470 <- ifelse(targets$ben %in% dta_470$BEN, TRUE, targets$fiber_470)
## also if the district became a Non-Target in 2017, they must have filed a Form 470
targets$fiber_470 <- ifelse(targets$esh_id %in% dd_2017$esh_id[dd_2017$fiber_target_status == 'Not Target' &
                                                                 dd_2017$include_in_universe_of_districts == TRUE &
                                                                 dd_2017$district_type == "Traditional" &
                                                                 dd_2017$exclude_from_ia_analysis == FALSE], TRUE, targets$fiber_470)

## total districts: 1,228
length(unique(targets$esh_id))
## total campuses: 4,098
targets.sub <- targets[,c('esh_id', 'num_campuses')]
targets.sub <- unique(targets.sub)
sum(targets.sub$num_campuses)

## count how many districts in each bucket
## filed their own Form 470:
sub <- targets[which(targets$ben %in% dta_470$BEN),]
## 329 districts, 27%
length(unique(sub$esh_id))
sub2 <- sub[,c('esh_id', 'num_campuses')]
sub2 <- unique(sub2)
## 1,503 campuses, 37%
sum(sub2$num_campuses)

## consortia filed their Form 470:
sub3 <- targets[which(targets$esh_id %in% districts_fiber),]
sub3 <- sub3[which(!sub3$esh_id %in% sub$esh_id),]
## 155 districts, 13%
length(unique(sub3$esh_id))
sub4 <- sub3[,c('esh_id', 'num_campuses')]
sub4 <- unique(sub4)
## 501 campuses, 12%
sum(sub4$num_campuses)

## assumed they filed their Form 470:
sub5 <- targets[which(targets$esh_id %in% dd_2017$esh_id[dd_2017$fiber_target_status == 'Not Target' &
                                                         dd_2017$include_in_universe_of_districts == TRUE &
                                                         dd_2017$district_type == "Traditional" &
                                                         dd_2017$exclude_from_ia_analysis == FALSE]),]
sub5 <- sub5[which(!sub5$esh_id %in% c(sub3$esh_id, sub$esh_id)),]
## 121 districts, 10%
length(unique(sub5$esh_id))
sub6 <- sub5[,c('esh_id', 'num_campuses')]
sub6 <- unique(sub6)
## 406 campuses, 10%
sum(sub6$num_campuses)

## 605/1228 (49%) Districts requested Fiber 470
combine <- rbind(sub, sub3, sub5)
length(unique(combine$esh_id))

## 2,410/4,098 (59%) Campuses requested Fiber 470
combine <- combine[,c('esh_id', 'num_campuses')]
combine <- unique(combine)
sum(combine$num_campuses)

##**************************************************************************************************************************************************
## investigate patterns

## subset to the districts
fiber_470 <- targets[which(targets$fiber_470 == TRUE),]
#fiber_470 <- fiber_470[,c('esh_id', 'num_campuses', 'engagement_status', 'postal_cd', 'predom_procurement_cat')]
#fiber_470 <- unique(fiber_470)
#table(fiber_470$postal_cd)

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

## for the districts that filed a Fiber 470, what percentage got 0 bids? 
## only 329 / 605 Districts eligible (means they filed their own form 470)

## subset to the districts that filed for themself
bids_sub <- dta_470[which(dta_470$BEN %in% fiber_470$ben),]
## there may be different num_bids_received for the same Form 470
agg.470s.ben <- aggregate(bids_sub$num_bids_received, by=list(bids_sub$BEN), FUN=sum, na.rm=T)
names(agg.470s.ben) <- c('BEN', 'num_bids_received')
## take out NAs
agg.470s.ben <- agg.470s.ben[!is.na(agg.470s.ben$num_bids_received),]

## subset to the districts that filed 470s that received bids
bids.districts <- targets[which(targets$ben %in% agg.470s.ben$BEN),]
## create indicator for 0 bids
bids.districts$zero_bids <- ifelse(bids.districts$ben %in% agg.470s.ben$BEN[agg.470s.ben$num_bids_received == 0], TRUE, FALSE)

## 36/329 11% of districts received 0 bids
length(unique(bids.districts$esh_id[which(bids.districts$zero_bids == TRUE)]))
length(unique(bids.districts$esh_id))
length(unique(bids.districts$esh_id[which(bids.districts$zero_bids == TRUE)])) / length(unique(bids.districts$esh_id))
## No Rural Pattern
table(bids.districts$locale)
table(bids.districts$locale[bids.districts$zero_bids == TRUE])

## 106/1,503 7% of campuses received 0 bids
sum(bids.districts$num_campuses[which(bids.districts$zero_bids == TRUE)])
sum(bids.districts$num_campuses)
sum(bids.districts$num_campuses[which(bids.districts$zero_bids == TRUE)]) / sum(bids.districts$num_campuses)


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



#targets$qa_filed_fiber <- ifelse(targets$esh_id %in% qa$esh_id, TRUE, FALSE)

