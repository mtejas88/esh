## =========================================
##
## Determining why "gold-plating"
##  categorizing gold-plated districts
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/gold_plating/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(ggplot2)

##imports
districts <- read.csv("data/interim/districts_clean_cats.csv")
frn_statuses <- read.csv("data/raw/frn_statuses.csv")
negative_barriers <- read.csv("data/raw/negative_barriers.csv")


#count gold plated districts that got denied funding
gold_plating <- filter(districts, category == 'gold-plated')
gold_plating_frns <- inner_join(gold_plating, frn_statuses, by = c("esh_id" = "recipient_id"))
dist_status <- group_by(gold_plating_frns, esh_id, frn_status)
dist_status_ct <- summarize(dist_status, count=n())
dist_denied <- (dist_status_ct %>% filter(frn_status == 'Denied') %>% distinct(esh_id))
nrow(dist_denied)/nrow(gold_plating)

dist_denied_canc <- (dist_status_ct %>% filter(frn_status == 'Denied' | frn_status == 'Cancelled') %>% distinct(esh_id))
nrow(dist_denied_canc)/nrow(gold_plating)

#count gold plated districts that have negative barriers
negative_barriers$indicator <- ifelse(negative_barriers$barriers > 0, TRUE, FALSE)
gold_plating_surveys <- inner_join(gold_plating, negative_barriers, by = c("esh_id" = "entity_id"))
dist_survey <- group_by(gold_plating_surveys, esh_id, indicator)
dist_survey_ct <- summarize(dist_survey, count=n())
dist_barriers <- (dist_survey_ct %>% filter(indicator == TRUE) %>% distinct(esh_id))
nrow(dist_barriers)/nrow(gold_plating)

#overlap
overlap <- inner_join(dist_barriers[,1], dist_denied[,1], by = c("esh_id" = "esh_id"))
nrow(overlap)/nrow(gold_plating)

##histogram of gold-plating cost/student
p.cost <- ggplot(gold_plating, aes(log(monthly_cost_per_student)))
#breakpoints
p.cost + geom_histogram(binwidth=.05)+
  scale_x_continuous(breaks=c(log(4.50),log(9.5),log(19.25),log(34.75),log(60.5),6), 
                     labels=c(4.50, 9.5,19.25,34.75,60.5,round(exp(6),0)))+
  ylab("Districts")+
  xlab("IA+WAN $/student")+ 
  geom_vline(xintercept = log(19.25), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(60.5), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(34.75), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(9.5), color = '#CB2027', linetype="dashed", size = 1)
#no breakpoints
p.cost + geom_histogram(binwidth=.05)+
  scale_x_continuous(breaks=c(log(4.50),log(9.5),log(19.25),log(34.75),log(60.5),6), 
                     labels=c(4.50, 9.5,19.25,34.75,60.5,round(exp(6),0)))+
  ylab("Districts")+
  xlab("IA+WAN $/student")

gold_plating$cost_category <- ifelse(gold_plating$monthly_cost_per_student > 4.5, 
                                     ifelse(gold_plating$monthly_cost_per_student <= 9.5, '$4.50-$9.50',
                                            ifelse(gold_plating$monthly_cost_per_student <= 19.25, '$9.50-$19.25',
                                                   ifelse(gold_plating$monthly_cost_per_student <= 34.75, '$19.25-$34.75',
                                                          ifelse(gold_plating$monthly_cost_per_student <= 60.5, '$34.75-$60.50',
                                                                 '>$60.50')))),'error')

table(gold_plating$cost_category)

##histogram of gold-plating bw/student
p.bw <- ggplot(gold_plating, aes(log(ia_bandwidth_per_student_kbps)))
#breakpoints
p.bw + geom_histogram(binwidth=.05)+
  scale_x_continuous(breaks=c(log(1000),log(2075),log(2550),log(5400),log(8000)), 
                     labels=c(1, 2,2.6,5.4,8))+
  ylab("Districts")+
  xlab("IA Mbps/student")+ 
  geom_vline(xintercept = log(2075), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(2550), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(5400), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(8000), color = '#CB2027', linetype="dashed", size = 1)
#no breakpoints
p.bw + geom_histogram(binwidth=.05)+
  scale_x_continuous(breaks=c(log(1000),log(2075),log(2550),log(5400),log(8000)), 
                     labels=c(1, 2,2.6,5.4,8))+
  ylab("Districts")+
  xlab("IA Mbps/student")

gold_plating$bw_category <- ifelse(gold_plating$ia_bandwidth_per_student_kbps > 1000, 
                                   ifelse(gold_plating$ia_bandwidth_per_student_kbps <= 2075, '1M-2.075M',
                                          ifelse(gold_plating$ia_bandwidth_per_student_kbps <= 2550, '2.075M-2.55M',
                                                 ifelse(gold_plating$ia_bandwidth_per_student_kbps <= 5400, '2.55M-5.4M',
                                                        ifelse(gold_plating$ia_bandwidth_per_student_kbps <= 8000, '5.4M-8M',
                                                               '>8M')))),'error')

table(gold_plating$bw_category)