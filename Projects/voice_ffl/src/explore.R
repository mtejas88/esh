## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

spend <- read.csv("data/raw/spend.csv", as.is=T, header=T, stringsAsFactors=F)
spend.by.discount <- read.csv("data/raw/spend_discount.csv", as.is=T, header=T, stringsAsFactors=F)
spend.applicant <- read.csv("data/raw/spend_app.csv", as.is=T, header=T, stringsAsFactors=F)

spend$per.applicant.pre <- spend$pre_discount / spend$num_applicants
spend$per.applicant.erate <- spend$erate_request / spend$num_applicants

erate_saves <- spend[spend$year == 2015, c('erate_request')] - spend[spend$year == 2017, c('erate_request')]
erate_spend_perc <- spend[spend$year == 2017, c('erate_request')] / spend[spend$year == 2015, c('erate_request')]

spend$oop <- spend$pre_discount - spend$erate_request
oop_costs <-  spend[spend$year == 2017, c('oop')] - spend[spend$year == 2015, c('oop')]
oop_spend_perc <-  spend[spend$year == 2017, c('oop')] / spend[spend$year == 2015, c('oop')]

sum(spend.by.discount$pre_discount, na.rm = T)

spend.by.discount$discount_rate_grouping <- ifelse(spend.by.discount$discount_rate >= 80,
                                                   'High Discount',
                                                   ifelse(spend.by.discount$discount_rate <= 30,
                                                   'Low Discount',
                                                   'Mid Discount'))

spend.by.discount.grouping <- group_by(spend.by.discount, year, discount_rate_grouping) %>%
                                summarise(num_applicants = sum(num_applicants, na.rm = T),
                                          num_line_items = sum(num_line_items, na.rm = T),
                                          num_applications = sum(num_applications, na.rm = T),
                                          pre_discount = sum(pre_discount, na.rm = T),
                                          erate_request = sum(erate_request, na.rm = T)) %>%
                                as.data.frame()

high.15 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2015 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'High Discount', 
                                      'pre_discount']

high.16 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2016 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'High Discount' &
                                        !is.na(spend.by.discount.grouping$discount_rate_grouping), 
                                      'pre_discount']

high.17 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2017 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'High Discount' &
                                        !is.na(spend.by.discount.grouping$discount_rate_grouping), 
                                      'pre_discount']

low.15 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2015 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'Low Discount', 
                                      'pre_discount']

low.16 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2016 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'Low Discount' &
                                        !is.na(spend.by.discount.grouping$discount_rate_grouping), 
                                      'pre_discount']

low.17 <- spend.by.discount.grouping[spend.by.discount.grouping$year == 2017 & 
                                        spend.by.discount.grouping$discount_rate_grouping == 'Low Discount' &
                                        !is.na(spend.by.discount.grouping$discount_rate_grouping), 
                                      'pre_discount']

perc.high.15 <- high.15 / spend[spend$year == 2015, c('pre_discount')]
perc.high.16 <- high.16 / spend[spend$year == 2016, c('pre_discount')]
perc.high.17 <- high.17 / spend[spend$year == 2017, c('pre_discount')]

perc.low.15 <- low.15 / spend[spend$year == 2015, c('pre_discount')]
perc.low.16 <- low.16 / spend[spend$year == 2016, c('pre_discount')]
perc.low.17 <- low.17 / spend[spend$year == 2017, c('pre_discount')]


head(spend.applicant)
spend.applicant$oop_17 <- spend.applicant$pre_discount_17 - spend.applicant$erate_request_17
spend.applicant$oop_15 <- spend.applicant$pre_discount_15 - spend.applicant$erate_request_15
spend.applicant$oop.less <- spend.applicant$oop_17 <= spend.applicant$oop_15
#old incorrect way - this was the erate share
#spend.applicant$oop.less <- spend.applicant$erate_request_17 <= spend.applicant$erate_request_15
spend.applicant$savings <- spend.applicant$oop_15 - spend.applicant$oop_17
#old incorrect way - this was the erate share
#spend.applicant$savings <- spend.applicant$erate_request_15 - spend.applicant$erate_request_17
table(spend.applicant$oop.less)
perc.oop.less <- nrow(spend.applicant[spend.applicant$oop.less == T,]) / nrow(spend.applicant)
sum(spend.applicant$pre_discount_17, na.rm = T)

saving <- filter(spend.applicant, oop.less == TRUE)
saving.avg <- mean(saving$savings, na.rm = T)

expensive <- filter(spend.applicant, oop.less == FALSE)
expensive.loss.avg <- mean(expensive$savings, na.rm = T)

total.district.savings <- sum(spend.applicant$savings, na.rm = T)
total.erate.savings <- sum(spend.applicant$erate_request_15 - spend.applicant$erate_request_17, na.rm = T)
total.savings <- sum(spend.applicant$pre_discount_15 - spend.applicant$pre_discount_17, na.rm = T)

