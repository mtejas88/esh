## ==============================================================================================================================
##
## SERVICE PROVIDER ANALYSIS: PREP DATA
##
## Defining a main service provider, prepping the dataset
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

## make current directory the working directory
wd <- setwd(".")
setwd(wd)
#setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Org-wide Projects/Progress Tracking/MASTER_MASTER/code/")

## load in libraries
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN FILES

## Services Received files
sr.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/services_received/"
sr.files <- list.files(sr.directory)
sr.2015.files <- sr.files[grepl("2015-services-received", sr.files)]
sr.2016.files <- sr.files[grepl("2016-services-received", sr.files)]
sr.2015 <- read.csv(paste(sr.directory, sr.2015.files[length(sr.2015.files)], sep=''), as.is=T, header=T, stringsAsFactors = F)
sr.2016 <- read.csv(paste(sr.directory, sr.2016.files[length(sr.2016.files)], sep=''), as.is=T, header=T, stringsAsFactors = F)

## Upgrades
up.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/processed/upgrades/"
up.files <- list.files(up.directory)
up.files <- up.files[grepl("districts_upgraded_as_of_", up.files)]
upgrades <- read.csv(paste(up.directory, up.files[length(up.files)], sep=''), as.is=T, header=T, stringsAsFactors = F)

## Deluxe District files
dd.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/deluxe_districts/"
dd.files <- list.files(dd.directory)
dd.2015.files <- dd.files[grepl("2015-districts-deluxe", dd.files)]
dd.2016.files <- dd.files[grepl("2016-districts-deluxe", dd.files)]
dd.2015 <- read.csv(paste(dd.directory, dd.2015.files[length(dd.2015.files)], sep=''), as.is=T, header=T, stringsAsFactors = F)
dd.2016 <- read.csv(paste(dd.directory, dd.2016.files[length(dd.2016.files)], sep=''), as.is=T, header=T, stringsAsFactors = F)

## read in exceptions to service provider "changes"
sp.exceptions <- read.csv("../data/service_provider_exceptions.csv", as.is=T, header=T, stringsAsFactors=F)

## and switcher QA
switcher.qa <- read.csv("../data/switcher_qa.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa2 <- read.csv("../data/switcher_qa2.csv", as.is=T, header=T, stringsAsFactors=F)
switcher.qa3 <- read.csv("../data/switcher_qa3.csv", as.is=T, header=T, stringsAsFactors=F)

## read in cost reference data
cost <- read.csv("../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/cost_lookup.csv", as.is=T, header=T)
cost$cost_per_circuit <- cost$circuit_size_mbps * cost$cost_per_mbps

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

## 2016
## subset to only Internet and Upstream
sr.2016.sub <- sr.2016[sr.2016$purpose %in% c('Internet', 'Upstream'),]
## need to create column for total bandwidth received by district from a service provider
sr.2016.sub$bandwidth_in_mbps_total <- sr.2016.sub$quantity_of_line_items_received_by_district * sr.2016.sub$bandwidth_in_mbps
## also take out excluded line items
sr.2016.sub <- sr.2016.sub[sr.2016.sub$inclusion_status == "clean_with_cost",]
## CALL FUNCTION to define the predominant service provider
dta.2016 <- define.predominant.sp(sr.2016.sub)
## attach year to the end of column names, except esh_id
names(dta.2016) <- paste(names(dta.2016), '_2016', sep='')
names(dta.2016)[names(dta.2016) == 'esh_id_2016'] <- 'esh_id'
## merge in clean status
dta.2016 <- merge(dta.2016, dd.2016[,c('esh_id', 'exclude_from_ia_analysis')], by='esh_id', all.x=T)
dta.2016.all <- dta.2016
dta.2016 <- dta.2016[dta.2016$exclude_from_ia_analysis == FALSE,]
## how many districts have a predominant service provider?
## 79% (10,295 / 13,036)
table(dta.2016$predominant_sp_2016)
nrow(dta.2016)
## plot histogram of percentage for dominant service provider
sub.hist <- dta.2016[dta.2016$percent_bw_2016 > 0.50 & dta.2016$percent_bw_2016 < 1,]
pdf("../figures/2016_percentage_bw_service_provider.pdf", height=4, width=6)
qplot(sub.hist$percent_bw_2016, geom="histogram", binwidth=0.02) +
  xlab("") + 
  ggtitle("2016 Percentage Total BW\nProvided by Main Service Provider") +
  theme(panel.background=element_blank(), panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(), panel.border=element_rect(color = rgb(0,0,0,0.8), fill=NA),
        plot.background=element_rect(fill=alpha('white', 0.0),color="grey50"),
        legend.position="none")
dev.off()


## 2015
## subset to only Internet and Upstream
sr.2015.sub <- sr.2015[sr.2015$internet_conditions_met == TRUE | sr.2015$upstream_conditions_met == TRUE,]
## create a Purpose field
sr.2015.sub$purpose <- ifelse(sr.2015.sub$internet_conditions_met == TRUE, "Internet", ifelse(sr.2015.sub$upstream_conditions_met == TRUE, "Upstream", NA))
## need to create column for total bw received by district from a service provider
sr.2015.sub$bandwidth_in_mbps_total <- sr.2015.sub$cat.1_allocations_to_district * sr.2015.sub$bandwidth_in_mbps
## create "line_item_district_monthly_cost_recurring" column for 2015
sr.2015.sub$line_item_recurring_elig_cost <- suppressWarnings(as.numeric(sr.2015.sub$line_item_recurring_elig_cost))
sr.2015.sub$line_item_district_monthly_cost_recurring <- (sr.2015.sub$line_item_district_monthly_cost / sr.2015.sub$line_item_total_monthly_cost) * sr.2015.sub$line_item_recurring_elig_cost
## also take out excluded line items
sr.2015.sub <- sr.2015.sub[sr.2015.sub$exclude == FALSE,]
## also take out NA reporting_names
sr.2015.sub$reporting_name <- ifelse(is.na(sr.2015.sub$reporting_name), sr.2015.sub$service_provider_name, sr.2015.sub$reporting_name)
## CALL FUNCTION to define the predominant service provider
dta.2015 <- define.predominant.sp(sr.2015.sub)
## attach year to the end of column names, except esh_id
names(dta.2015) <- paste(names(dta.2015), '_2015', sep='')
names(dta.2015)[names(dta.2015) == 'esh_id_2015'] <- 'esh_id'
## merge in clean status
dta.2015 <- merge(dta.2015, dd.2015[,c('esh_id', 'exclude_from_analysis')], by='esh_id', all.x=T)
dta.2015 <- dta.2015[dta.2015$exclude_from_analysis == FALSE,]
## how many districts have a predominant service provider?
## 84% (9,936/11,782)
table(dta.2015$predominant_sp_2015)
nrow(dta.2015)
## plot histogram of percentage for dominant service provider
sub.hist <- dta.2015[dta.2015$percent_bw_2015 > 0.50 & dta.2015$percent_bw_2015 < 1,]
pdf("../figures/2015_percentage_bw_service_provider.pdf", height=4, width=6)
qplot(sub.hist$percent_bw_2015, geom="histogram", binwidth=0.02) +
  xlab("") + 
  ggtitle("2015 Percentage Total BW\nProvided by Main Service Provider") +
  theme(panel.background=element_blank(), panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(), panel.border=element_rect(color = rgb(0,0,0,0.8), fill=NA),
        plot.background=element_rect(fill=alpha('white', 0.0),color="grey50"),
        legend.position="none")
dev.off()

## define whether the predominant service provider changed
## first, only subset to the one predominant service provider for each year
dta.dom.2015 <- dta.2015[dta.2015$predominant_sp_2015 == TRUE & !is.na(dta.2015$predominant_sp_2015),]
dta.dom.2016 <- dta.2016[dta.2016$predominant_sp_2016 == TRUE & !is.na(dta.2016$predominant_sp_2016),]
## merge the two years
dta.dom <- merge(dta.dom.2015, dta.dom.2016, by='esh_id', all=T)
## only keep the districts that overlap in both years (no NA values in the other year)
dta.dom <- dta.dom[!is.na(dta.dom$service_provider_2015) & !is.na(dta.dom$service_provider_2016),]
## merge in upgrades info
dta.dom <- merge(dta.dom, upgrades[,c('esh_id', 'postal_cd', 'district_name', 'locale', 'num_students_2015', 'num_students_2016',
                                      'upgrade', 'meeting_goals_2015', 'meeting_goals_2016')], by='esh_id', all.x=T)
## subset to no NA values in upgrades data (means the district was dirty in either 2015 or 2016)
dta.dom <- dta.dom[!is.na(dta.dom$postal_cd),]
## once more, what percentage of districts have a predominant service provider in both years?
## 95% (8,484/8,897)
nrow(dta.dom) / nrow(upgrades)
## calculate meeting connectivity goal status for the predominant service provider
dta.dom$sp_bw_per_student_2015 <- (dta.dom$bandwidth_in_mbps_2015*1000) / dta.dom$num_students_2015
dta.dom$sp_bw_per_student_2016 <- (dta.dom$bandwidth_in_mbps_2016*1000) / dta.dom$num_students_2016
dta.dom$sp_meeting_goals_2015 <- ifelse(dta.dom$sp_bw_per_student_2015 >= 100, TRUE, FALSE)
dta.dom$sp_meeting_goals_2016 <- ifelse(dta.dom$sp_bw_per_student_2016 >= 100, TRUE, FALSE)
## indicate whether there was a service provider change based on string matching
dta.dom$sp_change <- ifelse(dta.dom$service_provider_2015 != dta.dom$service_provider_2016, 1, 0)

## create subsets to manually check service provider changes
#sub.change <- dta.dom[dta.dom$sp_change == 1,]
#sub.change <- data.frame(table(sub.change[,c('service_provider_2015', 'service_provider_2016')]))
#sub.change <- sub.change[sub.change$Freq > 0,]
#sub.change <- sub.change[order(sub.change$Freq, decreasing=T),]
#write.csv(sub.change[sub.change$Freq >= 10,], "../data/most_common_sp_changes_greater.csv", row.names=F)
#write.csv(sub.change[sub.change$Freq < 10,], "../data/most_common_sp_changes.csv", row.names=F)

## override changes if the service providers are meant to be the same (collected manually from data above)
dta.dom <- merge(dta.dom, sp.exceptions, by=c('service_provider_2015', 'service_provider_2016'), all.x=T)
## also override changes with the QA info:
## take all unique combinations of "no's"
switcher.qa2 <- switcher.qa2[switcher.qa2$QA.Switched. == "no" | switcher.qa2$QA.Switched. == "no ",]
switcher.qa2 <- unique(switcher.qa2[,c('postal_cd', 'service_provider_2015', 'service_provider_2016')])
switcher.qa2 <- rbind(switcher.qa2, switcher.qa3)
switcher.qa2$override <- 1
dta.dom <- merge(dta.dom, switcher.qa2, by=c('postal_cd', 'service_provider_2015', 'service_provider_2016'), all.x=T)
## Apply the overrides:
## create subset of dta.dom where same is not NA
dta.dom.same <- dta.dom[!is.na(dta.dom$same),]
dta.dom <- dta.dom[is.na(dta.dom$same),]
## apply correction to the service provider change if not a change
dta.dom.same$sp_change <- ifelse(dta.dom.same$same == 1, 0, dta.dom.same$sp_change)
## now rbind back the datasets
dta.dom <- rbind(dta.dom, dta.dom.same)

## create subset of dta.dom where override is not NA
dta.dom.override <- dta.dom[!is.na(dta.dom$override),]
dta.dom <- dta.dom[is.na(dta.dom$override),]
## apply correction to the service provider change if not a change
dta.dom.override$sp_change <- ifelse(dta.dom.override$override == 1, 0, dta.dom.same$sp_change)
## now rbind back the datasets
dta.dom <- rbind(dta.dom, dta.dom.override)

## create an indicator for whether there was a contract end date between years
## defined as anything expiring in 2016
dta.dom$contract_ended_between_years <- ifelse(dta.dom$contract_end_date_2015 <= "2016-12-31", TRUE, FALSE)

## lastly, merge in affordability goal information from deluxe districts table
## subset to districts "fit for analysis"
dd.2015 <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
## fix dd.2015 monthly_ia_cost_per_mbps
dd.2015$ia_monthly_cost_per_mbps <- suppressWarnings(as.numeric(dd.2015$monthly_ia_cost_per_mbps, na.rm=T))
dd.2016$ia_monthly_cost_per_mbps <- as.numeric(dd.2016$ia_monthly_cost_per_mbps, na.rm=T)
## take out NA values for ia_monthly_cost_total
dd.2016.sub <- dd.2016[!is.na(dd.2016$ia_monthly_cost_total),]
dd.2015.sub <- dd.2015[!is.na(dd.2015$ia_monthly_cost_total),]
## function for solving bandwidth budget 'knapsack' problem
bw_knapsack <- function(ia_budget){
  ia_bw <- 0
  while (ia_budget > 0) {
    ## do something
    if (length(which(cost$cost_per_circuit <= ia_budget)) == 0) {
      break
    } else {
      ## maximum circuit cost that a district can afford within the budget
      index <- max(which(cost$cost_per_circuit <= ia_budget))
      ## add bandwidth
      ia_bw <- ia_bw + cost$circuit_size_mbps[index]
      ## subtract from budget
      ia_budget <- ia_budget - cost$cost_per_circuit[index]
    }
  }
  return(ia_bw)
}
## Function to apply Knapsack / SotS Affordability Goal 
three_datasets_for_real <- function(input){
  ## create target_bandwidth variable
  input$target_bandwidth <- sapply(input$ia_monthly_cost_total, function(x){bw_knapsack(x)})
  ## convert ia_monthly_cost_per_mbps to numeric
  #input$ia_monthly_cost_per_mbps <- as.numeric(input$ia_monthly_cost_per_mbps, na.rm = TRUE)
  
  ## are districts meeting $3 per Mbps Goal?
  input$affordability_goal_sots <- ifelse(input$ia_monthly_cost_per_mbps <= 3, 1, 0)
  
  ## are districts meeting the new Affordability Goal?
  input$affordability_goal_knapsack <- ifelse(input$ia_bw_mbps_total >= input$target_bandwidth, 1, 0)
  
  ## for districts spending less than $700,
  ## the standard is whether they are paying less than or equal to $14 per Mbps
  small <- which(input$ia_monthly_cost_total < 700) 
  input[small,]$affordability_goal_knapsack <- ifelse(input[small,]$ia_monthly_cost_per_mbps <= 14, 1, 0)
  
  ## give free credit
  free_ia <- which(input$exclude_from_ia_analysis == FALSE &
                     input$exclude_from_ia_cost_analysis == FALSE &
                     input$ia_monthly_cost_total == 0 &
                     input$ia_bw_mbps_total > 0)
  input$affordability_goal_knapsack[free_ia] <- 1
  
  restricted_cost <- which(input$exclude_from_ia_analysis == FALSE &
                             input$exclude_from_ia_cost_analysis == TRUE &
                             input$ia_monthly_cost_total == 0)
  input$affordability_goal_knapsack[restricted_cost] <- NA
  
  output <- input
  return(output)
}
dd.2015.sub <- three_datasets_for_real(dd.2015.sub)
dd.2016.sub <- three_datasets_for_real(dd.2016.sub)
## merge in afforadability goal information
dta.dom <- merge(dta.dom, dd.2015.sub[,c('esh_id', 'affordability_goal_knapsack', 'ia_monthly_cost_per_mbps')], by='esh_id', all.x=T)
names(dta.dom)[names(dta.dom) == 'affordability_goal_knapsack'] <- 'affordability_goal_knapsack_2015'
names(dta.dom)[names(dta.dom) == 'ia_monthly_cost_per_mbps'] <- 'district_ia_monthly_cost_per_mbps_2015'
dta.dom$affordability_goal_knapsack_2015 <- ifelse(dta.dom$affordability_goal_knapsack_2015 == 1, TRUE, FALSE)
dta.dom <- merge(dta.dom, dd.2016.sub[,c('esh_id', 'affordability_goal_knapsack', 'ia_monthly_cost_per_mbps', 'district_size')], by='esh_id', all.x=T)
names(dta.dom)[names(dta.dom) == 'affordability_goal_knapsack'] <- 'affordability_goal_knapsack_2016'
names(dta.dom)[names(dta.dom) == 'ia_monthly_cost_per_mbps'] <- 'district_ia_monthly_cost_per_mbps_2016'
dta.dom$affordability_goal_knapsack_2016 <- ifelse(dta.dom$affordability_goal_knapsack_2016 == 1, TRUE, FALSE)


## also combine a few service providers
## Ed Net of America to ENA Services, LLC
dta.dom$service_provider_2016 <- gsub("Ed Net of America", "ENA Services, LLC", dta.dom$service_provider_2016)
dta.2016$service_provider_2016 <- gsub("Ed Net of America", "ENA Services, LLC", dta.2016$service_provider_2016)
dta.2016.all$service_provider_2016 <- gsub("Ed Net of America", "ENA Services, LLC", dta.2016.all$service_provider_2016)
## Bright House Net, Time Warner Cable Business LLC to Charter
dta.dom$service_provider_2016 <- gsub("Bright House Net", "Charter", dta.dom$service_provider_2016)
dta.2016$service_provider_2016 <- gsub("Bright House Net", "Charter", dta.2016$service_provider_2016)
dta.2016.all$service_provider_2016 <- gsub("Bright House Net", "Charter", dta.2016.all$service_provider_2016)
dta.dom$service_provider_2016 <- gsub("Time Warner Cable Business LLC", "Charter", dta.dom$service_provider_2016)
dta.2016$service_provider_2016 <- gsub("Time Warner Cable Business LLC", "Charter", dta.2016$service_provider_2016)
dta.2016.all$service_provider_2016 <- gsub("Time Warner Cable Business LLC", "Charter", dta.2016.all$service_provider_2016)
dta.2016 <- dta.2016[!is.na(dta.2016$esh_id),]
dta.2016.all <- dta.2016.all[!is.na(dta.2016.all$esh_id),]
dta.2015 <- dta.2015[!is.na(dta.2015$esh_id),]


## what's the breakdown of purpose of the two dominant providers?
## redefine purpose for this quick analysis
dta.dom$purpose2_2015 <- ifelse(dta.dom$purpose_2015 == "Internet, Upstream" | dta.dom$purpose_2015 == "Upstream, Internet", "Both", dta.dom$purpose_2015)
dta.dom$purpose2_2016 <- ifelse(dta.dom$purpose_2016 == "Internet, Upstream" | dta.dom$purpose_2016 == "Upstream, Internet", "Both", dta.dom$purpose_2016)
tab <- table(dta.dom$purpose2_2015, dta.dom$purpose2_2016)
## 92% stayed the same
sum(diag(tab)) / nrow(dta.dom)
## DECISION: subset to only the diagonal for the cost_per_mbps
dta.dom$eligible_for_cost_per_mbps <- ifelse(dta.dom$purpose2_2015 == dta.dom$purpose2_2016, 1, NA)
## calculate cost_per_mbps
dta.dom$sp_ia_monthly_cost_per_mbps_2015 <- round(dta.dom$total_monthly_cost_2015 / dta.dom$bandwidth_in_mbps_2015, 2)
dta.dom$sp_ia_monthly_cost_per_mbps_2016 <- round(dta.dom$total_monthly_cost_2016 / dta.dom$bandwidth_in_mbps_2016, 2)
dta.dom$sp_ia_monthly_cost_per_mbps_2015 <- dta.dom$sp_ia_monthly_cost_per_mbps_2015 * dta.dom$eligible_for_cost_per_mbps
dta.dom$sp_ia_monthly_cost_per_mbps_2016 <- dta.dom$sp_ia_monthly_cost_per_mbps_2016 * dta.dom$eligible_for_cost_per_mbps
## also calculate total bw change
dta.dom$bw.change <- dta.dom$bandwidth_in_mbps_2016 - dta.dom$bandwidth_in_mbps_2015
dta.dom$bw.change.perc <- round(dta.dom$bw.change / dta.dom$bandwidth_in_mbps_2015, 2)
## create variable of total cost change
dta.dom$total.cost.change <- dta.dom$total_monthly_cost_2016 - dta.dom$total_monthly_cost_2015
dta.dom$total.cost.change.perc <- round(dta.dom$total.cost.change / dta.dom$total_monthly_cost_2015, 2)
## create variable of cost/mbps change
dta.dom$cost.per.mbps.change <- dta.dom$sp_ia_monthly_cost_per_mbps_2016 - dta.dom$sp_ia_monthly_cost_per_mbps_2015
dta.dom$cost.per.mbps.change.perc <- round(dta.dom$cost.per.mbps.change / dta.dom$sp_ia_monthly_cost_per_mbps_2015, 2)

## write out the datasets
write.csv(dta.dom, "../data/service_provider_master.csv", row.names=F)
write.csv(dta.2015, "../data/2015_service_providers_to_districts.csv", row.names=F)
write.csv(dta.2016, "../data/2016_service_providers_to_districts.csv", row.names=F)
write.csv(dta.2016.all, "../data/2016_service_providers_to_districts_all.csv", row.names=F)

