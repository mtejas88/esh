## =========================================
##
## Create histogram
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/unscalable_match_dr")

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


##import
summary <- read.csv("data/summary.csv")
colnames(summary) <- c('X', 'discount_rate_c1_matrix', 'match approved', 'match pending')

##reshape
summary_1 <- melt(summary, id.var="discount_rate_c1_matrix")
summary_1 <- filter(summary_1, variable != 'X')
summary_1 <- summary_1[order(summary_1$variable, decreasing = T),]

##bar chart for discounts -- evan
p.discounts.1 <- ggplot(summary_1, aes(x=discount_rate_c1_matrix, y=value, fill=variable)) +
  geom_bar(stat="identity")+
  scale_fill_manual(values = c('grey','#009296') )+
  ylab("% unscalable campuses with state match")+
  xlab("")+
  ggtitle("Campuses needing fiber with \nstate match by discount")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))+ 
  scale_y_continuous(labels = scales::percent)+ 
  scale_x_continuous(labels = scales::percent, breaks = c(.25, .4, .5, .6, .7, .8, .9))+
  annotate("text", x = .52, y = .3, label = "51% of campuses including pending have free fiber builds", color = 'black')+
  annotate("text", x = .52, y = .28, label = "40% of campuses excluding pending have free fiber builds", color = 'black')+
  geom_text(aes(label = paste0(sprintf("%.0f", value*100), "%")), position = position_stack(vjust = 0.5), size = 3, color = 'white')
  
p.discounts.1



