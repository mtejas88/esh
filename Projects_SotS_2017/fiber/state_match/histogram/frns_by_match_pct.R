## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/state_match/histogram/")

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
frns <- read.csv("data/frns.csv")
frns$match_pct = frns$match_amount/frns$total_pre_discount_charges 

##histogram of FRNs
p.pct <- ggplot(frns, aes(match_pct))
p.pct + geom_histogram(binwidth=.05, fill="#009296")+
  ylab("Number FRNs")+
  xlab("% match amount")+
  ggtitle("FRNs with match by match %")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))+
  stat_bin(aes(y=(..count..)/sum(..count..), 
               label=paste(round((..count..)/sum(..count..),2)*100,'%')), 
           geom="text", size=4, binwidth = .05, vjust=-1, color = 'black')


##histogram of $ match
p.pct2 <- ggplot(frns, aes(match_pct, weight = match_amount))
p.pct2 + geom_histogram(binwidth=.05, fill="#009296")+
  ylab("$ Match")+
  xlab("% match amount")+
  ggtitle("FRNs with match by match %")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))
