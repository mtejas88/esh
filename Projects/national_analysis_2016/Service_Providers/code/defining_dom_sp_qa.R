## ==============================================================================================================================
##
## SERVICE PROVIDER ANALYSIS: QA
##
## Comparing the Dom SP SotS 2016 Methodolgy with Sierra's new Methodology
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/national_analysis_2016/Service_Providers/")

##**************************************************************************************************************************************************
## READ IN FILES

## Services Received
sr_2017 <- read.csv("data/raw/2017_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
sr_2016 <- read.csv("data/raw/2016_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
sr_2015 <- read.csv("data/raw/2015_services_received.csv", as.is=T, header=T, stringsAsFactors=F)

## Deluxe Districts
dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016 <- read.csv("data/raw/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2015 <- read.csv("data/raw/2015_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

## current assignments
sp_assign_2017 <- read.csv("data/raw/2017_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
sp_assign_2016 <- read.csv("data/raw/2016_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
#sp_assign_2015 <- read.csv("data/raw/2015_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)

## read in exceptions to service provider "changes"
sp.exceptions <- read.csv("../../../General_Resources/datasets/service_provider_exceptions.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa2 <- read.csv("../../../General_Resources/datasets/switcher_qa2.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa3 <- read.csv("../../../General_Resources/datasets/switcher_qa3.csv", as.is=T, header=T, stringsAsFactors=F)

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
  sr_sub <- sr_sub[which(sr_sub$recipient_exclude_from_ia_analysis == FALSE),]
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

dta.2016 <- define_dom(sr_2016)
dta.2017 <- define_dom(sr_2017)
#dta.2015 <- define_dom(sr_2015)

##**************************************************************************************************************************************************
## Compare with New Methodology

compare_meth <- function(dta, dd, sp_assign){
  ## subset to just the districts with dominant service providers
  sub.dom <- dta[which(dta$predominant_sp == TRUE),]
  ## merge in clean status, universe indicator, and district_type
  dta <- merge(sub.dom, dd[,c('esh_id', 'exclude_from_ia_analysis', 'include_in_universe_of_districts', 'district_type')], by='esh_id', all.x=T)
  dta <- dta[which(dta$district_type == 'Traditional' & dta$include_in_universe_of_districts == TRUE),]
  dta <- dta[,c('esh_id', 'service_provider', 'purpose', 'bandwidth_in_mbps', 'percent_bw')]
  names(dta)[names(dta) != 'esh_id'] <- paste(names(dta)[names(dta) != 'esh_id'], "_old", sep='')
  ## combine both methodologies
  combined <- merge(dta, sp_assign, by='esh_id', all.x=T)
  ## format purpose column in new assignments
  combined$purpose <- gsub("\\{", "", combined$purpose)
  combined$purpose <- gsub("\\}", "", combined$purpose)
  combined$purpose <- gsub(" ", "", combined$purpose)
  combined$purpose_old <- gsub(" ", "", combined$purpose_old)
  ## standardize the "Internet,Upstream" and "Upstream,Internet" for both
  combined$purpose_old <- ifelse(combined$purpose_old == "Internet,Upstream" | combined$purpose_old == "Upstream,Internet", "Internet,Upstream", combined$purpose_old)
  combined$purpose <- ifelse(combined$purpose == "Internet,Upstream" | combined$purpose == "Upstream,Internet", "Internet,Upstream", combined$purpose)
  ## round the bw percent in new assignments
  combined$primary_sp_percent_of_bandwidth <- round(combined$primary_sp_percent_of_bandwidth, 2)
  ## create indicator where the columns don't match
  combined$service_provider_match <- ifelse(combined$service_provider_old == combined$reporting_name, TRUE, FALSE)
  combined$purpose_match <- ifelse(combined$purpose_old == combined$purpose, TRUE, FALSE)
  combined$bandwidth_match <- ifelse(combined$bandwidth_in_mbps_old == combined$primary_sp_bandwidth, TRUE, FALSE)
  combined$bandwidth_perc_match <- ifelse(combined$percent_bw_old == combined$primary_sp_percent_of_bandwidth, TRUE, FALSE)
  
  return(combined)
}

compare_2016 <- compare_meth(dta.2016, dd_2016, sp_assign_2016)
## create a subset of the districts that were assigned in both methodologies but don't match on some feature
sub.false.2016 <- compare_2016[which(compare_2016$service_provider_match == FALSE | compare_2016$purpose_match == FALSE |
                                  compare_2016$bandwidth_match == FALSE | compare_2016$bandwidth_perc_match == FALSE),]
sub.false.2016 <- sub.false.2016[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'purpose',
                          'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
                          "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
## create a subset of the districts that were only assigned in the old methodology
sub.na.2016 <- compare_2016[which(is.na(compare_2016$service_provider_match)),]


compare_2017 <- compare_meth(dta.2017, dd_2017, sp_assign_2017)
## create a subset of the districts that were assigned in both methodologies but don't match on some feature
sub.false.2017 <- compare_2017[which(compare_2017$service_provider_match == FALSE | compare_2017$purpose_match == FALSE |
                                       compare_2017$bandwidth_match == FALSE | compare_2017$bandwidth_perc_match == FALSE),]
sub.false.2017 <- sub.false.2017[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'purpose',
                                    'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
                                    "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
## create a subset of the districts that were only assigned in the old methodology
sub.na.2017 <- compare_2017[which(is.na(compare_2017$service_provider_match)),]


#compare_2015 <- compare_meth(dta.2015, dd_2015, sp_assign_2015)
## create a subset of the districts that were assigned in both methodologies but don't match on some feature
#sub.false.2015 <- compare_2015[which(compare_2015$service_provider_match == FALSE | compare_2015$purpose_match == FALSE |
#                                       compare_2015$bandwidth_match == FALSE | compare_2015$bandwidth_perc_match == FALSE),]
#sub.false.2015 <- sub.false.2015[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'purpose',
#                                    'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
#                                    "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
## create a subset of the districts that were only assigned in the old methodology
#sub.na.2015 <- compare_2015[which(is.na(compare_2015$service_provider_match)),]

##**************************************************************************************************************************************************
## Format the override data: Based on DQT QA for SotS 2016

## State-Specific SP "Changes": Should be considered the same
## take all unique combinations of "no's"
switcher.qa2 <- switcher.qa2[switcher.qa2$QA.Switched. == "no" | switcher.qa2$QA.Switched. == "no ",]
switcher.qa2 <- unique(switcher.qa2[,c('postal_cd', 'service_provider_2015', 'service_provider_2016')])
switcher.qa2 <- rbind(switcher.qa2, switcher.qa3)
switcher.qa2$same <- 1
switcher.qa2$override <- NULL
state_no_sp_change <- switcher.qa2
write.csv(state_no_sp_change, "../../../General_Resources/datasets/state_specific_sp_not_switchers.csv", row.names=F)


## Non-State Specific "Changes": Should be considered the same
sp.exceptions <- sp.exceptions[which(sp.exceptions$same == 1),]
sp.exceptions$Freq <- NULL
write.csv(sp.exceptions, "../../../General_Resources/datasets/general_sp_not_switchers.csv", row.names=F)
