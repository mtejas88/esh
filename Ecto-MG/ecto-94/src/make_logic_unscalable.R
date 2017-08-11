## ======================================================================================
##
## CREATE LOGIC FOR PICKING THE "WORST" UNSCALABLE IA/WAN LINE FOR A DISTRICT
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
uc_2017 <- read.csv("data/raw/2017_unscalable_line_items.csv")
#uc_ia <- read.csv("data/raw/2017_unscalable_ia.csv")
#uc_wan <- read.csv("data/raw/2017_unscalable_wan.csv")

##**************************************************************************************************************************************************

## how many clean districts overall?
dd_2017_sub <- dd_2017[which(dd_2017$include_in_universe_of_districts == TRUE & dd_2017$exclude_from_ia_analysis == FALSE),]

## subset to only clean districts and line items
## not subsetting to district_type = Traditional since we are including AZ Charters
sr_2017_sub <- sr_2017[which(sr_2017$recipient_include_in_universe_of_districts == TRUE &
                     sr_2017$recipient_exclude_from_ia_analysis == FALSE &
                     sr_2017$inclusion_status %in% c('clean_no_cost', 'clean_with_cost') &
                     (!sr_2017$connect_category %in% c('ISP Only', 'Lit Fiber', 'Dark Fiber')) &
                     sr_2017$purpose %in% c('Internet', 'Upstream', 'WAN')),]

## format when monthly_circuit_cost_recurring == 0:
## use monthly_circuit_cost_total / months_of_service
sr_2017_sub$monthly_circuit_cost_recurring <- ifelse(sr_2017_sub$monthly_circuit_cost_recurring == 0,
                                                     sr_2017_sub$monthly_circuit_cost_total,
                                                     sr_2017_sub$monthly_circuit_cost_recurring)

## create an indicator for ISP (make NA for scalable/unscalable)
#sr_2017_sub$isp_indicator <- ifelse(sr_2017_sub$connect_category == 'ISP Only' | sr_2017_sub$purpose == 'ISP', 1, 0)

## create an indicator for Copper services ('DSL', 'T-1', 'Cable', 'Other Copper')
sr_2017_sub$copper <- ifelse(sr_2017_sub$connect_category %in% c('DSL', 'T-1', 'Cable', 'Other Copper'), 1, 0)

## create an indicator for unscalable IA and WAN
sr_2017_sub$unscalable_ia <- ifelse(sr_2017_sub$purpose %in% c('Internet', 'Upstream'), 1, 0)
sr_2017_sub$unscalable_wan <- ifelse(sr_2017_sub$purpose == 'WAN', 1, 0)

## aggregate the unscalable line items for each district
district.agg.ia <- aggregate(sr_2017_sub$unscalable_ia, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.ia) <- c('recipient_id', 'unscalable_ia')

district.agg.wan <- aggregate(sr_2017_sub$unscalable_wan, by=list(sr_2017_sub$recipient_id), FUN=sum, na.rm=T)
names(district.agg.wan) <- c('recipient_id', 'unscalable_wan')

##----------------------------------------------------------------------------------------------------------------------------------
## UNSCALABLE CIRCUITS (IA)

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

##----------------------------------------------------------------------------------------------------------------------------------
## UNSCALABLE CIRCUITS (WAN)

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
## QA

## merge together unscalable ia and wan ids
combined <- merge(dta_unscalable_ia[,c('recipient_id', 'unscalable_ia_line_id')],
                  dta_unscalable_wan[,c('recipient_id', 'unscalable_wan_line_id')], by='recipient_id', all=T)

## merge with QA
names(uc_2017) <- paste(names(uc_2017), "_qa", sep="")
combined <- merge(combined, uc_2017[,c('esh_id_qa', "line_item_id_unscalable_ia_qa", "line_item_id_unscalable_wan_qa")],
                  by.x='recipient_id', by.y='esh_id_qa', all=T)
## compare IA
combined$ia_compare <- ifelse(is.na(combined$unscalable_ia_line_id) & is.na(combined$line_item_id_unscalable_ia_qa), NA,
                               ifelse(!is.na(combined$unscalable_ia_line_id) & is.na(combined$line_item_id_unscalable_ia_qa), "NOT",
                                      ifelse(is.na(combined$unscalable_ia_line_id) & !is.na(combined$line_item_id_unscalable_ia_qa), "NOT",
                                             ifelse(combined$unscalable_ia_line_id == combined$line_item_id_unscalable_ia_qa, "SAME", "NOT"))))
table(combined$ia_compare)
## confirm that the ones that differ have the same monthly_circuit_cost_recurring and copper indicator
sub.ia <- combined[which(combined$ia_compare == 'NOT'),]
sub.agg.ia <- district.agg.ia[which(district.agg.ia$recipient_id %in% sub.ia$recipient_id),]
table(sub.agg.ia$unscalable_ia > 1)
for (i in 1:nrow(sub.ia)){
  sub <- sr_2017_sub_unscalable_ia[which(sr_2017_sub_unscalable_ia$recipient_id == sub.agg.ia$recipient_id[i]),]
  sub <- sub[sub$line_item_id %in% c(sub.ia$unscalable_ia_line_id[sub.ia$recipient_id == sub.agg.ia$recipient_id[i]],
                                     sub.ia$line_item_id_unscalable_ia_qa[sub.ia$recipient_id == sub.agg.ia$recipient_id[i]]),]
  if ((sub$monthly_circuit_cost_recurring[1] != sub$monthly_circuit_cost_recurring[2]) | (sub$copper[1] != sub$copper[2])){
    print('NOT THE SAME:', sub$recipient_id[i])
  }
}

## compare WAN
combined$wan_compare <- ifelse(is.na(combined$unscalable_wan_line_id) & is.na(combined$line_item_id_unscalable_wan_qa), NA,
                               ifelse(!is.na(combined$unscalable_wan_line_id) & is.na(combined$line_item_id_unscalable_wan_qa), "NOT",
                                      ifelse(is.na(combined$unscalable_wan_line_id) & !is.na(combined$line_item_id_unscalable_wan_qa), "NOT",
                                             ifelse(combined$unscalable_wan_line_id == combined$line_item_id_unscalable_wan_qa, "SAME", "NOT"))))
table(combined$wan_compare)
## confirm that the ones that differ have the same monthly_circuit_cost_recurring and copper indicator
sub.wan <- combined[which(combined$wan_compare == 'NOT'),]
sub.agg.wan <- district.agg.wan[which(district.agg.wan$recipient_id %in% sub.wan$recipient_id),]
table(sub.agg.wan$unscalable_wan > 1)
for (i in 1:nrow(sub.wan)){
  sub <- sr_2017_sub_unscalable_wan[which(sr_2017_sub_unscalable_wan$recipient_id == sub.agg.wan$recipient_id[i]),]
  sub <- sub[sub$line_item_id %in% c(sub.wan$unscalable_wan_line_id[sub.wan$recipient_id == sub.agg.wan$recipient_id[i]],
                                     sub.wan$line_item_id_unscalable_wan_qa[sub.wan$recipient_id == sub.agg.wan$recipient_id[i]]),]
  if ((sub$monthly_circuit_cost_recurring[1] != sub$monthly_circuit_cost_recurring[2]) | (sub$copper[1] != sub$copper[2])){
    print('NOT THE SAME:', sub$recipient_id[i])
  }
}

#names(uc_wan) <- paste(names(uc_wan), "_qa", sep="")
#combined_wan <- merge(dta_unscalable_wan[,c('recipient_id', 'unscalable_wan_line_id')],
#                      uc_wan[,c('recipient_id_qa', "line_item_id_unscalable_wan_qa")],
#                      by.x='recipient_id', by.y='recipient_id_qa', all=T)
#combined_wan$diff <- ifelse(combined_wan$unscalable_wan_line_id == combined_wan$line_item_id_unscalable_wan_qa, FALSE, TRUE)
#table(combined_wan$diff)

#names(uc_ia) <- paste(names(uc_ia), "_qa", sep="")
#combined_ia <- merge(dta_unscalable_ia[,c('recipient_id', 'unscalable_ia_line_id')],
#                      uc_ia[,c('recipient_id_qa', "line_item_id_unscalable_ia_qa")],
#                      by.x='recipient_id', by.y='recipient_id_qa', all=T)
#combined_ia$diff <- ifelse(combined_ia$unscalable_ia_line_id == combined_ia$line_item_id_unscalable_ia_qa, FALSE, TRUE)

