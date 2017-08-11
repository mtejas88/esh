## ======================================================================================
##
## CREATE LOGIC FOR PICKING THE "BEST" SCALABLE IA/WAN LINE FOR A DISTRICT
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
sc_2017 <- read.csv("data/raw/2017_scalable_line_items.csv")

##**************************************************************************************************************************************************

## how many clean districts overall?
dd_2017_sub <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$exclude_from_ia_analysis == FALSE),]

## subset to only clean districts and line items
## not subsetting to district_type = Traditional since we are including AZ Charters
sr_2017_sub <- sr_2017[which(sr_2017$recipient_include_in_universe_of_districts == TRUE &
                               sr_2017$recipient_exclude_from_ia_analysis == FALSE &
                               sr_2017$inclusion_status %in% c('clean_no_cost', 'clean_with_cost') &
                               (sr_2017$connect_category %in% c('Lit Fiber', 'Dark Fiber')) &
                               sr_2017$purpose %in% c('Internet', 'Upstream', 'WAN')),]

## format when monthly_circuit_cost_recurring == 0:
## use monthly_circuit_cost_total / months_of_service
sr_2017_sub$monthly_circuit_cost_recurring <- ifelse(sr_2017_sub$monthly_circuit_cost_recurring == 0,
                                                     sr_2017_sub$monthly_circuit_cost_total,
                                                     sr_2017_sub$monthly_circuit_cost_recurring)
## create an indicator for scalable IA and WAN
sr_2017_sub$scalable_ia <- ifelse(sr_2017_sub$purpose %in% c('Internet', 'Upstream'), 1, 0)
sr_2017_sub$scalable_wan <- ifelse(sr_2017_sub$purpose == 'WAN', 1, 0)

## create cost per mbps indicator
sr_2017_sub$ia_cost_per_mbps_line_item <- sr_2017_sub$monthly_circuit_cost_recurring / sr_2017_sub$bandwidth_in_mbps

## aggregate the scalable line items for each district
district.agg.ia <- aggregate(sr_2017_sub$scalable_ia, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.ia) <- c('recipient_id', 'scalable_ia')

district.agg.wan <- aggregate(sr_2017_sub$scalable_wan, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.wan) <- c('recipient_id', 'scalable_wan')

##----------------------------------------------------------------------------------------------------------------------------------
## SCALABLE CIRCUITS (IA)

## subset to IA line items
sr_2017_sub_scalable_ia <- sr_2017_sub[which(sr_2017_sub$scalable_ia == 1),]
## order by lowest cost (increasing)
sr_2017_sub_scalable_ia <- sr_2017_sub_scalable_ia %>% arrange(recipient_id, ia_cost_per_mbps_line_item)
## collect unique districts that have a scalable ia line item not equal to 0 cost
districts <- unique(sr_2017_sub_scalable_ia$recipient_id[sr_2017_sub_scalable_ia$ia_cost_per_mbps_line_item != 0])
## create an empty dataset (rows = unique districts)
dta_scalable_ia <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_scalable_ia) <- c('recipient_id', 'scalable_ia_line_id')
## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_scalable_ia[which(sr_2017_sub_scalable_ia$recipient_id == districts[i] & sr_2017_sub_scalable_ia$ia_cost_per_mbps_line_item != 0),]
  dta_scalable_ia$recipient_id[i] <- districts[i]
  dta_scalable_ia$scalable_ia_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_scalable_ia <- merge(dta_scalable_ia, sr_2017_sub_scalable_ia[,c("recipient_id", "line_item_id", "bandwidth_in_mbps",
                                                                     "monthly_circuit_cost_recurring", "connect_category",
                                                                     "service_provider_name", "reporting_name", "ia_cost_per_mbps_line_item")],
                         by.x=c('recipient_id', 'scalable_ia_line_id'), by.y=c('recipient_id', 'line_item_id'), all.x=T)


##----------------------------------------------------------------------------------------------------------------------------------
## SCALABLE CIRCUITS (WAN)

## subset to wan line items
sr_2017_sub_scalable_wan <- sr_2017_sub[which(sr_2017_sub$scalable_wan == 1),]
## collect unique districts that have a scalable wan line item
districts <- unique(sr_2017_sub_scalable_wan$recipient_id)
## create an empty dataset (rows = unique districts)
dta_scalable_wan <- data.frame(matrix(NA, nrow=length(districts), ncol=2))
names(dta_scalable_wan) <- c('recipient_id', 'scalable_wan_line_id')
## for each district, choose the line that best meets the qualifications above
for (i in 1:length(districts)){
  sub <- sr_2017_sub_scalable_wan[which(sr_2017_sub_scalable_wan$recipient_id == districts[i]),]
  dta_scalable_wan$recipient_id[i] <- districts[i]
  dta_scalable_wan$scalable_wan_line_id[i] <- sub$line_item_id[1]
}
## merge in other info for the line item
dta_scalable_wan <- merge(dta_scalable_wan, sr_2017_sub_scalable_wan[,c("recipient_id", "line_item_id", "bandwidth_in_mbps",
                                                                     "monthly_circuit_cost_recurring", "connect_category",
                                                                     "service_provider_name", "reporting_name")],
                         by.x=c('recipient_id', 'scalable_wan_line_id'), by.y=c('recipient_id', 'line_item_id'), all.x=T)

##----------------------------------------------------------------------------------------------------------------------------------
## QA

## merge together scalable ia and wan ids
combined <- merge(dta_scalable_ia[,c('recipient_id', 'scalable_ia_line_id')],
                  dta_scalable_wan[,c('recipient_id', 'scalable_wan_line_id')], by='recipient_id', all=T)

## merge with QA
names(sc_2017) <- paste(names(sc_2017), "_qa", sep="")
combined <- merge(combined, sc_2017[,c('esh_id_qa', "line_item_id_scalable_ia_qa", "line_item_id_scalable_wan_qa")],
                  by.x='recipient_id', by.y='esh_id_qa', all=T)
## compare IA
combined$ia_compare <- ifelse(is.na(combined$scalable_ia_line_id) & is.na(combined$line_item_id_scalable_ia_qa), NA,
                              ifelse(!is.na(combined$scalable_ia_line_id) & is.na(combined$line_item_id_scalable_ia_qa), "NOT",
                                     ifelse(is.na(combined$scalable_ia_line_id) & !is.na(combined$line_item_id_scalable_ia_qa), "NOT",
                                            ifelse(combined$scalable_ia_line_id == combined$line_item_id_scalable_ia_qa, "SAME", "NOT"))))
table(combined$ia_compare)
## confirm that the ones that differ have the same ia_cost_per_mbps_line_item
sub.ia <- combined[which(combined$ia_compare == 'NOT'),]
sub.agg.ia <- district.agg.ia[which(district.agg.ia$recipient_id %in% sub.ia$recipient_id),]
table(sub.agg.ia$scalable_ia > 1)
for (i in 1:nrow(sub.ia)){
  sub <- sr_2017_sub_scalable_ia[which(sr_2017_sub_scalable_ia$recipient_id == sub.agg.ia$recipient_id[i]),]
  sub <- sub[sub$line_item_id %in% c(sub.ia$scalable_ia_line_id[sub.ia$recipient_id == sub.agg.ia$recipient_id[i]],
                                     sub.ia$line_item_id_scalable_ia_qa[sub.ia$recipient_id == sub.agg.ia$recipient_id[i]]),]
  if (sub$ia_cost_per_mbps_line_item[1] != sub$ia_cost_per_mbps_line_item[2]){
    print('NOT THE SAME:', sub$recipient_id[i])
  }
}

## compare WAN
combined$wan_compare <- ifelse(is.na(combined$scalable_wan_line_id) & is.na(combined$line_item_id_scalable_wan_qa), NA,
                               ifelse(!is.na(combined$scalable_wan_line_id) & is.na(combined$line_item_id_scalable_wan_qa), "NOT",
                                      ifelse(is.na(combined$scalable_wan_line_id) & !is.na(combined$line_item_id_scalable_wan_qa), "NOT",
                                             ifelse(combined$scalable_wan_line_id == combined$line_item_id_scalable_wan_qa, "SAME", "NOT"))))
table(combined$wan_compare)
## confirm that the ones that differ have the same monthly_circuit_cost_recurring and copper indicator
sub.wan <- combined[which(combined$wan_compare == 'NOT'),]
table(is.na(sub.wan$scalable_wan_line_id))
table(is.na(sub.wan$line_item_id_scalable_wan_qa))
sub.agg.wan <- district.agg.wan[which(district.agg.wan$recipient_id %in% sub.wan$recipient_id),]
table(sub.agg.wan$scalable_wan > 1)

