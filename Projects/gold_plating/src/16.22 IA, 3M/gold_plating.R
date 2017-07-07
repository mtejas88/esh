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
#districts$wan_monthly_cost_total <- ifelse(districts$wan_monthly_cost_total > 0, districts$wan_monthly_cost_total, 0)
#districts$monthly_cost_total <- districts$ia_monthly_cost_total + districts$wan_monthly_cost_total

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
districts_clean$high_bw <- ifelse(districts_clean$ia_bandwidth_per_student_kbps > 3000, TRUE, FALSE)
districts_clean$high_cost <- ifelse(districts_clean$monthly_cost_per_student > 16.22, TRUE, FALSE)
districts_clean$category <- ifelse(districts_clean$high_bw, 
                                   ifelse( districts_clean$high_cost, 
                                           'gold-plated',
                                           'high bw'),
                                   ifelse( districts_clean$high_cost, 
                                           'high cost',
                                           'basic'))
#districts_clean$category_col <- factor(districts_clean$category,
#                                   levels = c("basic","high cost","high bw", "gold-plated"))
#districts_clean$category_col <- as.integer(districts_clean$category_col)
#districts_clean$example <- ifelse(districts_clean$esh_id == '883304' | districts_clean$esh_id == '969364', TRUE, FALSE)

districts_clean_high_cost <- filter(districts_clean, high_cost == TRUE)
districts_clean_high_bw <- filter(districts_clean, high_bw == TRUE)
districts_clean_high <- filter(districts_clean_high_cost, high_bw == TRUE)

#plot
p1 <- ggplot(districts_clean, aes(y = log(ia_bandwidth_per_student_kbps), x = log(monthly_cost_per_student)))
#color
p1 + geom_point(aes(color = category)) +
  scale_y_continuous(breaks=c(0,5,10), labels=c(exp(0), round(exp(5),0), round(exp(10),0)))+
  scale_x_continuous(breaks=c(-4,0,4), labels=c(round(exp(-4),-5), exp(0), round(exp(4),0)))+
  ylab("IA kbps/student")+
  xlab("IA $/student")


#summary
categories <- group_by(districts_clean, category)
write.csv(summarize(categories, 
                    sum_cost = sum(ia_monthly_cost_total, na.rm = T),
                    average_cost = mean(ia_monthly_cost_total, na.rm = T), 
                    average_cost_per_student = sum(ia_monthly_cost_total, na.rm = T)/sum(num_students, na.rm = T), 
                    average_bandwidth = mean(ia_bw_mbps_total, na.rm = T), 
                    average_bw_per_student_kbps = sum(ia_bw_mbps_total, na.rm = T)/sum(num_students, na.rm = T)*1000, 
                    average_students = mean(num_students, na.rm = T),
                    districts = n()), 
          "data/interim/districts_clean_cats_summary_2.csv")

write.csv(districts_clean,
          "data/interim/districts_clean_cats_2.csv")
