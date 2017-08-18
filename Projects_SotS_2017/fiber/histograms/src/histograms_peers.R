## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/histograms/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)

##import and filter
districts_not_meeting_goals <- read.csv("data/districts_not_meeting_goals.csv")
districts_with_state_peers <- filter(districts_not_meeting_goals, diagnosis == 'meet the prices available in your state') 


##histogram of prices
p.prices <- ggplot(districts_with_state_peers, aes(num_prices_to_meet_goals_with_same_budget))
p.prices + geom_histogram(binwidth=2, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of price examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),100,150))+ 
  geom_vline(xintercept = median(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
             )+ 
  annotate("text", x = 60, y = 25, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but \ncould with peer pricing")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))


##histogram of districts
p.districts <- ggplot(districts_with_state_peers, aes(num_districts_w_prices_to_meet_goals_with_same_budget))
p.districts + geom_histogram(binwidth=2.5, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of districts with examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),200,300))+ 
  geom_vline(xintercept = median(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
  )+ 
  annotate("text", x = 120, y = 15, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but \ncould with peer pricing")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))

##histogram of contract end time
p.contract <- ggplot(districts_not_meeting_goals, aes(contract_end_time))
p.contract + geom_histogram(binwidth=1, fill="#009296")+
  ylab("Number of districts")+
  xlab("Years until contract end of soonest expiring internet contract")+
  scale_x_continuous(breaks = c(1,2,3,4,5,6,7))+ 
  geom_text(aes( label = scales::percent(..prop..),
                 y= ..prop.. ), stat= "count", vjust = -.5)+
  ggtitle("Districts not meeting goals")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))
