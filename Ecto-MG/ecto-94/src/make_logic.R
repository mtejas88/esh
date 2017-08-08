## ======================================================================================
##
## CREATE LOGIC FOR PICKING THE WORST UNSCALABLE/SCALABLE IA/WAN LINE FOR A DISTRICT
##
## ======================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-94/")

library(dplyr) ## for the arrange function

##**************************************************************************************************************************************************
## READ IN DATA

dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv")
sr_2017 <- read.csv("data/raw/2017_services_recieved.csv")

##**************************************************************************************************************************************************

## how many clean districts overall?
dd_2017_sub <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$exclude_from_ia_analysis == FALSE),]

## subset to only clean districts and line items
## not subsetting to district_type = Traditional since we are including AZ Charters
sr_2017_sub <- sr_2017[which(sr_2017$recipient_include_in_universe_of_districts == TRUE &
                     sr_2017$recipient_exclude_from_ia_analysis == FALSE &
                     sr_2017$inclusion_status %in% c('clean_no_cost', 'clean_with_cost')),]

## format when monthly_circuit_cost_recurring == 0:
## use monthly_circuit_cost_total / months_of_service
sr_2017_sub$monthly_circuit_cost_recurring <- ifelse(sr_2017_sub$monthly_circuit_cost_recurring == 0,
                                                     sr_2017_sub$monthly_circuit_cost_total,
                                                     sr_2017_sub$monthly_circuit_cost_recurring)

## create an indicator for ISP (make NA for scalable/unscalable)
sr_2017_sub$isp_indicator <- ifelse(sr_2017_sub$connect_category == 'ISP Only' | sr_2017_sub$purpose == 'ISP', 1, 0)

## create an indicator for Copper services ('DSL', 'T-1', 'Cable', 'Other Copper')
sr_2017_sub$copper <- ifelse(sr_2017_sub$connect_category %in% c('DSL', 'T-1', 'Cable', 'Other Copper'), 1, 0)

## create an indicator for scalable vs unscalable
sr_2017_sub$unscalable_ia <- ifelse(!sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') &
                                      sr_2017_sub$isp_indicator != 1 &
                                      sr_2017_sub$purpose %in% c('Internet', 'Upstream'), 1, ifelse(sr_2017_sub$isp_indicator == 1, NA, 0))
sr_2017_sub$unscalable_wan <- ifelse(!sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') &
                                      sr_2017_sub$isp_indicator != 1 & sr_2017_sub$purpose == 'WAN', 1,
                                     ifelse(sr_2017_sub$isp_indicator == 1, NA, 0))
sr_2017_sub$scalable_ia <- ifelse(sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') &
                                  sr_2017_sub$isp_indicator != 1 &
                                  sr_2017_sub$purpose %in% c('Internet', 'Upstream'), 1, ifelse(sr_2017_sub$isp_indicator == 1, NA, 0))
sr_2017_sub$scalable_wan <- ifelse(sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') &
                                   sr_2017_sub$isp_indicator != 1 & sr_2017_sub$purpose == 'WAN', 1,
                                   ifelse(sr_2017_sub$isp_indicator == 1, NA, 0))

## aggregate the unscalable line items for each district
district.agg.ia <- aggregate(sr_2017_sub$unscalable_ia, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.ia) <- c('recipient_id', 'unscalable_ia')

district.agg.wan <- aggregate(sr_2017_sub$unscalable_wan, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.wan) <- c('recipient_id', 'unscalable_wan')


##----------------------------------------------------------------------------------------------------------------------------------
## UNSCALABLE CIRCUITS (IA and WAN)

## subset to only unscalable_ia line items
sr_2017_sub_unscalable_ia <- sr_2017_sub[which(sr_2017_sub$unscalable_ia == 1),]
## order by highest cost (decreasing), and copper for each district
sr_2017_sub_unscalable_ia <- sr_2017_sub_unscalable_ia %>% arrange(recipient_id, desc(monthly_circuit_cost_recurring), desc(copper))
## collect unique districts
districts <- unique(sr_2017_sub_unscalable_ia$recipient_id)
## create an empty dataset (rows = unique districts)
dta_unscalable_ia <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_unscalable_ia) <- c('recipient_id', 'unscalable_ia_line_id')
## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_unscalable_ia[which(sr_2017_sub_unscalable_ia$recipient_id == districts[i]),]
  dta_unscalable_ia$recipient_id[i] <- districts[i]
  dta_unscalable_ia$unscalable_ia_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_unscalable_ia <- merge(dta_unscalable_ia, sr_2017_sub_unscalable_ia[,c("recipient_id", "line_item_id", "bandwidth_in_mbps",
                                                                           "monthly_circuit_cost_recurring", "connect_category",
                                                                           "service_provider_name", "reporting_name")],
                                              by.x=c('recipient_id', 'unscalable_ia_line_id'), by.y=c('recipient_id', 'line_item_id'), all.x=T)

## subset to only unscalable_wan line items
sr_2017_sub_unscalable_wan <- sr_2017_sub[which(sr_2017_sub$unscalable_wan == 1),]
## order by highest cost (decreasing), and copper for each district
sr_2017_sub_unscalable_wan <- sr_2017_sub_unscalable_wan %>% arrange(recipient_id, desc(monthly_circuit_cost_recurring), desc(copper))
## collect unique districts
districts <- unique(sr_2017_sub_unscalable_wan$recipient_id)
## create an empty dataset (rows = unique districts)
dta_unscalable_wan <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_unscalable_wan) <- c('recipient_id', 'unscalable_wan_line_id')
## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_unscalable_wan[which(sr_2017_sub_unscalable_wan$recipient_id == districts[i]),]
  dta_unscalable_wan$recipient_id[i] <- districts[i]
  dta_unscalable_wan$unscalable_wan_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_unscalable_wan <- merge(dta_unscalable_wan, sr_2017_sub_unscalable_wan[,c("recipient_id", "line_item_id", "bandwidth_in_mbps",
                                                                              "monthly_circuit_cost_recurring", "connect_category",
                                                                              "service_provider_name", "reporting_name")],
                                                by.x=c('recipient_id', 'unscalable_wan_line_id'), by.y=c('recipient_id', 'line_item_id'), all.x=T)





##----------------------------------------------------------------------------------------------------------------------------------
## SCALABLE -- Not Ready Yet

## subset to districts with no unscalable_ia line items
sr_2017_sub_scalable_ia <- sr_2017_sub[which(sr_2017_sub$scalable_ia == 1),]
## order by highest cost (decreasing), and copper for each district
sr_2017_sub_scalable_ia <- sr_2017_sub_scalable_ia %>% arrange(recipient_id, bandwidth_in_mbps, monthly_circuit_cost_recurring)
## collect unique districts
districts <- unique(sr_2017_sub_scalable_ia$recipient_id)
## create an empty dataset (rows = unique districts)
dta_scalable_ia <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_scalable_ia) <- c('recipient_id', 'scalable_ia_line_id')
## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_scalable_ia[which(sr_2017_sub_scalable_ia$recipient_id == districts[i]),]
  dta_scalable_ia$recipient_id[i] <- districts[i]
  dta_scalable_ia$scalable_ia_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_scalable_ia <- merge(dta_scalable_ia, sr_2017_sub_scalable_ia[,c("recipient_id", "line_item_id", "bandwidth_in_mbps",
                                                                     "monthly_circuit_cost_recurring", "connect_category",
                                                                     "service_provider_name", "reporting_name")],
                                          by.x=c('recipient_id', 'scalable_ia_line_id'), by.y=c('recipient_id', 'line_item_id'), all.x=T)


##----------------------------------------------------------------------------------------------------------------------------------
## SCALABLE
## only calculate for the districts that don't have unscalable lines for each IA and WAN

## for each district, find the "lowest" scalable line item with the following logic:
## If there are multiple scalable connections:
##  1) Choose the one with the lowest bandwidth.
##    If TIE:
##      2) Choose the lower priced scalable line.
##        If TIE:
##          3) Pick one at random.

## subset to districts with no unscalable_ia line items
sr_2017_sub_scalable_ia <- sr_2017_sub[which(sr_2017_sub$recipient_id %in% district.agg.ia$recipient_id[district.agg.ia$unscalable_ia == 0]),]
sr_2017_sub_scalable_ia <- sr_2017_sub_scalable_ia[which(sr_2017_sub_scalable_ia$purpose %in% c('Internet', 'ISP', 'Bundled')),]
districts <- unique(sr_2017_sub_scalable_ia$recipient_id)
## create an empty dataset (rows = unique districts)
dta_scalable_ia <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_scalable_ia) <- c('recipient_id', 'scalable_ia_line_id')

## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_scalable_ia[which(sr_2017_sub_scalable_ia$recipient_id == districts[i]),]
  ## if more than 1 line item:
  if (nrow(sub) > 1){
    ## select the smallest bw
    sub <- sub[order(sub$bandwidth_in_mbps, decreasing=F),]
    ## if a tie between the first and second:
    if (nrow(sub) >= 2){
      if (sub$bandwidth_in_mbps[1] == sub$bandwidth_in_mbps[2]){
        sub <- sub[which(sub$bandwidth_in_mbps == sub$bandwidth_in_mbps[1]),]
        ## choose the lower priced line
        min.mrc <- min(sub$monthly_circuit_cost_recurring, na.rm=T)
        sub <- sub[which(sub$monthly_circuit_cost_recurring == min.mrc),]
        ## if stil a tie:
        if (nrow(sub) > 1){
          ## randomly select 1
          sub <- sub[sample(1:nrow(sub), 1, replace=F),]
        }
      }
    }
  }
  ## now assign whatever's leftover
  dta_scalable_ia$recipient_id[i] <- districts[i]
  dta_scalable_ia$scalable_ia_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item -- problem: there are not unique line item ids
dta_scalable_ia <- merge(dta_scalable_ia, sr_2017_sub_scalable_ia[,c("line_item_id", "recipient_id", "bandwidth_in_mbps",
                                                                      "monthly_circuit_cost_recurring", "connect_category",
                                                                      "service_provider_name")],
                           by.x=c('scalable_ia_line_id', 'recipient_id'), by.y=c('line_item_id', 'recipient_id'), all.x=T)


## NOTES:
## unscalable_ia_bw_per_connection_mbps
## unscalable_ia_mrc_per_connection
## unscalable_ia_connect_category	    
## unscalable_ia_service_provider_name

## unscalable_wan_bw_per_connection_mbps
## unscalable_wan_mrc_per_connection
## unscalable_wan_connect_category	    
## unscalable_wan_service_provider_name

## scalable_ia_bw_per_connection_mbps	
## scalable_ia_mrc_per_connection
## scalable_ia_service_provider_name

## scalable_wan_bw_per_connection_mbps	
## scalable_wan_mrc_per_connection
## scalable_wan_service_provider_name
