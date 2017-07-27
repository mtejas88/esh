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

compare.2015.2016 <- 0
compare.2016.2017 <- 1

##**************************************************************************************************************************************************
## READ IN FILES

## Services Received
if (compare.2015.2016 == 1){
  sr_2015 <- read.csv("data/raw/2015_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
}
if (compare.2016.2017 == 1){
  sr_2017 <- read.csv("data/raw/2017_services_received.csv", as.is=T, header=T, stringsAsFactors=F)
}
sr_2016 <- read.csv("data/raw/2016_services_received.csv", as.is=T, header=T, stringsAsFactors=F)


## Deluxe Districts
if (compare.2015.2016 == 1){
  dd_2015 <- read.csv("data/raw/2015_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
}
if (compare.2016.2017 == 1){
  dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
}
dd_2016 <- read.csv("data/raw/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

## current assignments
if (compare.2015.2016 == 1){
  sp_assign_2015 <- read.csv("data/raw/2015_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
}
if (compare.2016.2017 == 1){
  sp_assign_2017 <- read.csv("data/raw/2017_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)
}
sp_assign_2016 <- read.csv("data/raw/2016_current_sp_assignments.csv", as.is=T, header=T, stringsAsFactors=F)

## current switchers
sp_switchers <- read.csv("data/raw/current_switchers.csv", as.is=T, header=T, stringsAsFactors=F)

## read in exceptions to service provider "changes"
sp.exceptions <- read.csv("../../../General_Resources/datasets/service_provider_exceptions.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa2 <- read.csv("../../../General_Resources/datasets/switcher_qa2.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa3 <- read.csv("../../../General_Resources/datasets/switcher_qa3.csv", as.is=T, header=T, stringsAsFactors=F)

## 2016 Top SPs
top.sp <- read.csv("../../service_provider_ranking/data/interim/service_provider_aggregated_clean_districts.csv", as.is=T, header=T, stringsAsFactors=F)

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
  ## subset to only Internet and Upstream
  sr_sub <- sr_dta[which(sr_dta$purpose %in% c('Internet', 'Upstream')),]
  ## fix ENA
  sr_sub$reporting_name[which(sr_sub$reporting_name == 'Ed Net of America')] <- 'ENA Services, LLC'
  ## fix Charter
  sr_sub$reporting_name[which(sr_sub$reporting_name %in% c('Bright House Net', 'Time Warner Cable Business LLC'))] <- 'Charter'
  ## CALL FUNCTION to define the predominant service provider
  dta_sub <- define.predominant.sp(sr_sub)
  ## subset to only the service providers that were dominant
  dta_sub <- dta_sub[which(dta_sub$predominant_sp == TRUE),]
  return(dta_sub)
}

## for 2016, do some formatting first:
## create subset:
## subset to recipient_include_in_universe_of_districts = TRUE
sr_2016 <- sr_2016[which(sr_2016$recipient_include_in_universe_of_districts == TRUE),]
## subset to exlude_from_ia_analysis = FALSE
sr_2016 <- sr_2016[which(sr_2016$recipient_exclude_from_ia_analysis == FALSE),]
## subset to only inclusion_status = clean
sr_2016 <- sr_2016[which(sr_2016$inclusion_status %in% c('clean_with_cost', 'clean_no_cost')),]
## create fields:
## create column for total bandwidth received by district from a service provider
sr_2016$bandwidth_in_mbps_total <- sr_2016$quantity_of_line_items_received_by_district * sr_2016$bandwidth_in_mbps
## CALL FUNCTION to define the predominant service provider
dta.2016 <- define_dom(sr_2016)

if (compare.2015.2016 == 1){
  ## for 2015, need to do a little more formatting first:
  ## create subset:
  ## subset to non-excluded line items
  sr_2015 <- sr_2015[sr_2015$exclude == FALSE,]
  ## subset to exlude_from_analysis = FALSE
  sr_2015 <- sr_2015[which(sr_2015$exclude_from_analysis == FALSE),]
  ## create fields:
  ## create a Purpose field
  sr_2015$purpose <- ifelse(sr_2015$internet_conditions_met == TRUE, "Internet", ifelse(sr_2015$upstream_conditions_met == TRUE, "Upstream", NA))
  ## need to create column for total bw received by district from a service provider
  sr_2015$bandwidth_in_mbps_total <- sr_2015$cat.1_allocations_to_district * sr_2015$bandwidth_in_mbps
  ## create "line_item_district_monthly_cost_recurring" column for 2015
  sr_2015$line_item_recurring_elig_cost <- suppressWarnings(as.numeric(sr_2015$line_item_recurring_elig_cost))
  sr_2015$line_item_district_monthly_cost_recurring <- (sr_2015$line_item_district_monthly_cost / sr_2015$line_item_total_monthly_cost) * sr_2015$line_item_recurring_elig_cost
  ## also take out NA reporting_names
  sr_2015$reporting_name <- ifelse(is.na(sr_2015$reporting_name), sr_2015$service_provider_name, sr_2015$reporting_name)
  ## CALL FUNCTION to define the predominant service provider
  dta.2015 <- define_dom(sr_2015)
}

if (compare.2016.2017 == 1){
  ## create subset:
  ## subset to recipient_include_in_universe_of_districts = TRUE
  sr_2017 <- sr_2017[which(sr_2017$recipient_include_in_universe_of_districts == TRUE),]
  ## subset to exlude_from_ia_analysis = FALSE
  sr_2017 <- sr_2017[which(sr_2017$recipient_exclude_from_ia_analysis == FALSE),]
  ## subset to only inclusion_status = clean
  sr_2017 <- sr_2017[which(sr_2017$inclusion_status %in% c('clean_with_cost', 'clean_no_cost')),]
  ## create fields:
  ## create column for total bandwidth received by district from a service provider
  sr_2017$bandwidth_in_mbps_total <- sr_2017$quantity_of_line_items_received_by_district * sr_2017$bandwidth_in_mbps
  ## replace NA contract_end_dates
  sr_2017$contract_end_date <- ifelse(is.na(sr_2017$contract_end_date), "None", sr_2017$contract_end_date)
  ## CALL FUNCTION to define the predominant service provider
  dta.2017 <- define_dom(sr_2017)
}

##**************************************************************************************************************************************************
## Compare with New Methodology

compare_meth <- function(dta, dd, sp_assign){
  ## merge in clean status, universe indicator, and district_type
  dta <- merge(dta, dd[,c('esh_id', 'exclude_from_ia_analysis', 'include_in_universe_of_districts', 'district_type')], by='esh_id', all.x=T)
  dta <- dta[which(dta$district_type == 'Traditional' & dta$include_in_universe_of_districts == TRUE),]
  dta <- dta[,c('esh_id', 'service_provider', 'purpose', 'bandwidth_in_mbps', 'percent_bw')]
  names(dta)[names(dta) != 'esh_id'] <- paste(names(dta)[names(dta) != 'esh_id'], "_old", sep='')
  ## combine both methodologies
  combined <- merge(dta, sp_assign, by='esh_id', all.x=T)
  ## format purpose column in new assignments
  combined$primary_sp_purpose <- gsub("\\{", "", combined$primary_sp_purpose)
  combined$primary_sp_purpose <- gsub("\\}", "", combined$primary_sp_purpose)
  combined$primary_sp_purpose <- gsub(" ", "", combined$primary_sp_purpose)
  combined$purpose_old <- gsub(" ", "", combined$purpose_old)
  ## standardize the "Internet,Upstream" and "Upstream,Internet" for both
  combined$purpose_old <- ifelse(combined$purpose_old == "Internet,Upstream" | combined$purpose_old == "Upstream,Internet", "Internet,Upstream", combined$purpose_old)
  combined$primary_sp_purpose <- ifelse(combined$primary_sp_purpose == "Internet,Upstream" | combined$primary_sp_purpose == "Upstream,Internet", "Internet,Upstream", combined$primary_sp_purpose)
  ## round the bw percent in new assignments
  combined$primary_sp_percent_of_bandwidth <- round(combined$primary_sp_percent_of_bandwidth, 2)
  ## create indicator where the columns don't match
  combined$service_provider_match <- ifelse(combined$service_provider_old == combined$reporting_name, TRUE, FALSE)
  combined$purpose_match <- ifelse(combined$purpose_old == combined$primary_sp_purpose, TRUE, FALSE)
  combined$bandwidth_match <- ifelse(combined$bandwidth_in_mbps_old == combined$primary_sp_bandwidth, TRUE, FALSE)
  combined$bandwidth_perc_match <- ifelse(combined$percent_bw_old == combined$primary_sp_percent_of_bandwidth, TRUE, FALSE)
  
  return(combined)
}

names(sp_assign_2016)[names(sp_assign_2016) == 'purpose'] <- 'primary_sp_purpose'
compare_2016 <- compare_meth(dta.2016, dd_2016, sp_assign_2016)
## create a subset of the districts that were assigned in both methodologies but don't match on some feature
sub.false.2016 <- compare_2016[which(compare_2016$service_provider_match == FALSE | compare_2016$purpose_match == FALSE |
                                  compare_2016$bandwidth_match == FALSE | compare_2016$bandwidth_perc_match == FALSE),]
sub.false.2016 <- sub.false.2016[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'primary_sp_purpose',
                          'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
                          "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
## create a subset of the districts that were only assigned in the old methodology
sub.na.2016 <- compare_2016[which(is.na(compare_2016$service_provider_match)),]

if (compare.2015.2016 == 1){
  ## FOR 2015 DO IT MANUALLY:
  ## merge in clean status, universe indicator, and district_type
  dta <- merge(dta.2015, dd_2015[,c('esh_id', 'exclude_from_analysis')], by='esh_id', all.x=T)
  dta <- dta[,c('esh_id', 'service_provider', 'purpose', 'bandwidth_in_mbps', 'percent_bw')]
  names(dta)[names(dta) != 'esh_id'] <- paste(names(dta)[names(dta) != 'esh_id'], "_old", sep='')
  ## combine both methodologies
  combined <- merge(dta, sp_assign_2015, by='esh_id', all.x=T)
  ## format purpose column in new assignments
  combined$primary_sp_purpose <- gsub("\\{", "", combined$primary_sp_purpose)
  combined$primary_sp_purpose <- gsub("\\}", "", combined$primary_sp_purpose)
  combined$primary_sp_purpose <- gsub(" ", "", combined$primary_sp_purpose)
  combined$purpose_old <- gsub(" ", "", combined$purpose_old)
  ## standardize the "Internet,Upstream" and "Upstream,Internet" for both
  combined$purpose_old <- ifelse(combined$purpose_old == "Internet,Upstream" | combined$purpose_old == "Upstream,Internet", "Internet,Upstream", combined$purpose_old)
  combined$primary_sp_purpose <- ifelse(combined$primary_sp_purpose == "Internet,Upstream" | combined$primary_sp_purpose == "Upstream,Internet", "Internet,Upstream", combined$primary_sp_purpose)
  ## round the bw percent in new assignments
  combined$primary_sp_percent_of_bandwidth <- round(combined$primary_sp_percent_of_bandwidth, 2)
  ## create indicator where the columns don't match
  combined$service_provider_match <- ifelse(combined$service_provider_old == combined$reporting_name, TRUE, FALSE)
  combined$purpose_match <- ifelse(combined$purpose_old == combined$primary_sp_purpose, TRUE, FALSE)
  combined$bandwidth_match <- ifelse(combined$bandwidth_in_mbps_old == combined$primary_sp_bandwidth, TRUE, FALSE)
  combined$bandwidth_perc_match <- ifelse(combined$percent_bw_old == combined$primary_sp_percent_of_bandwidth, TRUE, FALSE)
  compare_2015 <- combined
  ## create a subset of the districts that were assigned in both methodologies but don't match on some feature
  sub.false.2015 <- compare_2015[which(compare_2015$service_provider_match == FALSE | compare_2015$purpose_match == FALSE |
                                         compare_2015$bandwidth_match == FALSE | compare_2015$bandwidth_perc_match == FALSE),]
  sub.false.2015 <- sub.false.2015[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'primary_sp_purpose',
                                      'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
                                      "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
  ## create a subset of the districts that were only assigned in the old methodology
  sub.na.2015 <- compare_2015[which(is.na(compare_2015$service_provider_match)),]
}

if (compare.2016.2017 == 1){
  compare_2017 <- compare_meth(dta.2017, dd_2017, sp_assign_2017)
  ## create a subset of the districts that were assigned in both methodologies but don't match on some feature
  sub.false.2017 <- compare_2017[which(compare_2017$service_provider_match == FALSE | compare_2017$purpose_match == FALSE |
                                         compare_2017$bandwidth_match == FALSE | compare_2017$bandwidth_perc_match == FALSE),]
  sub.false.2017 <- sub.false.2017[,c('esh_id', 'service_provider_old', 'reporting_name', 'purpose_old', 'primary_sp_purpose',
                                      'bandwidth_in_mbps_old', 'primary_sp_bandwidth', 'percent_bw_old', 'primary_sp_percent_of_bandwidth',
                                      "service_provider_match", "purpose_match", "bandwidth_match", "bandwidth_perc_match")]
  ## create a subset of the districts that were only assigned in the old methodology
  sub.na.2017 <- compare_2017[which(is.na(compare_2017$service_provider_match)),]
}

##**************************************************************************************************************************************************
## Define Switchers

## (2015-2016)
if (compare.2015.2016 == 1){
  names(dta.2015)[names(dta.2015) != 'esh_id'] <- paste(names(dta.2015)[names(dta.2015) != 'esh_id'], '_2015', sep="")
  names(dta.2016)[names(dta.2016) != 'esh_id'] <- paste(names(dta.2016)[names(dta.2016) != 'esh_id'], '_2016', sep="")
  
  ## combine 2015 and 2016
  dta <- merge(dta.2015, dta.2016, by='esh_id', all=T)
  ## only keep where the is info in both years
  dta <- dta[which(!is.na(dta$service_provider_2015) & !is.na(dta$service_provider_2016)),]
  ## merge in postal_cd
  dta <- merge(dta, dd_2016[,c('esh_id', 'postal_cd')], by='esh_id', all.x=T)
  ## define if the service provider changed between years
  dta$switcher <- ifelse(dta$service_provider_2015 != dta$service_provider_2016, TRUE, FALSE)
  ## merge in state-specific exceptions
  dta <- merge(dta, state_no_sp_change, by=c('postal_cd', 'service_provider_2015', 'service_provider_2016'), all.x=T)
  ## if same = 1, then change switcher to FALSE
  dta$same <- ifelse(is.na(dta$same), 0, dta$same)
  dta$switcher <- ifelse(dta$same == 1, FALSE, dta$switcher)
  dta$same <- NULL
  ## merge in generic exceptions
  dta <- merge(dta, sp.exceptions, by=c('service_provider_2015', 'service_provider_2016'), all.x=T)
  ## if same = 1, then change switcher to FALSE
  dta$same <- ifelse(is.na(dta$same), 0, dta$same)
  dta$switcher <- ifelse(dta$same == 1, FALSE, dta$switcher)
  dta$same <- NULL
  
  ## Compare with New Methodology
  ## compare switchers for 2015 to 2016
  sp_switchers <- sp_switchers[which(sp_switchers$year == 2016),]
  nrow(sp_switchers)
  table(sp_switchers$switcher)
  nrow(dta)
  table(dta$switcher)
  
  ## look at missing in each table
  missing.sierra <- dta[which(!dta$esh_id %in% sp_switchers$esh_id),]
  missing.adrianna <- sp_switchers[which(!sp_switchers$esh_id %in% dta$esh_id),]
}

## (2016-2017)
if (compare.2016.2017 == 1){
  names(dta.2017)[names(dta.2017) != 'esh_id'] <- paste(names(dta.2017)[names(dta.2017) != 'esh_id'], '_2017', sep="")
  names(dta.2016)[names(dta.2016) != 'esh_id'] <- paste(names(dta.2016)[names(dta.2016) != 'esh_id'], '_2016', sep="")
  
  ## combine 2017 and 2016
  dta <- merge(dta.2017, dta.2016, by='esh_id', all=T)
  ## only keep where the is info in both years
  dta <- dta[which(!is.na(dta$service_provider_2017) & !is.na(dta$service_provider_2016)),]
  ## merge in postal_cd
  dta <- merge(dta, dd_2017[,c('esh_id', 'postal_cd')], by='esh_id', all.x=T)
  ## define if the service provider changed between years
  dta$switcher <- ifelse(dta$service_provider_2017 != dta$service_provider_2016, TRUE, FALSE)
  
  ## Compare with New Methodology
  ## compare switchers for 2017 to 2016
  sp_switchers <- sp_switchers[which(sp_switchers$year == 2017),]
  nrow(sp_switchers)
  table(sp_switchers$switcher)
  nrow(dta)
  table(dta$switcher)
  
  ## look at missing in each table
  missing.sierra <- dta[which(!dta$esh_id %in% sp_switchers$esh_id),]
  missing.adrianna <- sp_switchers[which(!sp_switchers$esh_id %in% dta$esh_id),]
}

