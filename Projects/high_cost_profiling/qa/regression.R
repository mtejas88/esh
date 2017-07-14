## =========================================
##
## REGRESSION
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

applications <- read.csv("data/raw/applications.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## FROMAT DATA

applications$cost_per_student <- applications$total_funding_year_commitment_amount_request / applications$fulltime_enrollment
range(applications$cost_per_student)
quantile(applications$cost_per_student, probs=seq(0,1,by=0.01))

range(applications$total_funding_year_commitment_amount_request)
quantile(applications$total_funding_year_commitment_amount_request, probs=seq(0,1,by=0.01))

## make character columns factors
applications$applicant_type <- as.factor(applications$applicant_type)
applications$urban_rural_status <- as.factor(applications$urban_rural_status)
applications$category_of_service <- as.factor(applications$category_of_service)

## take out application_number, cost_per_student
dta.model <- applications[,-c(1,3,13)]

##**************************************************************************************************************************************************
## regression

## no log
model1a <- lm(total_funding_year_commitment_amount_request ~ consultant_indicator + special_construction_indicator +
               num_service_types + num_spins + num_recipients + applicant_type + category_of_service + urban_rural_status +
               category_one_discount_rate + fulltime_enrollment, data=applications)
summary(model1a)
## with log
model1b <- lm(log(total_funding_year_commitment_amount_request) ~ consultant_indicator + special_construction_indicator +
               num_service_types + num_spins + num_recipients + applicant_type + category_of_service + urban_rural_status +
               category_one_discount_rate + fulltime_enrollment, data=applications)
summary(model1b)

## just test consultant indicator
t.test(applications$total_funding_year_commitment_amount_request ~ applications$consultant_indicator)
t.test(log(applications$total_funding_year_commitment_amount_request) ~ applications$consultant_indicator)

## no log
model3a <- lm(cost_per_student ~ consultant_indicator + special_construction_indicator +
               num_service_types + num_spins + num_recipients + applicant_type + category_of_service + urban_rural_status +
               category_one_discount_rate + fulltime_enrollment, data=applications)
summary(model3a)
## with log
model3b <- lm(log(cost_per_student) ~ consultant_indicator + special_construction_indicator +
                num_service_types + num_spins + num_recipients + applicant_type + category_of_service + urban_rural_status +
                category_one_discount_rate + fulltime_enrollment, data=applications)
summary(model3b)

## just test consultant indicator
t.test(applications$cost_per_student ~ applications$consultant_indicator)
t.test(log(applications$cost_per_student) ~ applications$consultant_indicator)
