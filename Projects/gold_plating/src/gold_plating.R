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
library(dplyr)
library(ggplot2)
#library(rgl)

##districts_deluxe and manipulations
districts <- read.csv("data/raw/districts_deluxe.csv")
districts$ia_monthly_cost_total <- ifelse(districts$ia_monthly_cost_total > 0, districts$ia_monthly_cost_total, 0)
districts$wan_monthly_cost_total <- ifelse(districts$wan_monthly_cost_total > 0, districts$wan_monthly_cost_total, 0)
districts$monthly_cost_total <- districts$ia_monthly_cost_total + districts$wan_monthly_cost_total

districts$ia_bandwidth_per_student_kbps <- ifelse(districts$ia_bandwidth_per_student_kbps > 0, 
                                                   districts$ia_bandwidth_per_student_kbps, 
                                                   0)
districts$monthly_cost_per_student <- districts$monthly_cost_total / districts$num_students

districts$include_in_universe_of_districts_all_charters <- ifelse(districts$include_in_universe_of_districts_all_charters== TRUE, 
                                                                   TRUE,
                                                                   FALSE)
districts$exclude_from_ia_cost_analysis <- ifelse (districts$exclude_from_ia_cost_analysis== TRUE,
                                                   TRUE,
                                                   FALSE)

#clean districts
districts_clean <- filter(districts, include_in_universe_of_districts_all_charters == TRUE)
districts_clean <- filter(districts_clean, exclude_from_ia_cost_analysis == FALSE)
districts_clean <- filter(districts_clean, num_students > 0)

#plot colors
districts_clean$high_bw <- ifelse(districts_clean$ia_bandwidth_per_student_kbps > 1000, TRUE, FALSE)
districts_clean$high_cost <- ifelse(districts_clean$monthly_cost_per_student > 4.5, TRUE, FALSE)
districts_clean$category <- ifelse(districts_clean$high_bw, 
                                   ifelse( districts_clean$high_cost, 
                                           'gold-plated',
                                           'high bw'),
                                   ifelse( districts_clean$high_cost, 
                                           'high cost',
                                           'basic'))
districts_clean$category_col <- factor(districts_clean$category,
                                   levels = c("basic","high cost","high bw", "gold-plated"))
districts_clean$category_col <- as.integer(districts_clean$category_col)

districts_clean_high_cost <- filter(districts_clean, high_cost == TRUE)
districts_clean_high_bw <- filter(districts_clean, high_bw == TRUE)
districts_clean_high <- filter(districts_clean_high_cost, high_bw == TRUE)

#plot
p1 <- ggplot(districts_clean, aes(y = log(ia_bandwidth_per_student_kbps), x = log(monthly_cost_per_student)))
p1 + geom_point(aes(color = category)) +
  scale_y_continuous(breaks=c(0,5,10), labels=c(exp(0), round(exp(5),0), round(exp(10),0)))+
  scale_x_continuous(breaks=c(-4,0,4), labels=c(round(exp(-4),-5), exp(0), round(exp(4),0)))+
  ylab("IA kbps/student")+
  xlab("IA+WAN $/student")

## use the cex command to change the size of the points. you can play around with the scalar factor (right now set to 1/5) to make the points fit on the graph.
#cex=1/5*(sqrt(districts_clean$num_students)/pi)

p2 <- ggplot(districts_clean, aes(y = log(ia_bw_mbps_total), x = log(monthly_cost_total)))
p2 + geom_point(aes(color = category)) +
  scale_x_continuous(breaks=c(0,5,10,15), labels=c(exp(0), round(exp(5),0),round(exp(10),0),round(exp(15),0)))+
  scale_y_continuous(breaks=c(0,4,8,12), labels=c(exp(0), round(exp(4),0),round(exp(8),0),round(exp(12),0)))+
  ylab("IA mbps")+
  xlab("IA+WAN $")


#plot3d(districts_clean$monthly_cost_total, districts_clean$ia_bw_mbps_total, districts_clean$num_students, 
#       type="s", size=1, lit=TRUE, log="xyz", 
#       col=districts_clean$category_col)

#summary
categories <- group_by(districts_clean, category)
write.csv(summarize(categories, 
          sum_cost = sum(monthly_cost_total, na.rm = T),
          average_cost = mean(monthly_cost_total, na.rm = T), 
          average_cost_per_student = sum(monthly_cost_total, na.rm = T)/sum(num_students, na.rm = T), 
          average_bandwidth = mean(ia_bw_mbps_total, na.rm = T), 
          average_bw_per_student_kbps = sum(ia_bw_mbps_total, na.rm = T)/sum(num_students, na.rm = T)*1000, 
          average_students = mean(num_students, na.rm = T),
          districts = n()), 
          "data/interim/districts_clean_cats_summary.csv")

write.csv(districts_clean,
          "data/interim/districts_clean_cats.csv")
