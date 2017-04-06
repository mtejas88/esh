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
bids$num_bids_category <- ifelse(bids$num_bids_received > 1,2,bids$num_bids_received)
bids$locale_cat <- ifelse(bids$locale == 'Rural' | bids$locale == 'Town', 'Rural', 'Urban')

##fiber prepping
bids_fiber <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, fiber_target_status, num_bids_category)
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
bids_fiber_cat_summ <- group_by(bids_fiber, fiber_target_status, num_bids_category)
bids_fiber_cat_summ <- summarise(bids_fiber_cat_summ,
                             count = n())

##locale prepping
bids_locale <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, locale_cat, num_bids_category)
bids_locale_rural <- filter(bids_locale, bids_locale$locale_cat == 'Rural')
bids_locale_urban <- filter(bids_locale, bids_locale$locale_cat == 'Urban')
bids_locale_summ <- group_by(bids_locale, locale_cat)
bids_locale_summ <- summarise(bids_locale_summ,
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
bids_locale_cat_summ <- group_by(bids_locale, locale_cat, num_bids_category)
bids_locale_cat_summ <- summarise(bids_locale_cat_summ,
                                  count = n())



##bw goal meeting prepping 
bids_bw_goal <- filter(bids, bids$exclude_from_ia_analysis == 'false')
bids_bw_goal <- bids_bw_goal %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, meeting_2014_goal_no_oversub, num_bids_category)
bids_bw_goal_true <- filter(bids_bw_goal, bids_bw_goal$meeting_2014_goal_no_oversub == 'true')
bids_bw_goal_false <- filter(bids_bw_goal, bids_bw_goal$meeting_2014_goal_no_oversub == 'false')
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
bids_bw_goal_cat_summ <- group_by(bids_bw_goal, meeting_2014_goal_no_oversub, num_bids_category)
bids_bw_goal_cat_summ <- summarise(bids_bw_goal_cat_summ,
                                   count = n())

##afford goal prepping 
bids_afford_goal <- filter(bids, bids$exclude_from_ia_cost_analysis == 'false')
bids_afford_goal <- bids_afford_goal %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, meeting_knapsack_affordability_target, num_bids_category)
bids_afford_goal_true <- filter(bids_afford_goal, bids_afford_goal$meeting_knapsack_affordability_target == 'true')
bids_afford_goal_false <- filter(bids_afford_goal, bids_afford_goal$meeting_knapsack_affordability_target == 'false')
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
bids_afford_goal_cat_summ <- group_by(bids_afford_goal, meeting_knapsack_affordability_target, num_bids_category)
bids_afford_goal_cat_summ <- summarise(bids_afford_goal_cat_summ,
                                       count = n())

##purpose prepping 
bids_purpose <- filter(bids, bids$exclude_from_ia_analysis == 'false')
bids_purpose <- bids_purpose %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, num_bids_category,
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
bids_connect <- filter(bids, bids$exclude_from_ia_analysis == 'false')
bids_connect <- bids_connect %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, num_bids_category,
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
  annotate("text", x = 1.5, y = .15, label = paste0(round(bids_fiber_summ$pct_0_bids[2]/bids_fiber_summ$pct_0_bids[1],0), "x"),
           colour = "red", size = 8)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh() 

fiber_target_1_bid <- ggplot(data=bids_fiber_summ, aes(x=fiber_target_status, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_fiber_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4, label = "insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid")  +
  theme_esh() 
##locale charts
locale_0_bids <- ggplot(data=bids_locale_summ, aes(x=locale_cat, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_locale_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1, label = "insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh() 
locale_1_bid <- ggplot(data=bids_locale_summ, aes(x=locale_cat, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_locale_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .45, label = paste0(round(bids_locale_summ$pct_1_bid[1]/bids_locale_summ$pct_1_bid[2],1), "x"),
           colour = "red", size = 8)+
  ggtitle("Frequency of 1 Bid") +
  theme_esh()  
##bw goal meeting charts
bw_goal_0_bids <- ggplot(data=bids_bw_goal_summ, aes(x=meeting_2014_goal_no_oversub, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_bw_goal_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Meeting Bandwidth Goals", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1, label = "insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh()  
bw_goal_1_bid <- ggplot(data=bids_bw_goal_summ, aes(x=meeting_2014_goal_no_oversub, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_bw_goal_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Meeting Bandwidth Goals", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4, label = "insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") +
  theme_esh() 
##afford goal charts
afford_goal_0_bids <- ggplot(data=bids_afford_goal_summ, aes(x=meeting_knapsack_affordability_target, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_afford_goal_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Meeting Afford Goals", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .1, label = "insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 0 Bids") +
  theme_esh() 
afford_goal_1_bid <- ggplot(data=bids_afford_goal_summ, aes(x=meeting_knapsack_affordability_target, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_afford_goal_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Meeting Afford Goals", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4, label = "insignificant",
           colour = "#009296", size = 4)+
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
internet_1_bid <- ggplot(data=bids_purpose_internet_summ, aes(x=internet_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_internet_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Internet", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .45,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid")  + 
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
upstream_1_bid <- ggplot(data=bids_purpose_upstream_summ, aes(x=upstream_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_upstream_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has Upstream", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .45,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") + 
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
wan_1_bid <- ggplot(data=bids_purpose_wan_summ, aes(x=wan_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_wan_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has WAN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .45,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") + 
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
isp_0_bids <- ggplot(data=bids_purpose_isp_summ, aes(x=isp_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_isp_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has ISP", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .15,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
isp_1_bid <- ggplot(data=bids_purpose_isp_summ, aes(x=isp_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_purpose_isp_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="FRN has ISP", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .43,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") + 
  theme_esh()
##connect charts
fiber_0_bids <- ggplot(data=bids_connect_fiber_summ, aes(x=fiber_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_fiber_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Fiber in FRN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .15,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 0 Bids") + 
  theme_esh()
fiber_1_bid <- ggplot(data=bids_connect_fiber_summ, aes(x=fiber_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_fiber_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Fiber in FRN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .45,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") + 
  theme_esh()

paste0(round(bids_connect_cable_summ$pct_1_bid[2]/bids_connect_cable_summ$pct_1_bid[1],1), "x")
paste0(round(bids_connect_cable_summ$pct_0_bids[2]/bids_connect_cable_summ$pct_0_bids[1],1), "x")


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
cable_1_bid <- ggplot(data=bids_connect_cable_summ, aes(x=cable_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_cable_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
  labs(x="Cable in FRN", y="") +
  geom_hline(yintercept=0, size=0.4, color="black")+
  annotate("text", x = 1.5, y = .4,  label="insignificant",
           colour = "#009296", size = 4)+
  ggtitle("Frequency of 1 Bid") + 
  theme_esh()

##WIP!!!!
copper_0_bids <- ggplot(data=bids_connect_copper_summ, aes(x=copper_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_copper_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, 1))+
  labs(title="0 Bids", x="copper in FRN", y="Probability") +
  geom_hline(yintercept=0, size=0.4, color="black")
copper_1_bid <- ggplot(data=bids_connect_copper_summ, aes(x=copper_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_copper_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, 1))+
  labs(title="1 Bid", x="copper in FRN", y="Probability") +
  geom_hline(yintercept=0, size=0.4, color="black")
fixedwireless_0_bids <- ggplot(data=bids_connect_fixedwireless_summ, aes(x=fixed_wireless_indicator, y=pct_0_bids)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_fixedwireless_summ,aes(label=paste0(round(pct_0_bids*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, 1))+
  labs(title="0 Bids", x="fixedwireless in FRN", y="Probability") +
  geom_hline(yintercept=0, size=0.4, color="black")
fixedwireless_1_bid <- ggplot(data=bids_connect_fixedwireless_summ, aes(x=fixed_wireless_indicator, y=pct_1_bid)) + 
  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
  geom_text(data=bids_connect_fixedwireless_summ,aes(label=paste0(round(pct_1_bid*100,1),"%")),vjust=-1)+ 
  scale_y_continuous(labels = percent_format(), limits = c(0, 1))+
  labs(title="1 Bid", x="fixedwireless in FRN", y="Probability") +
  geom_hline(yintercept=0, size=0.4, color="black")

##charts
require(gridExtra)
png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/fiberplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(fiber_target_0_bids, fiber_target_1_bid, ncol=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/localeplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(locale_0_bids, locale_1_bid, ncol=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/goalplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(bw_goal_0_bids, bw_goal_1_bid, afford_goal_0_bids, afford_goal_1_bid, ncol=2, nrow=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/purposeplotsig.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(internet_0_bids, upstream_0_bids, wan_0_bids, backbone_0_bids, backbone_1_bid, ncol=3, nrow=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/purposeplotinsig.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(internet_1_bid, upstream_1_bid, wan_1_bid, isp_1_bid, isp_0_bids, ncol=3, nrow=2)
dev.off()

png(file="C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/special_construction/connectplot.png",
    width=1000,
    height=796,
    res=120)
grid.arrange(fiber_0_bids, cable_0_bids, fixedwireless_0_bids, copper_0_bids, 
             fiber_1_bid, cable_1_bid, fixedwireless_1_bid, copper_1_bid, ncol=4, nrow=2)
dev.off()
