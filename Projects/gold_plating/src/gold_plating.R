## =========================================
##
## Determining districts "gold-plating"
##  categorizing clean districts
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
#setwd("C:/Users/Justine/Documents/GitHub/ficher/Projects/gold_plating/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr" ,"ggplot2", "rgl")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
detach("package:plyr")
library(dplyr)
library(ggplot2)
#library(rgl)

##districts_deluxe and manipulations
districts <- read.csv("data/raw/districts_deluxe.csv")
districts$ia_monthly_cost_total <- ifelse(districts$ia_monthly_cost_total > 0, districts$ia_monthly_cost_total, 0)

districts$ia_bandwidth_per_student_kbps <- ifelse(districts$ia_bandwidth_per_student_kbps > 0, 
                                                   districts$ia_bandwidth_per_student_kbps, 
                                                   0)
districts$monthly_cost_per_student <- districts$ia_monthly_cost_total / districts$num_students

districts$include_in_universe_of_districts_all_charters <- ifelse(districts$include_in_universe_of_districts_all_charters== 'true', 
                                                                   TRUE,
                                                                   FALSE)
districts$exclude_from_ia_cost_analysis <- ifelse (districts$exclude_from_ia_cost_analysis== 'true',
                                                   TRUE,
                                                   FALSE)

#clean districts
districts_clean <- filter(districts, include_in_universe_of_districts_all_charters == TRUE)
districts_clean <- filter(districts_clean, exclude_from_ia_cost_analysis == FALSE)
districts_clean <- filter(districts_clean, num_students > 0)

#plot colors
districts_clean$high_bw <- ifelse(districts_clean$ia_bandwidth_per_student_kbps > 3000, 'gt 3M', 
                                  ifelse(districts_clean$ia_bandwidth_per_student_kbps > 1000, '1M - 3M',
                                         'lt 1M'))
districts_clean_high_bw <- filter(districts_clean, high_bw == 'gt 3M')

#plot
p1 <- ggplot(districts_clean, aes(y = log(ia_bandwidth_per_student_kbps), x = log(monthly_cost_per_student)))
#color
p1 + geom_point(aes(color = high_bw)) +
  scale_y_continuous(breaks=c(0,5,10), labels=c(exp(0), round(exp(5),0), round(exp(10),0)))+
  scale_x_continuous(breaks=c(-4,0,4), labels=c(round(exp(-4),-5), exp(0), round(exp(4),0)))+
  ylab("IA kbps/student")+
  xlab("IA $/student")

#summary
bws <- group_by(districts_clean, high_bw)
write.csv(summarize(bws, 
          sum_cost = sum(ia_monthly_cost_total, na.rm = T),
          average_cost = mean(ia_monthly_cost_total, na.rm = T), 
          average_cost_per_student = sum(ia_monthly_cost_total, na.rm = T)/sum(num_students, na.rm = T), 
          average_bandwidth = mean(ia_bw_mbps_total, na.rm = T), 
          average_bw_per_student_kbps = sum(ia_bw_mbps_total, na.rm = T)/sum(num_students, na.rm = T)*1000, 
          average_students = mean(num_students, na.rm = T),
          districts = n()), 
          "data/interim/districts_clean_bws_summary.csv")

##histogram of high bws cost/student
p.bw <- ggplot(districts_clean_high_bw, aes(log(monthly_cost_per_student)))
#breakpoints
p.bw + geom_histogram(binwidth=.1)+
  scale_x_continuous(breaks=c(-4,0,log(4.5),log(13.5),log(40)), 
                     labels=c(round(exp(-4),2), 1,4.5,13.5,40))+
  ylab("Districts")+
  xlab("IA $/student")+ 
  geom_vline(xintercept = log(1), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(4.5), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(13.5), color = '#CB2027', linetype="dashed", size = 1)+ 
  geom_vline(xintercept = log(40), color = '#CB2027', linetype="dashed", size = 1)
#no breakpoints
p.bw + geom_histogram(binwidth=.1)+
  scale_x_continuous(breaks=c(-4,0,log(4.5),log(13.5),log(40)), 
                   labels=c(round(exp(-4),2), 1,4.5,13.5,40))+
  ylab("Districts")+
  xlab("IA $/student")

districts_clean_high_bw$cost_category <- ifelse(districts_clean_high_bw$monthly_cost_per_student > 1, 
                                   ifelse(districts_clean_high_bw$monthly_cost_per_student <= 4.5, '$1-$4.50',
                                          ifelse(districts_clean_high_bw$monthly_cost_per_student <= 13.5, '$4.50-$13.50',
                                                 ifelse(districts_clean_high_bw$monthly_cost_per_student <= 40, '$13.50-$40',
                                                               '>$40'))),'<$1')

table(districts_clean_high_bw$cost_category)

round(nrow(districts_clean_high_bw)/nrow(districts_clean),2)
gt.1 <- nrow(districts_clean_high_bw) - nrow(filter(districts_clean_high_bw, cost_category == '<$1'))
round(gt.1/nrow(districts_clean),2)
gt.4.5 <- gt.1 - nrow(filter(districts_clean_high_bw, cost_category == '$1-$4.50'))
round(gt.4.5/nrow(districts_clean),2)
gt.13.5 <- gt.4.5 - nrow(filter(districts_clean_high_bw, cost_category == '$4.50-$13.50'))
round(gt.13.5/nrow(districts_clean),2)
round(nrow(filter(districts_clean_high_bw, cost_category == '>$40'))/nrow(districts_clean),2)
