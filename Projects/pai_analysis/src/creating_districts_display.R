## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

# remove every object in the environment
rm(list = ls())

##**************************************************************************************************************************************************
## read in data
districts_display <- read.csv("data/raw/2016_districts.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

#install and load packages
packages.to.install <- c("data.table", "plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(data.table)
library(plyr)


##**************************************************************************************************************************************************
## cleaning up the columns

#Cleaning up the columns that are supposed to be booleans
districts_display$exclude_from_ia_analysis <- ifelse(districts_display$exclude_from_ia_analysis == 't', TRUE, FALSE)
districts_display$exclude_from_ia_cost_analysis <- ifelse(districts_display$exclude_from_ia_cost_analysis == 't', TRUE, FALSE)
districts_display$exclude_from_wan_analysis <- ifelse(districts_display$exclude_from_wan_analysis == 't', TRUE, FALSE)
districts_display$exclude_from_wan_cost_analysis <- ifelse(districts_display$exclude_from_wan_cost_analysis == 't', TRUE, FALSE)
districts_display$exclude_from_current_fiber_analysis <- ifelse(districts_display$exclude_from_current_fiber_analysis == 't', TRUE, FALSE)
districts_display$include_in_universe_of_districts <- ifelse(districts_display$include_in_universe_of_districts == 't', TRUE, FALSE)
districts_display$meeting_knapsack_affordability_target <- ifelse(districts_display$meeting_knapsack_affordability_target == 't', TRUE, FALSE)


##**************************************************************************************************************************************************
## Calculating Pai $ per student

#e-rate funding for C1 (does not include voice). Clean and dirty broadband erate line items
#c1 <- 1364343502

#without AK:
c1 <- 1125134004

#e-rate funding for C2
districts_display$adjusted_c2 <- ifelse(is.na(districts_display$discount_rate_c2), mean(districts_display$discount_rate_c2, na.rm=T), districts_display$discount_rate_c2)
c2 <- sum((30 * districts_display$adjusted_c2) * (districts_display$num_students))

#e-rates share of funds
total_funds <- c1+c2

#e-rate funding for IA
#ia_total_funds <-  583053227

#without AK:
ia_total_funds <- 451975094

#e-rate funding for WAN
wan_total_funds <- c1 - ia_total_funds

rural_town_student_count <- (sum(districts_display$num_students [which (districts_display$locale == 'Rural'|districts_display$locale == 'Town')]))
urban_suburban_student_count <-   (sum(districts_display$num_students [which (districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')])) 

rural_town_rich_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Rural'|districts_display$locale == 'Town')&districts_display$adj_c1_discount_rate <= .4)]))
rural_town_middleclass_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Rural'|districts_display$locale == 'Town')&districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                                      .7)]))
rural_town_poor_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Rural'|districts_display$locale == 'Town')&districts_display$adj_c1_discount_rate >= .8)]))

urban_suburban_rich_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate <= .4)]))
urban_suburban_middleclass_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                                          .7)]))
urban_suburban_poor_student_count <- (sum(districts_display$num_students [which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate >= .8)]))

sum_students <- urban_suburban_rich_student_count + urban_suburban_middleclass_student_count+urban_suburban_poor_student_count + rural_town_rich_student_count + rural_town_poor_student_count+ rural_town_middleclass_student_count

#creating different weights for locales
weight_rural_town_rich <- 1.5 * (1/9.75)
weight_rural_town_middleclass <- 2 * (1/9.75)
weight_rural_town_poor <- 3 * (1/9.75)

weight_urban_suburban_rich <- .75 * (1/9.75)
weight_urban_suburban_middleclass <- 1 * (1/9.75)
weight_urban_suburban_poor <- 1.5 * (1/9.75)

#creating new summary category
districts_display$category[which (districts_display$locale == 'Rural'|districts_display$locale == 'Town')&(districts_display$adj_c1_discount_rate <= .4)] <- "Rural_Town_Rich"
districts_display$category[which ((districts_display$locale == 'Rural'|districts_display$locale == 'Town')&districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                    .7)] <- "Rural_Town_Middleclass"
districts_display$category[which ((districts_display$locale == 'Rural'|districts_display$locale == 'Town')&districts_display$adj_c1_discount_rate >= .8)] <- "Rural_Town_Poor"
districts_display$category[which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate <= .4)] <- "Urban_Suburban_Rich"
districts_display$category[which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                    .7)] <- "Urban_Suburban_Middleclass"
districts_display$category[which ((districts_display$locale == 'Urban'|districts_display$locale == 'Suburban')&districts_display$adj_c1_discount_rate >= .8)] <- "Urban_Suburban_Poor"


#multiply post discount total funds by weight. distributes total funds (e-rate share) to all locale types
urban_suburban_rich_dollars_per_student <- (weight_urban_suburban_rich * total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                           (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                           (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                           (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                           (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                           (weight_rural_town_poor*rural_town_poor_student_count) )

urban_suburban_middleclass_dollars_per_student <- (weight_urban_suburban_middleclass * total_funds) /((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                        (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                        (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                        (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                        (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                        (weight_rural_town_poor*rural_town_poor_student_count) )
urban_suburban_poor_dollars_per_student <-(weight_urban_suburban_poor * total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                          (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                          (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                          (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                          (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                          (weight_rural_town_poor*rural_town_poor_student_count) )

rural_town_rich_dollars_per_student <- (weight_rural_town_rich * total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                   (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                   (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                   (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                   (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                   (weight_rural_town_poor*rural_town_poor_student_count) )
rural_town_middleclass_dollars_per_student <-(weight_rural_town_middleclass * total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                (weight_rural_town_poor*rural_town_poor_student_count) )
rural_town_poor_dollars_per_student <-(weight_rural_town_poor * total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                  (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                  (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                  (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                  (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                  (weight_rural_town_poor*rural_town_poor_student_count) )




#numbers check
numbers_check <- ((urban_suburban_rich_student_count*urban_suburban_rich_dollars_per_student) + 
                    (urban_suburban_middleclass_student_count*urban_suburban_middleclass_dollars_per_student)+(urban_suburban_poor_student_count*urban_suburban_poor_dollars_per_student) + (rural_town_rich_student_count*rural_town_rich_dollars_per_student)+(rural_town_middleclass_student_count*rural_town_middleclass_dollars_per_student)+(rural_town_poor_student_count*rural_town_poor_dollars_per_student))



##**************************************************************************************************************************************************
## Calculating Pai IA $ per student, IA Pai Budget, Total Pai Budget


ia_urban_suburban_rich_dollars_per_student <- (weight_urban_suburban_rich * ia_total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                 (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                 (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                 (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                 (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                 (weight_rural_town_poor*rural_town_poor_student_count) )

ia_urban_suburban_middleclass_dollars_per_student <- (weight_urban_suburban_middleclass * ia_total_funds) /((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                              (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                              (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                              (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                              (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                              (weight_rural_town_poor*rural_town_poor_student_count) )
ia_urban_suburban_poor_dollars_per_student <-(weight_urban_suburban_poor * ia_total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                (weight_rural_town_poor*rural_town_poor_student_count) )

ia_rural_town_rich_dollars_per_student <- (weight_rural_town_rich * ia_total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                         (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                         (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                         (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                         (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                         (weight_rural_town_poor*rural_town_poor_student_count) )
ia_rural_town_middleclass_dollars_per_student <-(weight_rural_town_middleclass * ia_total_funds) /((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                                     (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                                     (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                                     (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                                     (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                                     (weight_rural_town_poor*rural_town_poor_student_count) )
ia_rural_town_poor_dollars_per_student <-(weight_rural_town_poor * ia_total_funds) / ((weight_urban_suburban_rich*urban_suburban_rich_student_count)+
                                                                                        (weight_urban_suburban_middleclass*urban_suburban_middleclass_student_count) + 
                                                                                        (weight_urban_suburban_poor*urban_suburban_poor_student_count) +
                                                                                        (weight_rural_town_rich*rural_town_rich_student_count)+
                                                                                        (weight_rural_town_middleclass*rural_town_middleclass_student_count) + 
                                                                                        (weight_rural_town_poor*rural_town_poor_student_count) )


#ia_district_budget_pai
districts_display$ia_district_budget_pai <- ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                   & districts_display$adj_c1_discount_rate >= .8,
                                                   (4/3)*ia_urban_suburban_poor_dollars_per_student*districts_display$num_students,
                                                   
                                                   ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                          & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <= .7,
                                                          (4/3)*ia_urban_suburban_middleclass_dollars_per_student*districts_display$num_students,
                                                          
                                                          ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                                 & districts_display$adj_c1_discount_rate <= .4,
                                                                 (4/3)*ia_urban_suburban_rich_dollars_per_student*districts_display$num_students,
                                                                 
                                                                 ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                        & districts_display$adj_c1_discount_rate >= .8,
                                                                        (4/3)*ia_rural_town_poor_dollars_per_student*districts_display$num_students,
                                                                        
                                                                        ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                               & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                                 .7,
                                                                               (4/3)*ia_rural_town_middleclass_dollars_per_student*districts_display$num_students,
                                                                               
                                                                               ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                                      & districts_display$adj_c1_discount_rate <= .4,
                                                                                      (4/3)*ia_rural_town_rich_dollars_per_student*districts_display$num_students, "NA"))))))

districts_display$ia_district_budget_pai <- as.numeric(districts_display$ia_district_budget_pai)

districts_display$ia_yearly_district_cost_total <- (districts_display$ia_monthly_cost_total*12)

districts_display$district_budget_pai <-  ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                 & districts_display$adj_c1_discount_rate >= .8,
                                                 4/3*urban_suburban_poor_dollars_per_student*districts_display$num_students,
                                                 
                                                 ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                        & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <= .7,
                                                        4/3*urban_suburban_middleclass_dollars_per_student*districts_display$num_students,
                                                        
                                                        ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                               & districts_display$adj_c1_discount_rate <= .4,
                                                               4/3*urban_suburban_rich_dollars_per_student*districts_display$num_students,
                                                               
                                                               ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                      & districts_display$adj_c1_discount_rate >= .8,
                                                                      4/3*rural_town_poor_dollars_per_student*districts_display$num_students,
                                                                      
                                                                      ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                             & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                               .7,
                                                                             4/3*rural_town_middleclass_dollars_per_student*districts_display$num_students,
                                                                             
                                                                             ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                                    & districts_display$adj_c1_discount_rate <= .4,
                                                                                    4/3*rural_town_rich_dollars_per_student*districts_display$num_students, "NA"))))))

districts_display$district_budget_pai <- as.numeric(districts_display$district_budget_pai)


#ia_current_oop is districts share of their total cost
districts_display$ia_current_oop <- (1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)

write.csv(districts_display, "data/interim/districts_display.csv", row.names = FALSE)