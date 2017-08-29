## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/connectivity/contract_end_dates")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2", "reshape2", "plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)


##import and filter
districts_not_meeting_goals <- read.csv("data/districts_not_meeting.csv")

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
