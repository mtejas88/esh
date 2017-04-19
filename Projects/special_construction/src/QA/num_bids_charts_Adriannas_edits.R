## ===================================================
##
## ADRIANNA'S SUGGESTIONS FOR NUM_BIDS_CHARTS.R
##
## ===================================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects/special_construction/")

## NOTE: the code below will work on anyone's computer whether they have the packages or not.
## load packages (if not already in the environment)
packages.to.install <- c("lubridate", "ggplot2", "dplyr", "plotly", "ggmap", "RColorBrewer", "scales", "gridExtra")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(lubridate)
library(ggplot2)
library(dplyr)
library(plotly)
library(ggmap)
library(RColorBrewer)
library(scales)
library(gridExtra)

##**************************************************************************************************************************************************
## READ IN DATA

## bids data
## NOTE: I would suggest writing out the data to a raw sub-directory in data/ since the data is from our internal DB.
bids <- read.csv("data/raw/frns_with_district_info.csv", as.is=TRUE)

##**************************************************************************************************************************************************
## DATA MUNGING

##====================================
## STEP #1: CREATE INDICATORS
##====================================

## binary cleanliness indicator
bids$clean <- ifelse(bids$exclude_from_ia_analysis == FALSE, 1, 0)
bids$clean_cost <- ifelse(bids$exclude_from_ia_cost_analysis == FALSE, 1, 0)

## number of bids indicators
bids <- filter(bids, bids$num_bids_received < 26)
bids$indic_0_bids <- ifelse(bids$num_bids_received == 0, 1, 0)
bids$indic_1_bids <- ifelse(bids$num_bids_received == 1, 1, 0)
bids$indic_2p_bids <- ifelse(bids$num_bids_received > 1, 1, 0)

## locale indicators
## NOTE: I'd use actual TRUE/FALSE boolean values instead of strings
#bids$urban_indicator <- ifelse(bids$locale == 'Urban', TRUE, FALSE)
#bids$suburban_indicator <- ifelse(bids$locale == 'Suburban', TRUE, FALSE)
#bids$town_indicator <- ifelse(bids$locale == 'Town', TRUE, FALSE)
#bids$rural_indicator <- ifelse(bids$locale == 'Rural', TRUE, FALSE)
## EXTRA: another way to create the binary columns (especially if you have a ton to make)
locales <- unique(bids$locale)
for (i in 1:length(locales)){
  ## expression inside a () returns TRUE/FALSE boolean
  sub.locale <- (bids$locale == locales[i])
  ## assign the vector as a new column in the dataset (attach as the last column)
  bids[,ncol(bids) + 1] <- sub.locale
  ## name the last column using the name of the locale
  names(bids)[ncol(bids)] <- paste(tolower(locales[i]), "indicator", sep="_")
}

## fiber indicators
bids$fiber_target_indicator <- (bids$fiber_target_status == 'Target' | bids$fiber_target_status == 'Not Target')
bids$fiber_target_indicator <- ifelse(bids$fiber_target_status == 'Target' & bids$fiber_target_indicator == TRUE, TRUE,
                                      ifelse(bids$fiber_target_status == 'Not Target' & bids$fiber_target_indicator == TRUE, FALSE, NA))

## list indicators that require cleanliness
bids$meeting_knapsack_affordability_indicator <- bids$meeting_knapsack_affordability_target
bids$meeting_2014_goal_no_oversub_indicator <- bids$meeting_2014_goal_no_oversub
goal.indicators <- c("meeting_2014_goal_no_oversub_indicator", "meeting_knapsack_affordability_indicator")
purpose.indicators <- c("internet_indicator", "wan_indicator", "upstream_indicator", "backbone_indicator", "isp_indicator")
connect.indicators <- c("fiber_indicator", "copper_indicator", "cable_indicator", "fixed_wireless_indicator")
## combine indicators
all.indicators <- c(goal.indicators, purpose.indicators, connect.indicators)
for (i in 1:length(all.indicators)){
  bids[,c(all.indicators[i])] <- ifelse(bids[,c(all.indicators[i])] == TRUE, 1, 0)
  ## combine with clean cost category if affordability
  if (all.indicators[i] == "meeting_knapsack_affordability_indicator"){
    bids[,c(all.indicators[i])] <- bids[,c(all.indicators[i])] * bids$clean_cost
  }
  ## otherwise combine with clean category
  bids[,c(all.indicators[i])] <- bids[,c(all.indicators[i])] * bids$clean
  ## turn back into boolean
  bids[,c(all.indicators[i])] <- (bids[,c(all.indicators[i])] == 1)
}

##====================================
## STEP #2: CREATE SUBSETS
##====================================

## define function to create datasets by indicator_selected
create_datasets <- function(bids, indicator_selected){
  bids$indicator <- bids[,names(bids) == paste(tolower(indicator_selected), "indicator", sep="_")]
  bids_sub <- bids %>% distinct(frn, num_bids_received, indic_0_bids, indic_1_bids, indic_2p_bids, indicator)
  bids_sub_summ <- group_by(bids_sub, indicator)
  bids_sub_summ <- summarise(bids_sub_summ,
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
  bids_sub_summ$category <- indicator_selected
  bids_sub_summ$values <- bids_sub_summ$indicator
  assign(paste("bids", tolower(indicator_selected), "summ", sep="_"), bids_sub_summ, envir=.GlobalEnv)
}

## combine all indicators
all.indicators <- c(locales, "fiber_target_indicator", goal.indicators, purpose.indicators, connect.indicators)
## fix names
all.indicators <- tolower(all.indicators)
all.indicators <- gsub("_indicator", "", all.indicators)

for (i in 1:length(all.indicators)){
  create_datasets(bids, all.indicators[i])
}

##**************************************************************************************************************************************************
## NOTE: I would say you could break out this section into another script
## since all of the above code is about data munging/prepping
## and thus should only have be done once since you already write out to data/interim.

## chart theme settings
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

## define function for all plots
require(gridExtra)
plot_bids <- function(dta){
  title <- gsub("_", " ", dta$category[1])
  plot.object <- ggplot(data=dta, aes(x=indicator, y=pct_0_bids)) +
                  geom_text(data=dta, aes(label=paste0(round(pct_0_bids*100,1),"%")), vjust=-1) +
                  geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
                  scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
                  labs(x=title, y="") +
                  geom_hline(yintercept=0, size=0.4, color="black")+
                  annotate("text", x = 1.5, y = .15, label = paste0(round(dta$pct_0_bids[2]/dta$pct_0_bids[1],1), "x"),
                  colour = "red", size = 8)+
                  ggtitle("Frequency of 0 Bids") +
                  theme_esh()
  ## write out plot
  png(file=paste("figures/", dta$category[1], ".png", sep=""), width=1000, height=796, res=120)
  print(plot.object)
  dev.off()

  if (title %in% c("urban", "backbone", "copper")){
    plot.object2 <- ggplot(data=dta, aes(x=indicator, y=pct_1_bid)) +
      geom_text(data=dta, aes(label=paste0(round(pct_1_bid*100,1),"%")), vjust=-1) +
      geom_bar(stat="identity", fill=c("#FDB913","#F09221"), alpha=0.75)+
      scale_y_continuous(labels = percent_format(), limits = c(0, .5))+
      labs(x="", y="") +
      geom_hline(yintercept=0, size=0.4, color="black")+
      annotate("text", x = 1.5, y = .4, label = paste0(round(dta$pct_1_bid[1]/dta$pct_1_bid[2],1), "x"),
               colour = "red", size = 8)+
      ggtitle("Frequency of 1 Bid") +
      theme_esh()

    png(file=paste("figures/", dta$category[1], "_compare_0_1_bids.png", sep=""), width=1000, height=796, res=120)
    grid.arrange(plot.object, plot.object2, ncol=2)
    dev.off()
  }
}

## collect datasets to plot for bids
plot_bids(bids_fiber_summ)
plot_bids(bids_urban_summ)
plot_bids(bids_internet_summ)
plot_bids(bids_upstream_summ)
plot_bids(bids_wan_summ)
plot_bids(bids_backbone_summ)
plot_bids(bids_cable_summ)
plot_bids(bids_copper_summ)


##agg cost/mbps prepping
bids_ia_cost <- filter(bids, bids$exclude_from_ia_cost_analysis == 'false')
bids_ia_cost <- filter(bids_ia_cost,
                       bids_ia_cost$internet_indicator == 'true' |
                         bids_ia_cost$upstream_indicator == 'true' |
                         bids_ia_cost$isp_indicator == 'true' |
                         bids_ia_cost$backbone_indicator == 'true')
bids_ia_cost$num_bids_category <- ifelse(bids_ia_cost$num_bids_received > 1, 2, bids_ia_cost$num_bids_received)
bids_ia_cost <- bids_ia_cost %>% distinct(frn, num_bids_category, ia_monthly_cost_per_mbps)
bids_ia_cost_summ <- group_by(bids_ia_cost, num_bids_category)
bids_ia_cost_summ <- summarise(bids_ia_cost_summ,
                               pctile_25 = quantile(ia_monthly_cost_per_mbps, probs=0.25),
                               pctile_50 = quantile(ia_monthly_cost_per_mbps, probs=0.5),
                               pctile_75 = quantile(ia_monthly_cost_per_mbps, probs=0.75))
View(bids_ia_cost_summ)

## agg bw/student prepping
bids_ia_bw <- filter(bids, bids$exclude_from_ia_analysis == 'false')
bids_ia_bw <- filter(bids_ia_bw,
                     bids_ia_bw$internet_indicator == 'true' |
                       bids_ia_bw$upstream_indicator == 'true' |
                       bids_ia_bw$isp_indicator == 'true' |
                       bids_ia_bw$backbone_indicator == 'true')
bids_ia_bw$num_bids_category <- ifelse(bids_ia_bw$num_bids_received > 1, 2, bids_ia_bw$num_bids_received)
bids_ia_bw <- bids_ia_bw %>% distinct(frn, num_bids_category, ia_bandwidth_per_student_kbps)
bids_ia_bw_summ <- group_by(bids_ia_bw, num_bids_category)
bids_ia_bw_summ <- summarise(bids_ia_bw_summ,
                             pctile_25 = quantile(ia_bandwidth_per_student_kbps, probs=0.25),
                             pctile_50 = quantile(ia_bandwidth_per_student_kbps, probs=0.5),
                             pctile_75 = quantile(ia_bandwidth_per_student_kbps, probs=0.75))
View(bids_ia_bw_summ)
