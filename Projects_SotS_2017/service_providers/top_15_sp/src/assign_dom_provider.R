## ==============================================================================================================================
##
## SERVICE PROVIDER ANALYSIS: QA
##
## Comparing the Dom SP SotS 2016 Methodolgy with Sierra's new Methodology
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/service_providers/top_15_sp/")

##**************************************************************************************************************************************************
## READ IN FILES

## Services Received
sr_2017 <- read.csv("data/raw/2017_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
sr_2016_froz <- read.csv("data/raw/2016_frozen_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
#sr_2015 <- read.csv("data/raw/2015_services_received.csv", as.is=T, header=T, stringsAsFactors=F)

## Deluxe Districts
#dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016_froz <- read.csv("data/raw/2016_frozen_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
#dd_2015 <- read.csv("data/raw/2015_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

## current assignments
#sp_assign_2017 <- read.csv("data/raw/2017_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
#sp_assign_2016 <- read.csv("data/raw/2016_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
#sp_assign_2015 <- read.csv("data/raw/2015_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)

## read in exceptions to service provider "changes"
sp.exceptions <- read.csv("../../../General_Resources/datasets/service_provider_exceptions.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa2 <- read.csv("../../../General_Resources/datasets/switcher_qa2.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa3 <- read.csv("../../../General_Resources/datasets/switcher_qa3.csv", as.is=T, header=T, stringsAsFactors=F)

## 2016 Top SPs
top.sp <- read.csv("../../../Projects/service_provider_ranking/data/interim/service_provider_aggregated_clean_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## Define a Main Service Provider for a District

## function to define a predominant service provider for a district (currently, >50% of bandwidth supplied)
define.predominant.sp <- function(sr.sub){
  ## collect unique recipient_ids
  unique.district <- unique(sr.sub$recipient_id)
  dta <- NULL
  for (i in 1:length(unique.district)){
    sub <- sr.sub[sr.sub$recipient_id == unique.district[i],]
    ## aggregate total bandwidth
    sp.agg <- aggregate(sub$bandwidth_in_mbps_total, by=list(sub$reporting_name), FUN=sum, na.rm=T)
    names(sp.agg) <- c('service_provider', 'bandwidth_in_mbps')
    ## aggregate total monthly (recurring) cost
    sp.agg.cost <- aggregate(sub$line_item_district_monthly_cost_recurring, by=list(sub$reporting_name), FUN=sum, na.rm=T)
    names(sp.agg.cost) <- c('service_provider', 'total_monthly_cost')
    sp.unq <- unique(sp.agg$service_provider)
    sp.agg$contract_end_date <- NA
    sp.agg$purpose <- NA
    for (j in 1:length(sp.unq)){
      ## for each service provider, collect all unique contract_end_dates
      contract <- unique(sub$contract_end_date[sub$reporting_name == sp.unq[j]])
      ## order by increasing
      contract <- contract[order(contract, decreasing=F)]
      ## assign the first one, should be the most recent (or the only one)
      sp.agg$contract_end_date[sp.agg$service_provider == sp.unq[j]] <- contract[1]
      ## also collect all of the purposes for each service provider
      purpose <- unique(sub$purpose[sub$reporting_name == sp.unq[j]])
      ## if more than one purpose, turn into string
      purpose <- paste(purpose, collapse=", ")
      ## assign the list
      sp.agg$purpose[sp.agg$service_provider == sp.unq[j]] <- purpose
    }
    sp.agg$percent_bw <- sp.agg$bandwidth_in_mbps / sum(sp.agg$bandwidth_in_mbps, na.rm=T)
    sp.agg$esh_id <- unique.district[i]
    ## merge in total cost per service provider
    sp.agg <- merge(sp.agg, sp.agg.cost, by='service_provider', all.x=T)
    ## order by decreasing percent bw
    sp.agg <- sp.agg[order(sp.agg$percent_bw, decreasing=T),]
    ## create an indicator for predominant service provider
    ## defined as greater than 50% for now
    sp.agg$predominant_sp <- ifelse(sp.agg$percent_bw > 0.50, TRUE, FALSE)
    ## append to dta
    dta <- rbind(dta, sp.agg)
  }
  dta$percent_bw <- round(dta$percent_bw, 2)
  return(dta)
}

##**************************************************************************************************************************************************
## create subset for services received

## define function to create clean subset of services received
define_dom <- function(sr_dta){
  ## subset to recipient_include_in_universe_of_districts = TRUE
  sr_sub <- sr_dta[which(sr_dta$recipient_include_in_universe_of_districts == TRUE),]
  ## subset to exlude_from_ia_analysis = FALSE
  #sr_sub <- sr_sub[which(sr_sub$recipient_exclude_from_ia_analysis == FALSE),]
  ## subset to only Internet and Upstream
  sr_sub <- sr_sub[which(sr_sub$purpose %in% c('Internet', 'Upstream')),]
  ## subset to only inclusion_status = clean
  sr_sub <- sr_sub[which(sr_sub$inclusion_status %in% c('clean_with_cost', 'clean_no_cost')),]
  ## create column for total bandwidth received by district from a service provider
  sr_sub$bandwidth_in_mbps_total <- sr_sub$quantity_of_line_items_received_by_district * sr_sub$bandwidth_in_mbps
  ## fix ENA
  sr_sub$reporting_name[which(sr_sub$reporting_name == 'Ed Net of America')] <- 'ENA Services, LLC'
  ## fix Charter
  sr_sub$reporting_name[which(sr_sub$reporting_name %in% c('Bright House Net', 'Time Warner Cable Business LLC'))] <- 'Charter'
  
  ## CALL FUNCTION to define the predominant service provider
  dta_sub <- define.predominant.sp(sr_sub)
  
  return(dta_sub)
}

dta.2016 <- define_dom(sr_2016_froz)
dta.2017 <- define_dom(sr_2017)
#dta.2015 <- define_dom(sr_2015)

##**************************************************************************************************************************************************
## Find Top 15 SPs

## merge in cleanliness status
dta.2016 <- merge(dta.2016, dd_2016_froz[,c('esh_id', 'exclude_from_ia_analysis')], by='esh_id', all.x=T)
dta.2016$clean <- ifelse(dta.2016$exclude_from_ia_analysis == FALSE, 1, 0)  
dta.2016$counter <- 1

## aggregate at the SP-level
sp.2016 <- aggregate(dta.2016$counter, by=list(dta.2016$service_provider), FUN=sum, na.rm=T)
names(sp.2016) <- c('service_provider', 'total_districts')
sp.2016.clean <- aggregate(dta.2016$clean, by=list(dta.2016$service_provider), FUN=sum, na.rm=T)
names(sp.2016.clean) <- c('service_provider', 'clean_districts')

## merge
dta.sp <- merge(sp.2016, sp.2016.clean, by='service_provider', all.x=T)
dta.sp$perc_clean <- dta.sp$clean_districts / dta.sp$total_districts

## subset to the top 15 SPs
dta.sp.top <- dta.sp[dta.sp$service_provider %in% top.sp$service_provider[1:15],]
