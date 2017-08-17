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

unname(quantile(districts$num_prices_to_meet_goals_with_same_budget, c(.25,.5,.75)))

##imports
districts <- read.csv("data/districts_with_state_peers.csv")

##histogram of prices
p.prices <- ggplot(districts, aes(num_prices_to_meet_goals_with_same_budget))
p.prices + geom_histogram(binwidth=2, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of price examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts$num_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),100,150))+ 
  geom_vline(xintercept = median(districts$num_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts$num_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
             )+ 
  annotate("text", x = 60, y = 25, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but could with peer pricing")


##histogram of prices
p.districts <- ggplot(districts, aes(num_districts_w_prices_to_meet_goals_with_same_budget))
p.districts + geom_histogram(binwidth=2.5, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of districts with examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),200,300))+ 
  geom_vline(xintercept = median(districts$num_districts_w_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
  )+ 
  annotate("text", x = 120, y = 25, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but could with peer pricing")
