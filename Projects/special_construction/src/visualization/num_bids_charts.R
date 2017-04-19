library(lubridate)
library(ggplot2)
library(dplyr)
library(plotly)
library(ggmap)
library(RColorBrewer)
library(scales)
library(gridExtra)

##bids prepping
bids <- read.csv("C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/external/frns_with_district_info.csv", 
                 as.is=TRUE)
bids <- filter(bids, bids$num_bids_received < 26)
bids$indic_0_bids <- ifelse(bids$num_bids_received == 0,1,0)
bids$indic_1_bids <- ifelse(bids$num_bids_received == 1,1,0)
bids$indic_2p_bids <- ifelse(bids$num_bids_received > 1,1,0)
bids$urban_indicator <- ifelse(bids$locale == 'Urban', TRUE, FALSE)
bids$suburban_indicator <- ifelse(bids$locale == 'Suburban', TRUE, FALSE)
bids$town_indicator <- ifelse(bids$locale == 'Town', TRUE, FALSE)
bids$rural_indicator <- ifelse(bids$locale == 'Rural', TRUE, FALSE)

##fiber prepping
bids_fiber <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, fiber_target_status)
bids_fiber <- filter(bids_fiber, bids_fiber$fiber_target_status == 'Target' | bids_fiber$fiber_target_status == 'Not Target')
bids_fiber_target <- filter(bids_fiber, bids_fiber$fiber_target_status == 'Target')
bids_fiber_not_target <- filter(bids_fiber, bids_fiber$fiber_target_status == 'Not Target')
bids_fiber_summ <- group_by(bids_fiber, fiber_target_status)
bids_fiber_summ <- summarise(bids_fiber_summ,
                             count_0_bids = sum(indic_0_bids),
                             count_1_bid = sum(indic_1_bids),
                             count_2p_bids = sum(indic_2p_bids),
                             pct_0_bids = sum(indic_0_bids)/n(),
                             pct_1_bid = sum(indic_1_bids)/n(),
                             pct_2p_bids = sum(indic_2p_bids)/n(),
                             pctile_25 = quantile(num_bids_received, probs=0.25),
                             pctile_50 = quantile(num_bids_received, probs=0.5),
                             pctile_75 = quantile(num_bids_received, probs=0.75),
                             avg = mean(num_bids_received))
##locale prepping
bids_urban <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, urban_indicator)
bids_urban_summ <- group_by(bids_urban, urban_indicator)
bids_urban_summ <- summarise(bids_urban_summ,
                              count_0_bids = sum(indic_0_bids),
                              count_1_bid = sum(indic_1_bids),
                              count_2p_bids = sum(indic_2p_bids),
                              pct_0_bids = sum(indic_0_bids)/n(),
                              pct_1_bid = sum(indic_1_bids)/n(),
                              pct_2p_bids = sum(indic_2p_bids)/n(),
                              pctile_25 = quantile(num_bids_received, probs=0.25),
                              pctile_50 = quantile(num_bids_received, probs=0.5),
                              pctile_75 = quantile(num_bids_received, probs=0.75),
                              avg = mean(num_bids_received))

bids_suburban <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, suburban_indicator)
bids_suburban_summ <- group_by(bids_suburban, suburban_indicator)
bids_suburban_summ <- summarise(bids_suburban_summ,
                                count_0_bids = sum(indic_0_bids),
                                count_1_bid = sum(indic_1_bids),
                                count_2p_bids = sum(indic_2p_bids),
                                pct_0_bids = sum(indic_0_bids)/n(),
                                pct_1_bid = sum(indic_1_bids)/n(),
                                pct_2p_bids = sum(indic_2p_bids)/n(),
                                pctile_25 = quantile(num_bids_received, probs=0.25),
                                pctile_50 = quantile(num_bids_received, probs=0.5),
                                pctile_75 = quantile(num_bids_received, probs=0.75),
                                avg = mean(num_bids_received))

bids_town <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, town_indicator)
bids_town_summ <- group_by(bids_town, town_indicator)
bids_town_summ <- summarise(bids_town_summ,
                            count_0_bids = sum(indic_0_bids),
                            count_1_bid = sum(indic_1_bids),
                            count_2p_bids = sum(indic_2p_bids),
                            pct_0_bids = sum(indic_0_bids)/n(),
                            pct_1_bid = sum(indic_1_bids)/n(),
                            pct_2p_bids = sum(indic_2p_bids)/n(),
                            pctile_25 = quantile(num_bids_received, probs=0.25),
                            pctile_50 = quantile(num_bids_received, probs=0.5),
                            pctile_75 = quantile(num_bids_received, probs=0.75),
                            avg = mean(num_bids_received))

bids_rural <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, rural_indicator)
bids_rural_summ <- group_by(bids_rural, rural_indicator)
bids_rural_summ <- summarise(bids_rural_summ,
                             count_0_bids = sum(indic_0_bids),
                             count_1_bid = sum(indic_1_bids),
                             count_2p_bids = sum(indic_2p_bids),
                             pct_0_bids = sum(indic_0_bids)/n(),
                             pct_1_bid = sum(indic_1_bids)/n(),
                             pct_2p_bids = sum(indic_2p_bids)/n(),
                             pctile_25 = quantile(num_bids_received, probs=0.25),
                             pctile_50 = quantile(num_bids_received, probs=0.5),
                             pctile_75 = quantile(num_bids_received, probs=0.75),
                             avg = mean(num_bids_received))
##bw goal meeting prepping 
bids_bw_goal <- filter(bids, bids$exclude_from_ia_analysis == FALSE)
bids_bw_goal <- bids_bw_goal %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, meeting_2014_goal_no_oversub)
bids_bw_goal_true <- filter(bids_bw_goal, bids_bw_goal$meeting_2014_goal_no_oversub == TRUE)
bids_bw_goal_false <- filter(bids_bw_goal, bids_bw_goal$meeting_2014_goal_no_oversub == FALSE)
bids_bw_goal_summ <- group_by(bids_bw_goal, meeting_2014_goal_no_oversub)
bids_bw_goal_summ <- summarise(bids_bw_goal_summ,
                               count_0_bids = sum(indic_0_bids),
                               count_1_bid = sum(indic_1_bids),
                               count_2p_bids = sum(indic_2p_bids),
                               pct_0_bids = sum(indic_0_bids)/n(),
                               pct_1_bid = sum(indic_1_bids)/n(),
                               pct_2p_bids = sum(indic_2p_bids)/n(),
                               pctile_25 = quantile(num_bids_received, probs=0.25),
                               pctile_50 = quantile(num_bids_received, probs=0.5),
                               pctile_75 = quantile(num_bids_received, probs=0.75),
                               avg = mean(num_bids_received))
##afford goal prepping 
bids_afford_goal <- filter(bids, bids$exclude_from_ia_cost_analysis == FALSE)
bids_afford_goal <- bids_afford_goal %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, meeting_knapsack_affordability_target)
bids_afford_goal_true <- filter(bids_afford_goal, bids_afford_goal$meeting_knapsack_affordability_target == TRUE)
bids_afford_goal_false <- filter(bids_afford_goal, bids_afford_goal$meeting_knapsack_affordability_target == FALSE)
bids_afford_goal_summ <- group_by(bids_afford_goal, meeting_knapsack_affordability_target)
bids_afford_goal_summ <- summarise(bids_afford_goal_summ,
                                   count_0_bids = sum(indic_0_bids),
                                   count_1_bid = sum(indic_1_bids),
                                   count_2p_bids = sum(indic_2p_bids),
                                   pct_0_bids = sum(indic_0_bids)/n(),
                                   pct_1_bid = sum(indic_1_bids)/n(),
                                   pct_2p_bids = sum(indic_2p_bids)/n(),
                                   pctile_25 = quantile(num_bids_received, probs=0.25),
                                   pctile_50 = quantile(num_bids_received, probs=0.5),
                                   pctile_75 = quantile(num_bids_received, probs=0.75),
                                   avg = mean(num_bids_received))
##purpose prepping 
bids_purpose <- filter(bids, bids$exclude_from_ia_analysis == FALSE)
bids_purpose <- bids_purpose %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids,
                                          internet_indicator, wan_indicator, upstream_indicator, backbone_indicator, isp_indicator)
bids_purpose_internet_summ <- group_by(bids_purpose, internet_indicator)
bids_purpose_internet_summ <- summarise(bids_purpose_internet_summ,
                                        count_0_bids = sum(indic_0_bids),
                                        count_1_bid = sum(indic_1_bids),
                                        count_2p_bids = sum(indic_2p_bids),
                                        pct_0_bids = sum(indic_0_bids)/n(),
                                        pct_1_bid = sum(indic_1_bids)/n(),
                                        pct_2p_bids = sum(indic_2p_bids)/n(),
                                        pctile_25 = quantile(num_bids_received, probs=0.25),
                                        pctile_50 = quantile(num_bids_received, probs=0.5),
                                        pctile_75 = quantile(num_bids_received, probs=0.75),
                                        avg = mean(num_bids_received))
bids_purpose_upstream_summ <- group_by(bids_purpose, upstream_indicator)
bids_purpose_upstream_summ <- summarise(bids_purpose_upstream_summ,
                                        count_0_bids = sum(indic_0_bids),
                                        count_1_bid = sum(indic_1_bids),
                                        count_2p_bids = sum(indic_2p_bids),
                                        pct_0_bids = sum(indic_0_bids)/n(),
                                        pct_1_bid = sum(indic_1_bids)/n(),
                                        pct_2p_bids = sum(indic_2p_bids)/n(),
                                        pctile_25 = quantile(num_bids_received, probs=0.25),
                                        pctile_50 = quantile(num_bids_received, probs=0.5),
                                        pctile_75 = quantile(num_bids_received, probs=0.75),
                                        avg = mean(num_bids_received))
bids_purpose_backbone_summ <- group_by(bids_purpose, backbone_indicator)
bids_purpose_backbone_summ <- summarise(bids_purpose_backbone_summ,
                                        count_0_bids = sum(indic_0_bids),
                                        count_1_bid = sum(indic_1_bids),
                                        count_2p_bids = sum(indic_2p_bids),
                                        pct_0_bids = sum(indic_0_bids)/n(),
                                        pct_1_bid = sum(indic_1_bids)/n(),
                                        pct_2p_bids = sum(indic_2p_bids)/n(),
                                        pctile_25 = quantile(num_bids_received, probs=0.25),
                                        pctile_50 = quantile(num_bids_received, probs=0.5),
                                        pctile_75 = quantile(num_bids_received, probs=0.75),
                                        avg = mean(num_bids_received))
bids_purpose_isp_summ <- group_by(bids_purpose, isp_indicator)
bids_purpose_isp_summ <- summarise(bids_purpose_isp_summ,
                                   count_0_bids = sum(indic_0_bids),
                                   count_1_bid = sum(indic_1_bids),
                                   count_2p_bids = sum(indic_2p_bids),
                                   pct_0_bids = sum(indic_0_bids)/n(),
                                   pct_1_bid = sum(indic_1_bids)/n(),
                                   pct_2p_bids = sum(indic_2p_bids)/n(),
                                   pctile_25 = quantile(num_bids_received, probs=0.25),
                                   pctile_50 = quantile(num_bids_received, probs=0.5),
                                   pctile_75 = quantile(num_bids_received, probs=0.75),
                                   avg = mean(num_bids_received))
bids_purpose_wan_summ <- group_by(bids_purpose, wan_indicator)
bids_purpose_wan_summ <- summarise(bids_purpose_wan_summ,
                                   count_0_bids = sum(indic_0_bids),
                                   count_1_bid = sum(indic_1_bids),
                                   count_2p_bids = sum(indic_2p_bids),
                                   pct_0_bids = sum(indic_0_bids)/n(),
                                   pct_1_bid = sum(indic_1_bids)/n(),
                                   pct_2p_bids = sum(indic_2p_bids)/n(),
                                   pctile_25 = quantile(num_bids_received, probs=0.25),
                                   pctile_50 = quantile(num_bids_received, probs=0.5),
                                   pctile_75 = quantile(num_bids_received, probs=0.75),
                                   avg = mean(num_bids_received))
##connect prepping 
bids_connect <- filter(bids, bids$exclude_from_ia_analysis == FALSE)
bids_connect <- bids_connect %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids,
                                          fiber_indicator, copper_indicator, cable_indicator, fixed_wireless_indicator)
bids_connect_fiber_summ <- group_by(bids_connect, fiber_indicator)
bids_connect_fiber_summ <- summarise(bids_connect_fiber_summ,
                                     count_0_bids = sum(indic_0_bids),
                                     count_1_bid = sum(indic_1_bids),
                                     count_2p_bids = sum(indic_2p_bids),
                                     pct_0_bids = sum(indic_0_bids)/n(),
                                     pct_1_bid = sum(indic_1_bids)/n(),
                                     pct_2p_bids = sum(indic_2p_bids)/n(),
                                     pctile_25 = quantile(num_bids_received, probs=0.25),
                                     pctile_50 = quantile(num_bids_received, probs=0.5),
                                     pctile_75 = quantile(num_bids_received, probs=0.75),
                                     avg = mean(num_bids_received))
bids_connect_cable_summ <- group_by(bids_connect, cable_indicator)
bids_connect_cable_summ <- summarise(bids_connect_cable_summ,
                                     count_0_bids = sum(indic_0_bids),
                                     count_1_bid = sum(indic_1_bids),
                                     count_2p_bids = sum(indic_2p_bids),
                                     pct_0_bids = sum(indic_0_bids)/n(),
                                     pct_1_bid = sum(indic_1_bids)/n(),
                                     pct_2p_bids = sum(indic_2p_bids)/n(),
                                     pctile_25 = quantile(num_bids_received, probs=0.25),
                                     pctile_50 = quantile(num_bids_received, probs=0.5),
                                     pctile_75 = quantile(num_bids_received, probs=0.75),
                                     avg = mean(num_bids_received))
bids_connect_fixedwireless_summ <- group_by(bids_connect, fixed_wireless_indicator)
bids_connect_fixedwireless_summ <- summarise(bids_connect_fixedwireless_summ,
                                             count_0_bids = sum(indic_0_bids),
                                             count_1_bid = sum(indic_1_bids),
                                             count_2p_bids = sum(indic_2p_bids),
                                             pct_0_bids = sum(indic_0_bids)/n(),
                                             pct_1_bid = sum(indic_1_bids)/n(),
                                             pct_2p_bids = sum(indic_2p_bids)/n(),
                                             pctile_25 = quantile(num_bids_received, probs=0.25),
                                             pctile_50 = quantile(num_bids_received, probs=0.5),
                                             pctile_75 = quantile(num_bids_received, probs=0.75),
                                             avg = mean(num_bids_received))
bids_connect_copper_summ <- group_by(bids_connect, copper_indicator)
bids_connect_copper_summ <- summarise(bids_connect_copper_summ,
                                      count_0_bids = sum(indic_0_bids),
                                      count_1_bid = sum(indic_1_bids),
                                      count_2p_bids = sum(indic_2p_bids),
                                      pct_0_bids = sum(indic_0_bids)/n(),
                                      pct_1_bid = sum(indic_1_bids)/n(),
                                      pct_2p_bids = sum(indic_2p_bids)/n(),
                                      pctile_25 = quantile(num_bids_received, probs=0.25),
                                      pctile_50 = quantile(num_bids_received, probs=0.5),
                                      pctile_75 = quantile(num_bids_received, probs=0.75),
                                      avg = mean(num_bids_received))

##creating multiples
bids_fiber_summ$category <- 'target'
bids_urban_summ$category <- 'urban'
bids_suburban_summ$category <- 'suburban'
bids_town_summ$category <- 'town'
bids_rural_summ$category <- 'rural'
bids_bw_goal_summ$category <- 'bw goal'
bids_afford_goal_summ$category <- 'afford goal'
bids_purpose_internet_summ$category <- 'internet'
bids_purpose_upstream_summ$category <- 'upstream'
bids_purpose_backbone_summ$category <- 'backbone'
bids_purpose_isp_summ$category <- 'isp'
bids_purpose_wan_summ$category <- 'wan'
bids_connect_fiber_summ$category <- 'fiber'
bids_connect_cable_summ$category <- 'cable'
bids_connect_fixedwireless_summ$category <- 'fixed wireless'
bids_connect_copper_summ$category <- 'copper'

bids_fiber_summ$value <- bids_fiber_summ$fiber_target_status
bids_urban_summ$value <- bids_urban_summ$urban_indicator
bids_suburban_summ$value <- bids_suburban_summ$suburban_indicator
bids_town_summ$value <- bids_town_summ$town_indicator
bids_rural_summ$value <- bids_rural_summ$rural_indicator
bids_bw_goal_summ$value <- bids_bw_goal_summ$meeting_2014_goal_no_oversub
bids_afford_goal_summ$value <- bids_afford_goal_summ$meeting_knapsack_affordability_target
bids_purpose_internet_summ$value <- bids_purpose_internet_summ$internet_indicator
bids_purpose_upstream_summ$value <- bids_purpose_upstream_summ$upstream_indicator
bids_purpose_backbone_summ$value <- bids_purpose_backbone_summ$backbone_indicator
bids_purpose_isp_summ$value <- bids_purpose_isp_summ$isp_indicator
bids_purpose_wan_summ$value <- bids_purpose_wan_summ$wan_indicator
bids_connect_fiber_summ$value <- bids_connect_fiber_summ$fiber_indicator
bids_connect_cable_summ$value <- bids_connect_cable_summ$cable_indicator
bids_connect_fixedwireless_summ$value <- bids_connect_fixedwireless_summ$fixed_wireless_indicator
bids_connect_copper_summ$value <- bids_connect_copper_summ$copper_indicator

target <- merge(filter(select(bids_fiber_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == 'Target'),
                filter(select(bids_fiber_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == 'Not Target'),
                by='category')
urban <- merge(filter(select(bids_urban_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                filter(select(bids_urban_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                by='category')
suburban <- merge(filter(select(bids_suburban_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
               filter(select(bids_suburban_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
               by='category')
town <- merge(filter(select(bids_town_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
               filter(select(bids_town_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
               by='category')
rural <- merge(filter(select(bids_rural_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
               filter(select(bids_rural_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
               by='category')
bw_goal <- merge(filter(select(bids_bw_goal_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                 filter(select(bids_bw_goal_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                 by='category')
afford_goal <- merge(filter(select(bids_afford_goal_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                     filter(select(bids_afford_goal_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                     by='category')
internet <- merge(filter(select(bids_purpose_internet_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                  filter(select(bids_purpose_internet_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                  by='category')
upstream <- merge(filter(select(bids_purpose_upstream_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                  filter(select(bids_purpose_upstream_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                  by='category')
backbone <- merge(filter(select(bids_purpose_backbone_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                  filter(select(bids_purpose_backbone_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                  by='category')
isp <- merge(filter(select(bids_purpose_isp_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
             filter(select(bids_purpose_isp_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
             by='category')
wan <- merge(filter(select(bids_purpose_wan_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
             filter(select(bids_purpose_wan_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
             by='category')
fiber <- merge(filter(select(bids_connect_fiber_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
               filter(select(bids_connect_fiber_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
               by='category')
cable <- merge(filter(select(bids_connect_cable_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
               filter(select(bids_connect_cable_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
               by='category')
fixed_wireless <- merge(filter(select(bids_connect_fixedwireless_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                        filter(select(bids_connect_fixedwireless_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                        by='category')
copper <- merge(filter(select(bids_connect_copper_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == TRUE),
                filter(select(bids_connect_copper_summ, category, value, pct_0_bids, pct_1_bid, pct_2p_bids), value == FALSE),
                by='category')

multiples1 <- union(target, wan)
multiples2 <- union(bw_goal, afford_goal)
multiples3 <- union(internet, upstream)
multiples4 <- union(isp, backbone)
multiples5 <- union(copper, fiber)
multiples6 <- union(fixed_wireless, cable)
multiples7 <- union(urban, suburban)
multiples8 <- union(town, rural)

multiples12 <- union(multiples1,multiples2)
multiples34 <- union(multiples3,multiples4)
multiples56 <- union(multiples5,multiples6)
mutliples78 <- union(multiples7,multiples8)
multiples1234 <- union(multiples12, multiples34)
multiples5678 <- union(multiples56,mutliples78)
multiples <- union(multiples1234,multiples5678)

multiples <- mutate(multiples,
                    pct_0_1_bids.x = pct_0_bids.x + pct_1_bid.x,
                    pct_0_1_bids.y = pct_0_bids.y + pct_1_bid.y,
                    multiple_0.v1 = pct_0_bids.x/pct_0_bids.y,
                    multiple_0.v2 = pct_0_bids.y/pct_0_bids.x,
                    multiple_1.v1 = pct_1_bid.x/pct_1_bid.y,
                    multiple_1.v2 = pct_1_bid.y/pct_1_bid.x,
                    multiple_0_1.v1 = pct_0_1_bids.x/pct_0_1_bids.y,
                    multiple_0_1.v2 = pct_0_1_bids.y/pct_0_1_bids.x,
                    multiple_2p.v1 = pct_2p_bids.x/pct_2p_bids.y,
                    multiple_2p.v2 = pct_2p_bids.y/pct_2p_bids.x)
write.csv(multiples, file = "C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/interim/multiples.csv")

##chart theme
theme_esh <- function(){
  theme(
    text = element_text(color="#666666", size=18),
    plot.title = element_text(lineheight=.8, size=12,color="#666666"),
    axis.title.x = element_text(color="#666666", size=15),
    panel.grid.major = element_line(color = "light grey"),
    panel.grid.major.x = element_blank(),
    panel.background = element_rect(fill = "white")
  )
}

##fiber charts
fiber_target_0_bids <- ggplot(data=bids_fiber_summ, aes(x=fiber_target_status, y=pct_0_bids)) +
  geom_text(data=bids_fiber_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1) +
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .15, label = paste0(round(bids_fiber_summ$pct_0_bids[2]/bids_fiber_summ$pct_0_bids[1],1), "x"),
           colour = "red", size = 8)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh()
##urban charts
urban_0_bids <- ggplot(data=bids_urban_summ, aes(x=urban_indicator, y=pct_0_bids)) +
  geom_text(data=bids_urban_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1) +
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Urban", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .15, label = paste0(round(bids_urban_summ$pct_0_bids[1]/bids_urban_summ$pct_0_bids[2],1), "x"),
           colour = "red", size = 8)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh()
urban_1_bid <- ggplot(data=bids_urban_summ, aes(x=urban_indicator, y=pct_1_bid)) +
  geom_text(data=bids_urban_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1) +
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Urban", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4, label = paste0(round(bids_urban_summ$pct_1_bid[1]/bids_urban_summ$pct_1_bid[2],1), "x"),
           colour = "red", size = 8)+
  ggtitle("Frequency of 1 Bid") +
  theme_esh()
##purpose charts
internet_0_bids <- ggplot(data=bids_purpose_internet_summ, aes(x=internet_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_internet_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Internet", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1,  label=paste0(round(bids_purpose_internet_summ$pct_0_bids[2]/bids_purpose_internet_summ$pct_0_bids[1],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
upstream_0_bids <- ggplot(data=bids_purpose_upstream_summ, aes(x=upstream_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_upstream_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Upstream", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1,  label=paste0(round(bids_purpose_upstream_summ$pct_0_bids[1]/bids_purpose_upstream_summ$pct_0_bids[2],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids")  + 
  theme_esh()
wan_0_bids <- ggplot(data=bids_purpose_wan_summ, aes(x=wan_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_wan_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has WAN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1,  label=paste0(round(bids_purpose_wan_summ$pct_0_bids[1]/bids_purpose_wan_summ$pct_0_bids[2],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
backbone_0_bids <- ggplot(data=bids_purpose_backbone_summ, aes(x=backbone_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_backbone_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Backbone", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1,  label=paste0(round(bids_purpose_backbone_summ$pct_0_bids[1]/bids_purpose_backbone_summ$pct_0_bids[2],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
backbone_1_bid <- ggplot(data=bids_purpose_backbone_summ, aes(x=backbone_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_backbone_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Backbone", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4,  label=paste0(round(bids_purpose_backbone_summ$pct_1_bid[1]/bids_purpose_backbone_summ$pct_1_bid[2],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 1 Bid") + 
  theme_esh()
##connect charts
cable_0_bids <- ggplot(data=bids_connect_cable_summ, aes(x=cable_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_cable_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Cable in FRN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .2,  label=paste0(round(bids_connect_cable_summ$pct_0_bids[2]/bids_connect_cable_summ$pct_0_bids[1],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
copper_0_bids <- ggplot(data=bids_connect_copper_summ, aes(x=copper_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_copper_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .6))+
  labs(x="Copper in FRN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .2,  label=paste0(round(bids_connect_copper_summ$pct_0_bids[2]/bids_connect_copper_summ$pct_0_bids[1],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh() 
copper_1_bid <- ggplot(data=bids_connect_copper_summ, aes(x=copper_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_copper_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .6))+
  labs(x="Copper in FRN", y="") +
  geom_hline(yintercept=0, size=0.44, color="black")+
  annotate("text", x = 1.5, y = .55,  label=paste0(round(bids_connect_copper_summ$pct_1_bid[2]/bids_connect_copper_summ$pct_1_bid[1],1), "x"),
           colour = "red", size = 6)+
  ggtitle("Frequency of 1 Bid") + 
  theme_esh()

##charts
require(gridExtra)
png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/targetplot.png",
    width=1000,
    height=796,
    res=120)
fiber_target_0_bids
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/urbanplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(urban_0_bids, urban_1_bid, ncol=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/internetplot.png",
    width=1000,
    height=796,
    res=120)
internet_0_bids
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/upstreamplot.png",
    width=1000,
    height=796,
    res=120)
upstream_0_bids
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/wanplot.png",
    width=1000,
    height=796,
    res=120)
wan_0_bids
dev.off()


png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/backboneplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(backbone_0_bids, backbone_1_bid, ncol=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/copperplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(copper_0_bids, copper_1_bid, ncol=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/images/cableplot.png",
    width=1000,
    height=796,
    res=120)
cable_0_bids
dev.off()

##agg cost/mbps prepping
bids_ia_cost <- filter(bids, bids$exclude_from_ia_cost_analysis == FALSE)
bids_ia_cost <- filter(bids_ia_cost, 
                       bids_ia_cost$internet_indicator == TRUE |
                         bids_ia_cost$upstream_indicator == TRUE |
                         bids_ia_cost$isp_indicator == TRUE |
                         bids_ia_cost$backbone_indicator == TRUE)
bids_ia_cost$num_bids_category <- ifelse(bids_ia_cost$num_bids_received > 1, 2, bids_ia_cost$num_bids_received)
bids_ia_cost <- bids_ia_cost %>% distinct(frn, num_bids_category, ia_monthly_cost_per_mbps)
bids_ia_cost_summ <- group_by(bids_ia_cost, num_bids_category)
bids_ia_cost_summ <- summarise(bids_ia_cost_summ,
                             pctile_25 = quantile(ia_monthly_cost_per_mbps, probs=0.25),
                             pctile_50 = quantile(ia_monthly_cost_per_mbps, probs=0.5),
                             pctile_75 = quantile(ia_monthly_cost_per_mbps, probs=0.75))
View(bids_ia_cost_summ)

##agg bw/student prepping
bids_ia_bw <- filter(bids, bids$exclude_from_ia_analysis == FALSE)
bids_ia_bw <- filter(bids_ia_bw, 
                     bids_ia_bw$internet_indicator == TRUE |
                       bids_ia_bw$upstream_indicator == TRUE |
                       bids_ia_bw$isp_indicator == TRUE |
                       bids_ia_bw$backbone_indicator == TRUE)
bids_ia_bw$num_bids_category <- ifelse(bids_ia_bw$num_bids_received > 1, 2, bids_ia_bw$num_bids_received)
bids_ia_bw <- bids_ia_bw %>% distinct(frn, num_bids_category, ia_bandwidth_per_student_kbps)
bids_ia_bw_summ <- group_by(bids_ia_bw, num_bids_category)
bids_ia_bw_summ <- summarise(bids_ia_bw_summ,
                               pctile_25 = quantile(ia_bandwidth_per_student_kbps, probs=0.25),
                               pctile_50 = quantile(ia_bandwidth_per_student_kbps, probs=0.5),
                               pctile_75 = quantile(ia_bandwidth_per_student_kbps, probs=0.75))
View(bids_ia_bw_summ)
