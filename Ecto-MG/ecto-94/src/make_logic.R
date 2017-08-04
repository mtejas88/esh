## ======================================================================================
##
## CREATE LOGIC FOR PICKING THE WORST UNSCALABLE/SCALABLE IA/WAN LINE FOR A DISTRICT
##
## ======================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-94/")

##**************************************************************************************************************************************************
## READ IN DATA

dd_2017 <- read.csv("data/raw/2017_deluxe_districts.csv")
sr_2017 <- read.csv("data/raw/2017_services_recieved.csv")

##**************************************************************************************************************************************************

## how many clean districts overall?
dd_2017_sub <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$exclude_from_ia_analysis == FALSE),]


## subset to only clean districts and line items
sr_2017_sub <- sr_2017[which(sr_2017$recipient_include_in_universe_of_districts == TRUE &
                     sr_2017$recipient_exclude_from_ia_analysis == FALSE &
                     sr_2017$inclusion_status %in% c('clean_no_cost', 'clean_with_cost')),]

table(sr_2017_sub$connect_category)

## create an indicator for scalable vs unscalable
sr_2017_sub$unscalable_ia <- ifelse(!sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber', 'ISP Only') &
                                      sr_2017_sub$purpose %in% c('ISP', 'Internet', 'Backbone'), 1,
                                 ifelse(sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') &
                                          sr_2017_sub$purpose %in% c('ISP', 'Internet', 'Backbone'), 0, NA))
sr_2017_sub$unscalable_wan <- ifelse(!sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber', 'ISP Only') & sr_2017_sub$purpose == 'WAN', 1,
                                    ifelse(sr_2017_sub$connect_category %in% c('Lit Fiber', 'Dark Fiber') & sr_2017_sub$purpose == 'WAN', 0, NA))
## create a column that multiplies the number of lines by bandwidth
sr_2017_sub$bandwidth_multiplied_by_line_items <- sr_2017_sub$quantity_of_line_items_received_by_district * sr_2017_sub$bandwidth_in_mbps

## aggregate the unscalable line items for each district
district.agg.ia <- aggregate(sr_2017_sub$unscalable_ia, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.ia) <- c('recipient_id', 'unscalable_ia')

district.agg.wan <- aggregate(sr_2017_sub$unscalable_wan, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.wan) <- c('recipient_id', 'unscalable_wan')

##----------------------------------------------------------------------------------------------------------------------------------
## UNSCALABLE

## for each district, find the "worst" unscalable line item with the following logic:
## If there are multiple unscalable connections:
##  1) Choose the one with the highest bandwidth.
##    If TIE:
##      2) Choose the higher priced unscalable line.
##        If TIE:
##        3) Choose the one with Copper.
##          If TIE:
##          4) Pick one at random.

## subset to unscalable_ia line items
sr_2017_sub_unscalable_ia <- sr_2017_sub[which(sr_2017_sub$unscalable_ia == 1),]
districts <- unique(sr_2017_sub_unscalable_ia$recipient_id)
## create an empty dataset (rows = unique districts)
dta_unscalable_ia <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_unscalable_ia) <- c('recipient_id', 'unscalable_ia_line_id')

## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_unscalable_ia[which(sr_2017_sub_unscalable_ia$recipient_id == districts[i]),]
  ## if more than 1 line item:
  if (nrow(sub) > 1){
    ## select the largest bw
    sub <- sub[order(sub$bandwidth_multiplied_by_line_items, decreasing=T),]
    ## if a tie between the first and second:
    if (nrow(sub) >= 2){
      if (sub$bandwidth_multiplied_by_line_items[1] == sub$bandwidth_multiplied_by_line_items[2]){
        sub <- sub[which(sub$bandwidth_multiplied_by_line_items == sub$bandwidth_multiplied_by_line_items[1]),]
        ## choose the higher priced line
        max.mrc <- max(sub$line_item_mrc_unless_null, na.rm=T)
        sub <- sub[which(sub$line_item_mrc_unless_null == max.mrc),]
        ## if stil a tie:
        if (nrow(sub) > 1){
          ## subset to Copper
          if ("Copper" %in% sub$connect_category){
            sub <- sub[which(sub$connect_category == 'Copper'),]
          }
          ## if STILL a tie:
          if (nrow(sub) > 1){
            ## randomly select 1
            sub <- sub[sample(1:nrow(sub), 1, replace=F),]
          }
        }
      }
    }
  }
  ## now assign whatever's leftover
  dta_unscalable_ia$recipient_id[i] <- districts[i]
  dta_unscalable_ia$unscalable_ia_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_unscalable_ia <- merge(dta_unscalable_ia, sr_2017_sub_unscalable_ia[,c("line_item_id", "bandwidth_in_mbps",
                                                                              "line_item_mrc_unless_null", "connect_category",
                                                                              "service_provider_name")],
                            by.x='unscalable_ia_line_id', by.y='line_item_id', all.x=T)

## now do the same for unscalable WAN lines:

## subset to unscalable_wan line items
sr_2017_sub_unscalable_wan <- sr_2017_sub[which(sr_2017_sub$unscalable_wan == 1),]
districts <- unique(sr_2017_sub_unscalable_wan$recipient_id)
## create an empty dataset (rows = unique districts)
dta_unscalable_wan <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_unscalable_wan) <- c('recipient_id', 'unscalable_wan_line_id')

## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_unscalable_wan[which(sr_2017_sub_unscalable_wan$recipient_id == districts[i]),]
  ## if more than 1 line item:
  if (nrow(sub) > 1){
    ## select the largest bw
    sub <- sub[order(sub$bandwidth_multiplied_by_line_items, decreasing=T),]
    ## if a tie between the first and second:
    if (nrow(sub) >= 2){
      if (sub$bandwidth_multiplied_by_line_items[1] == sub$bandwidth_multiplied_by_line_items[2]){
        sub <- sub[which(sub$bandwidth_multiplied_by_line_items == sub$bandwidth_multiplied_by_line_items[1]),]
        ## choose the higher priced line
        max.mrc <- max(sub$line_item_mrc_unless_null, na.rm=T)
        sub <- sub[which(sub$line_item_mrc_unless_null == max.mrc),]
        ## if stil a tie:
        if (nrow(sub) > 1){
          ## subset to Copper
          if ("Copper" %in% sub$connect_category){
            sub <- sub[which(sub$connect_category == 'Copper'),]
          }
          ## if STILL a tie:
          if (nrow(sub) > 1){
            ## randomly select 1
            sub <- sub[sample(1:nrow(sub), 1, replace=F),]
          }
        }
      }
    }
  }
  ## now assign whatever's leftover
  dta_unscalable_wan$recipient_id[i] <- districts[i]
  dta_unscalable_wan$unscalable_wan_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_unscalable_wan <- merge(dta_unscalable_wan, sr_2017_sub_unscalable_wan[,c("line_item_id", "bandwidth_in_mbps",
                                                                              "line_item_mrc_unless_null", "connect_category",
                                                                              "service_provider_name")],
                            by.x='unscalable_wan_line_id', by.y='line_item_id', all.x=T)

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
    sub <- sub[order(sub$bandwidth_multiplied_by_line_items, decreasing=F),]
    ## if a tie between the first and second:
    if (nrow(sub) >= 2){
      if (sub$bandwidth_multiplied_by_line_items[1] == sub$bandwidth_multiplied_by_line_items[2]){
        sub <- sub[which(sub$bandwidth_multiplied_by_line_items == sub$bandwidth_multiplied_by_line_items[1]),]
        ## choose the lower priced line
        min.mrc <- min(sub$line_item_mrc_unless_null, na.rm=T)
        sub <- sub[which(sub$line_item_mrc_unless_null == min.mrc),]
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
dta_scalable_ia <- merge(dta_scalable_ia, sr_2017_sub_scalable_ia[,c("line_item_id", "bandwidth_in_mbps",
                                                                      "line_item_mrc_unless_null", "connect_category",
                                                                      "service_provider_name")],
                           by.x='scalable_ia_line_id', by.y='line_item_id', all.x=T)


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

## Questions: 
## 1) for IA, is it just sr_2017$purpose == "Internet"? Or also "ISP" and "Backbone"?
## 2) should the bandwidth be defined as bandwidth_multiplied_by_line_items? ia_bw_per_connection_mbps
## 3) is line_item_mrc_unless_null the correct "mrc per connection"?
## 4) Are we using Service Provider name or reporting name?

