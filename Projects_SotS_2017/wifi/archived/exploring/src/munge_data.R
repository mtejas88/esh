## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())
library(dplyr)
library(ggplot2)
#library("reshape2")
#setwd('~/Documents/Analysis/ficher/Projects_SotS_2017/wifi/exploring/')

##**************************************************************************************************************************************************
## read in data

connectivity.all <- read.csv("data/raw/connectivity_all.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
source('../../../General_Resources/common_functions/correct_dataset.R')
connectivity.all <- correct.dataset(connectivity.all, 0 , 0)
table(connectivity.all$year)

connectivity.all$bw_per_student <- connectivity.all$bw_per_student %>% as.numeric()
connectivity.all$num_students <- connectivity.all$num_students %>% as.numeric()

connectivity.all <- filter(connectivity.all, bw_per_student >= 1)

ggplot(connectivity.all, aes(num_students, bw_per_student)) + 
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 500)) +
  scale_x_continuous(limits = c(0, 10000))

ggplot(connectivity.all[connectivity.all$year > 2015,], aes(num_students, bw_per_student)) + 
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 500)) +
  scale_x_continuous(limits = c(0, 10000))

ggplot(connectivity.all[connectivity.all$year > 2016,], aes(num_students, bw_per_student)) + 
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 500)) +
  scale_x_continuous(limits = c(0, 10000))

ggplot(connectivity.all[connectivity.all$year %in% c(2015, 2017),], aes(num_students, bw_per_student)) + 
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 500)) +
  scale_x_continuous(limits = c(0, 10000))

connectivity.all$ia_cost_per_mbps <- round(connectivity.all$ia_cost_per_mbps %>% as.numeric(), 2)

ggplot(connectivity.all[connectivity.all$ia_cost_per_mbps > 0,], aes(round(ia_cost_per_mbps,2), bw_per_student)) +
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 5000)) +
  scale_x_continuous(limits = c(0, 100))

ggplot(connectivity.all[connectivity.all$ia_cost_per_mbps > 0 & connectivity.all$year == 2017,], aes(round(ia_cost_per_mbps,2), bw_per_student)) +
  geom_point(aes(color = factor(year)), alpha = 0.5) +
  scale_y_continuous(limits = c(0, 5000)) +
  scale_x_continuous(limits = c(0, 100))

ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(num_students, bw_per_student)) +
  geom_point(aes(color = factor(district_size)))

ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(num_students, bw_per_student)) +
  geom_point(aes(color = factor(locale)))

connectivity.all$mbps_needed_to_meet <- ifelse(connectivity.all$bw_per_student >= 100, 0,
                                               (100 - connectivity.all$bw_per_student) * connectivity.all$num_students / 1000)

ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(mbps_needed_to_meet, bw_per_student)) +
  geom_point(aes(color = factor(district_size)))
ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(num_students, mbps_needed_to_meet)) +
  geom_point(aes(color = factor(district_size))) + 
  scale_x_continuous(limits = c(0, 10000)) +
  scale_y_continuous(limits = c(0, 2500))
ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(mbps_needed_to_meet, num_students)) +
  geom_point(aes(color = factor(district_size))) + 
  scale_x_continuous(limits = c(0, 2500)) +
  scale_y_continuous(limits = c(0, 10000))
ggplot(connectivity.all[connectivity.all$year > 2016 & connectivity.all$bw_per_student < 100,], aes(mbps_needed_to_meet)) +
  geom_histogram(binwidth = 100) +
  scale_x_continuous(limits = c(-100, 2500))

connectivity.all$cost_to_meet_current_pricing <- ifelse(connectivity.all$bw_per_student >= 100, 0,
                                                        round(connectivity.all$mbps_needed_to_meet * connectivity.all$ia_cost_per_mbps,2))
