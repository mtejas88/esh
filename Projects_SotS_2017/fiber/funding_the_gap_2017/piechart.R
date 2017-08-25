## =========================================
##
## Create pie chart
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/funding_the_gap_2017")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2", "reshape2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)
library(reshape2)
blank_theme <- theme_minimal()+
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.border = element_blank(),
    panel.grid=element_blank(),
    axis.ticks = element_blank(),
    plot.title=element_text(size=14, face="bold")
  )

##import
state_costs <- read.csv("data/processed/state_metrics.csv")
funding_the_gap <- state_costs %>% summarise(state = sum(extrapolated_total_state_funding),
                                             erate = sum(extrapolated_total_erate_funding),
                                             district = sum(extrapolated_total_district_funding))


##reshape
funding_the_gap <- melt(funding_the_gap)

##bar chart for discounts -- evan
p.discounts.1 <- ggplot(funding_the_gap, aes(x="", y=value, fill=variable)) +
  geom_bar(stat="identity")+
  ylab("")+
  xlab("")+
  ggtitle("Funding the remaining \nnonfiber campuses")
p.discounts.1 + 
  coord_polar("y", start=0) +  
  scale_fill_brewer("Blues") +
  blank_theme +
  theme(axis.text.x=element_blank()) +
  geom_text(aes(y = value/3 + c(0, cumsum(value)[-length(value)]), 
                label = paste('$',round(value/1000000,0),'M', sep="")), size=4.5)+ 
  theme(plot.title = element_text(size = 30, face = "bold"))



