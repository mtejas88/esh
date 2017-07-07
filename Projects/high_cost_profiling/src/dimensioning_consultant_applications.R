## =========================================
##
## Dimension fiber target districts
##    Locale, district size, number of
##    alternative fiber service providers
##
##  NOT USED -- no significant diffs from 
##  population of applications
##
## =========================================

## Clearing memory
rm(list=ls())

## Setting working directory -- needs to be changed
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/high_cost_profiling")

##load packages
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## Read in data
applications <- read.csv("data/raw/applications.csv", as.is=T, header=T, stringsAsFactors=F)
applications$discount_category <- floor(applications$category_one_discount_rate/10)*10
consultant.applications <- filter(applications, consultant_indicator == 1)

consultant.applications.count <- nrow(consultant.applications)
consultant.applications.requested <- sum(consultant.applications$total_funding_year_commitment_amount_request)
applications.count <- nrow(applications)
applications.requested <- sum(applications$total_funding_year_commitment_amount_request)

#Dimension by category - consultant applications
category.consultant.applications <- group_by(consultant.applications, category_of_service) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/consultant.applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/consultant.applications.requested)

png('figures/service_category.png')
ggplot(category.consultant.applications, aes(x = category_of_service, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Consultant applications by service category") +
  labs(x = 'Category', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by category - consultant applications
category.applications <- group_by(applications, category_of_service) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/applications.requested)

png('figures/service_category_all.png')
ggplot(category.applications, aes(x = category_of_service, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Applications by service category") +
  labs(x = 'Category', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()


#Dimension by discount rate  - consultant applications
discount.consultant.applications <- group_by(consultant.applications, discount_category) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/consultant.applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/consultant.applications.requested)

png('figures/discount.png')
ggplot(discount.consultant.applications, aes(x = discount_category, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Consultant applications by discount rate") +
  labs(x = 'Discount Rate', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by discount rate  - all
discount.applications <- group_by(applications, discount_category) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/applications.requested)

png('figures/discount_all.png')
ggplot(category.applications, aes(x = discount_category, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Applications by discount rate") +
  labs(x = 'Discount Rate', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()


#Dimension by applicant type  - consultant applications
type.consultant.applications <- group_by(consultant.applications, applicant_type) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/consultant.applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/consultant.applications.requested)

png('figures/type.png')
ggplot(type.consultant.applications, aes(x = applicant_type, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Consultant applications by applicant type") +
  labs(x = 'Applicant Type', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by applicant type  - all
type.applications <- group_by(applications, applicant_type) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/applications.requested)

png('figures/type_all.png')
ggplot(type.applications, aes(x = applicant_type, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Applications by applicant type") +
  labs(x = 'Applicant Type', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()


#Dimension by applicant type  - consultant applications
speck.consultant.applications <- group_by(consultant.applications, special_construction_indicator) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/consultant.applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/consultant.applications.requested)

png('figures/speck.png')
ggplot(speck.consultant.applications, aes(x = special_construction_indicator, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  ggtitle("Consultant applications by special consturction presence") +
  labs(x = 'Special Construction', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()

#Dimension by special construction  - all
speck.applications <- group_by(applications, special_construction_indicator) %>%
  summarise(num.applications = n(),
            pct.applications = num.applications/applications.count,
            funding.requested = sum(total_funding_year_commitment_amount_request),
            pct.funding.requested = funding.requested/applications.requested)

png('figures/speck_all.png')
ggplot(speck.applications, aes(x = special_construction_indicator, y = pct.applications)) + 
  geom_bar(stat = 'identity', fill = '#009296') + 
  ggtitle("Applications by special construction presence") +
  labs(x = 'Special Construction', y = '% Applications') +
  ylim(0, 1) +
  theme_grey()
dev.off()