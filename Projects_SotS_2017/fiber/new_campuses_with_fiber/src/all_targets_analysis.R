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

##**************************************************************************************************************************************************
## FORMAT DATA

## subset to only 2016 Targets
dd_2016 <- dd_2016[which(dd_2016$include_in_universe_of_districts == TRUE & dd_2016$exclude_from_ia_analysis == FALSE),]
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

##**************************************************************************************************************************************************
## LOGIC FOR FIBER 470

## Maybe the rest are applied for by a consortia:
## filter consortium subset further
dta_470 <- dta_470[which(dta_470$Function %in% c('Dark Fiber', 'Lit Fiber Service') |
                           (!dta_470$Function %in% c('Internet Access: ISP Service Only',
                                                     'Other', 'Cellular Data Plan/Air Card Service',
                                                     'Cellular Voice', 
                                                     'Voice Service (Analog, Digital, Interconnected VOIP, etc)') & dta_470$total_bw_min >= 200)),]
## create fiber indicator
dta_470$fiber <- TRUE

## merge in BENS to applicant_id in services_received
sr_2017 <- merge(sr_2017, bens[,c('entity_id', 'ben')], by.x='applicant_id', by.y='entity_id', all.x=T)
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
                                                                 dd_2017$include_in_universe_of_districts == TRUE&
                                                                 dd_2017$exclude_from_ia_analysis == FALSE], TRUE, targets$fiber_470)
## 688/1257 (55%) requested Fiber 470
table(targets$fiber_470)
fiber_470 <- targets[which(targets$fiber_470 == TRUE),]
table(fiber_470$postal_cd)

##**************************************************************************************************************************************************
## LOGIC FOR BIDS ON FIBER 470s

## for the districts that filed a Fiber 470, what percentage got 0 bids? 





