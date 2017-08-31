## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/funding_the_gap_2017")

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
unscalable_breakdown <- read.csv("data/interim/unscalable_breakdown.csv")

##histogram of contract end time
p.contract <- ggplot(unscalable_breakdown, aes(x=diagnosis))
p.contract + geom_bar(aes(weight=sum), fill="#009296")+
  ylab("Number of unscalable campuses")+
  xlab("")+
  geom_text(aes(label=round(sum,0), y=round(sum,0)), position=position_dodge(width=0.9), vjust=-0.25)+
  ggtitle("Cost to build fiber")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))

