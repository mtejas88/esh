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
total_funding_by_district <- read.csv("data/raw/2016_total_funding_by_district.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
service_providers <- read.csv("data/raw/service_providers.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)


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
c1 <- 1364343502

#e-rate funding for C2
districts_display$adjusted_c2 <- ifelse(is.na(districts_display$discount_rate_c2), mean(districts_display$discount_rate_c2, na.rm=T), districts_display$discount_rate_c2)
c2 <- sum((30 * districts_display$adjusted_c2) * (districts_display$num_students))

#e-rates share of funds
total_funds <- c1+c2

#e-rate funding for IA
ia_total_funds <-  583053227

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

##**************************************************************************************************************************************************
#Merging tables, and craeting TODAY model

#updating ia_monthly_cost total and wan_monthly_cost_total based on total funding by district (clean and dirty)
districts_display <- merge(x = districts_display, y = total_funding_by_district, by='esh_id')
districts_display$ia_monthly_cost_total <- districts_display$monthly_internet_spend
districts_display$wan_monthly_cost_total <- districts_display$monthly_wan_spend
drops <- c('monthly_internet_spend','monthly_wan_spend','total_internet_spend','total_wan_spend')
districts_display <- districts_display[ , !(names(districts_display) %in% drops)]

districts_display$district_cost_total <- (districts_display$ia_monthly_cost_total*12)+(districts_display$wan_monthly_cost_total*12)+(30*districts_display$num_students)
districts_display$district_cost_c1 <- (districts_display$ia_monthly_cost_total*12)+(districts_display$wan_monthly_cost_total*12)

#update total current oop
districts_display$total_current_oop <- (((1-districts_display$adjusted_c2)*(30*districts_display$num_students)) + 
                                          ((1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)) + 
                                          ((1-districts_display$adj_c1_discount_rate)*(districts_display$wan_monthly_cost_total*12)))

##**************************************************************************************************************************************************
#MAXIMIZED COST model (same OOP)

#if ia_current_oop is greater than the ia_district_budget_pai/4 (which is pai_oop), ia_current_oop + pai_non_oop. Else 4 * ia_current_oop
districts_display$max_cost_ia_pai_budg <- ifelse((districts_display$ia_current_oop > (as.numeric(districts_display$ia_district_budget_pai)/4)), 
                                                 (districts_display$ia_current_oop)+(districts_display$ia_district_budget_pai*.75), 4*districts_display$ia_current_oop)

districts_display$max_cost_bandwidth_per_student <- (((as.numeric(districts_display$max_cost_ia_pai_budg)/12)/districts_display$ia_monthly_cost_per_mbps)*1000)/(districts_display$num_students)

#created this line for max cost IA oop. no matter what in this model, the district's oop stays the same
max_cost_ia_oop <- districts_display$ia_current_oop

#max cost IA E-rate portion
districts_display$max_cost_ia_erate_share <- districts_display$max_cost_ia_pai_budg - max_cost_ia_oop

#max cost total budget 
districts_display$max_cost_total_pai_budg <- ifelse(districts_display$total_current_oop > (as.numeric(districts_display$district_budget_pai)/4), 
                                                    districts_display$total_current_oop+(districts_display$district_budget_pai*.75), 4*districts_display$total_current_oop)

#max cost total oop
districts_display$max_cost_total_oop <- districts_display$total_current_oop

#max cost E-rate portion
districts_display$max_cost_total_erate_share <- districts_display$max_cost_total_pai_budg - districts_display$max_cost_total_oop

##**************************************************************************************************************************************************
#BW CONSTANT model

districts_display$bw_constant_ia_monthly_budget <- districts_display$ia_monthly_cost_total
districts_display$bw_constant_ia_pai_budg <- districts_display$bw_constant_ia_monthly_budget * 12

#if current IA cost is more than what you would get under Pai, your OOP is your current OOP - .75 of the Pai budget. othewise it's .25 of pai budget
districts_display$bw_constant_ia_oop <- ifelse(districts_display$ia_yearly_district_cost_total/as.numeric(districts_display$ia_district_budget_pai)>1,
                                               (districts_display$ia_yearly_district_cost_total-(as.numeric(districts_display$ia_district_budget_pai)*.75)), .25*districts_display$ia_yearly_district_cost_total)   


districts_display$bw_constant_bandwidth_per_student <- (districts_display$bw_constant_ia_monthly_budget / (districts_display$ia_monthly_cost_per_mbps)*1000)/districts_display$num_students

#bw constant IA E-rate portion
districts_display$bw_constant_ia_erate_share <- districts_display$bw_constant_ia_pai_budg - districts_display$bw_constant_ia_oop

#bw constant total budget
districts_display$bw_constant_total_pai_budg <- districts_display$district_cost_total

#bw constant total oop
districts_display$bw_constant_total_pai_oop <- ifelse(districts_display$district_cost_total/(districts_display$district_budget_pai)>1,
                                                      (districts_display$district_cost_total-(districts_display$district_budget_pai*.75)), .25*districts_display$district_cost_total)                                 

#bw constant E-rate portion
districts_display$bw_constant_total_erate_share <- districts_display$bw_constant_total_pai_budg - districts_display$bw_constant_total_pai_oop

##**************************************************************************************************************************************************
#COST CONSTANT model (Pai OOP)

## If you can't afford to spend more OOP, this is the max amount you will get as a district from E-rate and OOP combined
districts_display$cost_constant_ia_pai_budj <- ifelse ((4*districts_display$ia_current_oop)<(districts_display$ia_district_budget_pai),
                                                       (4*districts_display$ia_current_oop),districts_display$ia_district_budget_pai)

districts_display$cost_constant_bandwidth_per_student <- (((as.numeric(districts_display$cost_constant_ia_pai_budj)/12)/districts_display$ia_monthly_cost_per_mbps)*1000)/(districts_display$num_students)

#created this line for cost constant OOP
districts_display$cost_constant_ia_oop <- ifelse((4*districts_display$ia_current_oop)<(districts_display$ia_district_budget_pai),
                                                 districts_display$ia_current_oop,districts_display$ia_district_budget_pai/4)

#cost constant IA E-rate potion
districts_display$cost_constant_ia_erate_share <- districts_display$cost_constant_ia_pai_budj - districts_display$cost_constant_ia_oop

#cost constant total budget
districts_display$cost_constant_total_pai_budj <- ifelse ((4*districts_display$total_current_oop)<(districts_display$district_budget_pai),
                                                          (4*districts_display$total_current_oop),districts_display$district_budget_pai)

#cost costant total oop 
districts_display$cost_constant_total_pai_oop <- ifelse ((4*districts_display$total_current_oop)<(districts_display$district_budget_pai),
                                                         districts_display$total_current_oop, districts_display$district_budget_pai/4)

#cost costant E-rate portion
districts_display$cost_constant_total_erate_share <- districts_display$cost_constant_total_pai_budj - districts_display$cost_constant_total_pai_oop

##**************************************************************************************************************************************************
#Adding more fields to districts display based on the models


#districts meeting and districts in sample
districts_display$current_districts_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                        districts_display$ia_bandwidth_per_student_kbps >= 100, 1, 0)
districts_display$current_districts_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE, 1, 0)
districts_display$max_cost_districts_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                         districts_display$max_cost_bandwidth_per_student >= 100 &
                                                         districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                         districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)
districts_display$max_cost_districts_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                        districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                        districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)
districts_display$cost_constant_districts_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                              districts_display$cost_constant_bandwidth_per_student >= 100 &
                                                              districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                              districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)
districts_display$cost_constant_districts_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                             districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                             districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)
districts_display$bw_constant_districts_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                            districts_display$bw_constant_bandwidth_per_student >= 100 &
                                                            districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                            districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)
districts_display$bw_constant_districts_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                           districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                           districts_display$ia_monthly_cost_per_mbps > 0, 1, 0)



#creating current num students meeting and max cost num students meeting
districts_display$current_num_students_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                           districts_display$ia_bandwidth_per_student_kbps >= 100, districts_display$num_students, 0)
districts_display$current_num_students_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE, districts_display$num_students, 0)
districts_display$max_cost_num_students_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                            districts_display$max_cost_bandwidth_per_student >= 100 &
                                                            districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                            districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)
districts_display$max_cost_num_students_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                           districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                           districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)
#cost constant
districts_display$cost_constant_num_students_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                                 districts_display$cost_constant_bandwidth_per_student >= 100 &
                                                                 districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                 districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)
districts_display$cost_constant_num_students_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                                districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)

#bw constant
districts_display$bw_constant_num_students_meeting <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                               districts_display$bw_constant_bandwidth_per_student >= 100 &
                                                               districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                               districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)
districts_display$bw_constant_num_students_sample <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                              districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                              districts_display$ia_monthly_cost_per_mbps > 0, districts_display$num_students, 0)

##**************************************************************************************************************************************************
#CREATING A CATEGORY DF
num_students_category <- aggregate(districts_display$num_students, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(num_students_category) <- c('category','num_students_category')

cost_constant_total_pai_budg_category <- aggregate(districts_display$cost_constant_total_pai_budj, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_budg_category) <- c('category','cost_constant_total_pai_budg_category')

bw_constant_total_pai_budg_category <- aggregate(districts_display$bw_constant_total_pai_budg, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_budg_category) <- c('category','bw_constant_total_pai_budg_category')

max_cost_total_pai_budg_category <- aggregate(districts_display$max_cost_total_pai_budg, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_total_pai_budg_category) <- c('category','max_cost_total_pai_budg_category')

district_cost_total_category <- aggregate(districts_display$district_cost_total, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(district_cost_total_category) <- c('category','district_cost_total_category')

#cost_constant_total_pai_oop, bw_constant_total_pai_oop, max_cost_total_oop, total_current_oop
cost_constant_total_pai_oop_category <- aggregate(districts_display$cost_constant_total_pai_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_oop_category) <- c('category','cost_constant_total_pai_oop')

bw_constant_total_pai_oop_category <- aggregate(districts_display$bw_constant_total_pai_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_oop_category) <- c('category','bw_constant_total_pai_oop')

max_cost_total_oop_category <- aggregate(districts_display$max_cost_total_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_total_oop_category) <- c('category','max_cost_total_oop')

total_current_oop_category <- aggregate(districts_display$total_current_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(total_current_oop_category) <- c('category','total_current_oop')


current_num_students_meeting_category <- aggregate(districts_display$current_num_students_meeting, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(current_num_students_meeting_category) <- c('category','current_num_students_meeting_category')
max_cost_num_students_meeting_category <- aggregate(districts_display$max_cost_num_students_meeting, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_meeting_category) <- c('category','max_cost_num_students_meeting_category')

current_num_students_sample_category <- aggregate(districts_display$current_num_students_sample, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(current_num_students_sample_category) <- c('category','current_num_students_sample_category')

max_cost_num_students_sample_category <- aggregate(districts_display$max_cost_num_students_sample, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_sample_category) <- c('category','max_cost_num_students_sample_category')



#joining tables
category_df <- merge(x=num_students_category,y=cost_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=district_cost_total_category, by='category')
category_df <- merge(x=category_df,y=cost_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_oop_category, by='category')
category_df <- merge(x=category_df,y=total_current_oop_category, by='category')
category_df <- merge(x=category_df,y=current_num_students_meeting_category, by='category')
category_df <- merge(x=category_df,y=max_cost_num_students_meeting_category, by='category')
category_df <- merge(x=category_df,y=current_num_students_sample_category, by='category')
category_df <- merge(x=category_df,y=max_cost_num_students_sample_category, by='category')
category_df$current_num_students_meeting_extrap_by_category <- (category_df$current_num_students_meeting_category / category_df$current_num_students_sample_category) * category_df$num_students_category
category_df$max_cost_num_students_meeting_extrap_by_category <- (category_df$max_cost_num_students_meeting_category / category_df$max_cost_num_students_sample_category) * category_df$num_students_category
category_df$cost_constant_total_erate_share_category <- category_df$cost_constant_total_pai_budg_category - category_df$cost_constant_total_pai_oop
category_df$bw_constant_total_erate_share_category <- category_df$bw_constant_total_pai_budg_category - category_df$bw_constant_total_pai_oop
category_df$max_cost_total_erate_share_category <- category_df$max_cost_total_pai_budg_category - category_df$max_cost_total_oop
category_df$total_erate_share_category <- category_df$district_cost_total_category - category_df$total_current_oop

#creating a per student category df
category_df_per_student <- category_df
category_df_per_student$cost_constant_total_per_student <- category_df_per_student$cost_constant_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$bw_constant_total_per_student <- category_df_per_student$bw_constant_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$max_cost_total_per_student <- category_df_per_student$max_cost_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$current_total_per_student <- category_df_per_student$district_cost_total_category / category_df_per_student$num_students_category
category_df_per_student$cost_constant_erate_per_student <- category_df_per_student$cost_constant_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$bw_constant_erate_per_student <- category_df_per_student$bw_constant_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$max_cost_erate_per_student <- category_df_per_student$max_cost_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$current_erate_per_student <- category_df_per_student$total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$cost_constant_dist_per_student <- category_df_per_student$cost_constant_total_pai_oop / category_df_per_student$num_students_category
category_df_per_student$bw_constant_dist_per_student <- category_df_per_student$bw_constant_total_pai_oop / category_df_per_student$num_students_category
category_df_per_student$max_cost_dist_per_student <- category_df_per_student$max_cost_total_oop / category_df_per_student$num_students_category
category_df_per_student$current_dist_per_student <- category_df_per_student$total_current_oop / category_df_per_student$num_students_category
category_df_per_student <- category_df_per_student[,c('category','cost_constant_total_per_student','bw_constant_total_per_student','max_cost_total_per_student',
                                                      'current_total_per_student','cost_constant_erate_per_student','bw_constant_erate_per_student',
                                                      'max_cost_erate_per_student','current_erate_per_student','cost_constant_dist_per_student',
                                                      'bw_constant_dist_per_student','max_cost_dist_per_student','current_dist_per_student')]

category_df$current_num_students_meeting_extrap <- category_df$num_students_category * current_num_students_meeting_extrap_perc
category_df$max_cost_num_students_meeting_extrap <- category_df$num_students_category * max_cost_num_students_meeting_extrap_perc

##**************************************************************************************************************************************************
#CREATING A LOCALE DF
num_students_locale <- aggregate(districts_display$num_students, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(num_students_locale) <- c('locale','num_students_locale')

cost_constant_total_pai_budg_locale <- aggregate(districts_display$cost_constant_total_pai_budj, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_budg_locale) <- c('locale','cost_constant_total_pai_budg_locale')

bw_constant_total_pai_budg_locale <- aggregate(districts_display$bw_constant_total_pai_budg, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_budg_locale) <- c('locale','bw_constant_total_pai_budg_locale')

max_cost_total_pai_budg_locale <- aggregate(districts_display$max_cost_total_pai_budg, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_total_pai_budg_locale) <- c('locale','max_cost_total_pai_budg_locale')

district_cost_total_locale <- aggregate(districts_display$district_cost_total, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(district_cost_total_locale) <- c('locale','district_cost_total_locale')

#cost_constant_total_pai_oop, bw_constant_total_pai_oop, max_cost_total_oop, total_current_oop
cost_constant_total_pai_oop_locale <- aggregate(districts_display$cost_constant_total_pai_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_oop_locale) <- c('locale','cost_constant_total_pai_oop')

bw_constant_total_pai_oop_locale <- aggregate(districts_display$bw_constant_total_pai_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_oop_locale) <- c('locale','bw_constant_total_pai_oop')

max_cost_total_oop_locale <- aggregate(districts_display$max_cost_total_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_total_oop_locale) <- c('locale','max_cost_total_oop')

total_current_oop_locale <- aggregate(districts_display$total_current_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(total_current_oop_locale) <- c('locale','total_current_oop')

#num meeting
current_num_students_meeting_locale <- aggregate(districts_display$current_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_num_students_meeting_locale) <- c('locale','current_num_students_meeting_locale')

max_cost_num_students_meeting_locale <- aggregate(districts_display$max_cost_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_meeting_locale) <- c('locale','max_cost_num_students_meeting_locale')

cost_constant_num_students_meeting_locale <- aggregate(districts_display$cost_constant_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_num_students_meeting_locale) <- c('locale','cost_constant_num_students_meeting_locale')

bw_constant_num_students_meeting_locale <- aggregate(districts_display$bw_constant_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_num_students_meeting_locale) <- c('locale','bw_constant_num_students_meeting_locale')

#num in sample
current_num_students_sample_locale <- aggregate(districts_display$current_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_num_students_sample_locale) <- c('locale','current_num_students_sample_locale')

max_cost_num_students_sample_locale <- aggregate(districts_display$max_cost_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_sample_locale) <- c('locale','max_cost_num_students_sample_locale')

cost_constant_num_students_sample_locale <- aggregate(districts_display$cost_constant_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_num_students_sample_locale) <- c('locale','cost_constant_num_students_sample_locale')

bw_constant_num_students_sample_locale <- aggregate(districts_display$bw_constant_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_num_students_sample_locale) <- c('locale','bw_constant_num_students_sample_locale')

#num districts meeting
current_districts_meeting_locale <- aggregate(districts_display$current_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_districts_meeting_locale) <- c('locale','current_districts_meeting_locale')

max_cost_districts_meeting_locale <- aggregate(districts_display$max_cost_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_districts_meeting_locale) <- c('locale','max_cost_districts_meeting_locale')

cost_constant_districts_meeting_locale <- aggregate(districts_display$cost_constant_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_districts_meeting_locale) <- c('locale','cost_constant_districts_meeting_locale')

bw_constant_districts_meeting_locale <- aggregate(districts_display$bw_constant_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_districts_meeting_locale) <- c('locale','bw_constant_districts_meeting_locale')

#num districts in sample
current_districts_sample_locale <- aggregate(districts_display$current_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_districts_sample_locale) <- c('locale','current_districts_sample_locale')

max_cost_districts_sample_locale <- aggregate(districts_display$max_cost_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_districts_sample_locale) <- c('locale','max_cost_districts_sample_locale')

cost_constant_districts_sample_locale <- aggregate(districts_display$cost_constant_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_districts_sample_locale) <- c('locale','cost_constant_districts_sample_locale')

bw_constant_districts_sample_locale <- aggregate(districts_display$bw_constant_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_districts_sample_locale) <- c('locale','bw_constant_districts_sample_locale')






#joining tables
locale_df <- merge(x=num_students_locale,y=cost_constant_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=district_cost_total_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_total_pai_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_total_pai_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_total_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=total_current_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_districts_sample_locale, by='locale')
locale_df$current_num_students_meeting_extrap_by_locale <- (locale_df$current_num_students_meeting_locale / locale_df$current_num_students_sample_locale) * locale_df$num_students_locale
locale_df$max_cost_num_students_meeting_extrap_by_locale <- (locale_df$max_cost_num_students_meeting_locale / locale_df$max_cost_num_students_sample_locale) * locale_df$num_students_locale
locale_df$cost_constant_num_students_meeting_extrap_by_locale <- (locale_df$cost_constant_num_students_meeting_locale / locale_df$cost_constant_num_students_sample_locale) * locale_df$num_students_locale
locale_df$bw_constant_num_students_meeting_extrap_by_locale <- (locale_df$bw_constant_num_students_meeting_locale / locale_df$bw_constant_num_students_sample_locale) * locale_df$num_students_locale

locale_df$current_districts_meeting_perc <- (locale_df$current_districts_meeting_locale / locale_df$current_districts_sample_locale)
locale_df$max_cost_districts_meeting_perc <- (locale_df$max_cost_districts_meeting_locale / locale_df$max_cost_districts_sample_locale)
locale_df$cost_constant_districts_meeting_perc <- (locale_df$cost_constant_districts_meeting_locale / locale_df$cost_constant_districts_sample_locale)
locale_df$bw_constant_districts_meeting_perc <- (locale_df$bw_constant_districts_meeting_locale / locale_df$bw_constant_districts_sample_locale)

locale_df$cost_constant_total_erate_share_locale <- locale_df$cost_constant_total_pai_budg_locale - locale_df$cost_constant_total_pai_oop
locale_df$bw_constant_total_erate_share_locale <- locale_df$bw_constant_total_pai_budg_locale - locale_df$bw_constant_total_pai_oop
locale_df$max_cost_total_erate_share_locale <- locale_df$max_cost_total_pai_budg_locale - locale_df$max_cost_total_oop
locale_df$total_erate_share_locale <- locale_df$district_cost_total_locale - locale_df$total_current_oop

#creating a per student category df
locale_df_per_student <- locale_df
locale_df_per_student$cost_constant_total_per_student <- locale_df_per_student$cost_constant_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_total_per_student <- locale_df_per_student$bw_constant_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_total_per_student <- locale_df_per_student$max_cost_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$current_total_per_student <- locale_df_per_student$district_cost_total_locale / locale_df_per_student$num_students_locale
locale_df_per_student$cost_constant_erate_per_student <- locale_df_per_student$cost_constant_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_erate_per_student <- locale_df_per_student$bw_constant_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_erate_per_student <- locale_df_per_student$max_cost_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$current_erate_per_student <- locale_df_per_student$total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$cost_constant_dist_per_student <- locale_df_per_student$cost_constant_total_pai_oop / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_dist_per_student <- locale_df_per_student$bw_constant_total_pai_oop / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_dist_per_student <- locale_df_per_student$max_cost_total_oop / locale_df_per_student$num_students_locale
locale_df_per_student$current_dist_per_student <- locale_df_per_student$total_current_oop / locale_df_per_student$num_students_locale
locale_df_per_student <- locale_df_per_student[,c('locale','cost_constant_total_per_student','bw_constant_total_per_student','max_cost_total_per_student',
                                                      'current_total_per_student','cost_constant_erate_per_student','bw_constant_erate_per_student',
                                                      'max_cost_erate_per_student','current_erate_per_student','cost_constant_dist_per_student',
                                                      'bw_constant_dist_per_student','max_cost_dist_per_student','current_dist_per_student')]

locale_df$current_num_students_meeting_extrap <- locale_df$num_students_locale * current_num_students_meeting_extrap_perc
locale_df$max_cost_num_students_meeting_extrap <- locale_df$num_students_locale * max_cost_num_students_meeting_extrap_perc

##**************************************************************************************************************v

#creating a rural town rich df to look at discount rates
rich_df <- districts_display
rich_df <- subset(rich_df, rich_df$category == 'Rural_Town_Rich')
rich_students_df <- aggregate(rich_df$num_students, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_students_df) <- c('Adj C1 Discount Rate', 'Num Students')
rich_budget_pai_df <- aggregate(rich_df$district_budget_pai, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_budget_pai_df) <- c('Adj C1 Discount Rate', 'Pai Budget')
rich_budget_current_df <- aggregate(rich_df$district_cost_total, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_budget_current_df) <- c('Adj C1 Discount Rate', 'Current Budget')
rich_summary_df <- merge(x=rich_students_df, y=rich_budget_pai_df, by = 'Adj C1 Discount Rate')
rich_summary_df <- merge(x=rich_summary_df, y=rich_budget_current_df, by = 'Adj C1 Discount Rate')
rich_summary_df$pai_erate_share <- .75 * rich_summary_df$`Pai Budget`
rich_summary_df$current_erate_share <- (1-rich_summary_df$`Adj C1 Discount Rate`) * rich_summary_df$`Current Budget`


rich_c2_df <- aggregate(rich_df$num_students, by=list(rich_df$adjusted_c2), FUN = sum)

##**************************************************************************************************************v
#creating a Totals DF
#totals budget
num_students <- sum(districts_display$num_students, na.rm = TRUE)

current_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                     districts_display$include_in_universe_of_districts == TRUE &
                                                                     districts_display$ia_bandwidth_per_student_kbps >= 100], na.rm = TRUE)
current_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                    districts_display$include_in_universe_of_districts == TRUE], na.rm = TRUE)

current_num_students_meeting_extrap_perc <- current_num_students_meeting / current_num_students_sample

current_num_students_meeting_extrap <- current_num_students_meeting_extrap_perc * num_students


##max cost extraps
max_cost_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                      districts_display$include_in_universe_of_districts == TRUE &
                                                                      districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                      districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                      districts_display$max_cost_bandwidth_per_student >= 100], na.rm = TRUE)

max_cost_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                      districts_display$include_in_universe_of_districts == TRUE &
                                                                      districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                      districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

max_cost_num_students_meeting_extrap_perc <- max_cost_num_students_meeting / max_cost_num_students_sample

##cost constant extraps
cost_constant_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                      districts_display$include_in_universe_of_districts == TRUE &
                                                                      districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                      districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                      districts_display$cost_constant_bandwidth_per_student >= 100], na.rm = TRUE)

cost_constant_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                     districts_display$include_in_universe_of_districts == TRUE &
                                                                     districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                     districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

cost_constant_num_students_meeting_extrap_perc <- cost_constant_num_students_meeting / cost_constant_num_students_sample

##bw constant extraps
bw_constant_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                           districts_display$include_in_universe_of_districts == TRUE &
                                                                           districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                           districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                           districts_display$bw_constant_bandwidth_per_student >= 100], na.rm = TRUE)

bw_constant_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                          districts_display$include_in_universe_of_districts == TRUE &
                                                                          districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                          districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

bw_constant_num_students_meeting_extrap_perc <- bw_constant_num_students_meeting / bw_constant_num_students_sample



#

cost_constant_total_pai_budg <- sum(districts_display$cost_constant_total_pai_budj, na.rm = TRUE)
bw_constant_total_pai_budg <- sum(districts_display$bw_constant_total_pai_budg, na.rm = TRUE)
max_cost_total_pai_budg <- sum(districts_display$max_cost_total_pai_budg, na.rm = TRUE)
district_cost_total <- sum(districts_display$district_cost_total, na.rm = TRUE)
current_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$ia_bandwidth_per_student_kbps >= 100])
current_districts_meeting_perc <- current_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
cost_constant_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$cost_constant_bandwidth_per_student >= 100])
cost_constant_districts_meeting_perc <- cost_constant_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
bw_constant_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$bw_constant_bandwidth_per_student >= 100])
bw_constant_districts_meeting_perc <- bw_constant_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
max_cost_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$max_cost_bandwidth_per_student >= 100])
max_cost_districts_meeting_perc <- max_cost_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])


#totals oop
cost_constant_total_pai_oop <- sum(districts_display$cost_constant_total_pai_oop, na.rm = TRUE)
bw_constant_total_pai_oop <- sum(districts_display$bw_constant_total_pai_oop, na.rm = TRUE)
max_cost_total_oop <- sum(districts_display$max_cost_total_oop, na.rm = TRUE)
total_current_oop <- sum(districts_display$total_current_oop, na.rm = TRUE)


#joining tables
totals_df <- data.frame(num_students, cost_constant_total_pai_budg,bw_constant_total_pai_budg,max_cost_total_pai_budg,district_cost_total,
                        cost_constant_total_pai_oop,bw_constant_total_pai_oop,max_cost_total_oop,total_current_oop)
totals_df$cost_constant_total_erate_share <- totals_df$cost_constant_total_pai_budg - totals_df$cost_constant_total_pai_oop
totals_df$bw_constant_total_erate_share_category <- totals_df$bw_constant_total_pai_budg - totals_df$bw_constant_total_pai_oop
totals_df$max_cost_total_erate_share_category <- totals_df$max_cost_total_pai_budg - totals_df$max_cost_total_oop
totals_df$total_erate_share_category <- totals_df$district_cost_total - totals_df$total_current_oop



#creating a per student totals df
totals_df_per_student <- totals_df
totals_df_per_student$cost_constant_total_per_student <- totals_df_per_student$cost_constant_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$bw_constant_total_per_student <- totals_df_per_student$bw_constant_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$max_cost_total_per_student <- totals_df_per_student$max_cost_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$current_total_per_student <- totals_df_per_student$district_cost_total / totals_df_per_student$num_students
totals_df_per_student$cost_constant_erate_per_student <- totals_df_per_student$cost_constant_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$bw_constant_erate_per_student <- totals_df_per_student$bw_constant_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$max_cost_erate_per_student <- totals_df_per_student$max_cost_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$current_erate_per_student <- totals_df_per_student$total_erate_share / totals_df_per_student$num_students
totals_df_per_student$cost_constant_dist_per_student <- totals_df_per_student$cost_constant_total_pai_oop / totals_df_per_student$num_students
totals_df_per_student$bw_constant_dist_per_student <- totals_df_per_student$bw_constant_total_pai_oop / totals_df_per_student$num_students
totals_df_per_student$max_cost_dist_per_student <- totals_df_per_student$max_cost_total_oop / totals_df_per_student$num_students
totals_df_per_student$current_dist_per_student <- totals_df_per_student$total_current_oop / totals_df_per_student$num_students

##************************************************************************************************************************
#Creating the summary tables by model and locale
models <- c('Today', 'Pai OOP', 'Same OOP', 'Pay to Keep BW')
locales <- locale_df$locale
locales_and_models <- NULL
                                      


for(i in 1:length(locales)) {
  for(j in 1:length(models)) {
    #locales_and_models = paste(locales[i], models[j], sep=' ')
    locales_and_models <- append(locales_and_models,paste(locales[i], models[j], sep=' - '))
  }
}

locales_and_models <- paste(rep(locale_df$locale, 4), c(rep("Today",4), rep("Pai_OOP",4), rep("Keep_BW",4), rep("Same_OOP",4)), sep="-")
summary_df <- data.frame(locales_and_models,
                         "total_funding"=c(locale_df$district_cost_total_locale, locale_df$cost_constant_total_pai_budg_locale,
                                           locale_df$bw_constant_total_pai_budg_locale, locale_df$max_cost_total_pai_budg_locale),
                         "erate_funding"=c(locale_df$district_cost_total_locale - locale_df$total_current_oop, 
                                           locale_df$cost_constant_total_erate_share_locale,
                                           locale_df$bw_constant_total_erate_share_locale,
                                           locale_df$max_cost_total_erate_share_locale),
                         "district_portion"=c(locale_df$total_current_oop, locale_df$cost_constant_total_pai_oop,
                                           locale_df$bw_constant_total_pai_oop, locale_df$max_cost_total_oop),
                         "students_meeting_goals_extrap"=c(locale_df$current_num_students_meeting_extrap_by_locale, 
                                                           locale_df$cost_constant_num_students_meeting_extrap_by_locale,
                                                           locale_df$bw_constant_num_students_meeting_extrap_by_locale, 
                                                           locale_df$max_cost_num_students_meeting_extrap_by_locale),
                         "total_funding_per_student"=c(locale_df_per_student$current_total_per_student, 
                                                       locale_df_per_student$cost_constant_total_per_student,
                                                       locale_df_per_student$bw_constant_total_per_student, 
                                                       locale_df_per_student$max_cost_total_per_student),
                         "erate_funding_per_student"=c(locale_df_per_student$current_erate_per_student, 
                                                       locale_df_per_student$cost_constant_erate_per_student,
                                                       locale_df_per_student$bw_constant_erate_per_student, 
                                                       locale_df_per_student$max_cost_erate_per_student),
                         "district_portion_per_student"=c(locale_df_per_student$current_dist_per_student, 
                                                       locale_df_per_student$cost_constant_dist_per_student,
                                                       locale_df_per_student$bw_constant_dist_per_student, 
                                                       locale_df_per_student$max_cost_dist_per_student),
                         "districts_meeting"=c(locale_df$current_districts_meeting_perc, 
                                               locale_df$cost_constant_districts_meeting_perc,
                                               locale_df$bw_constant_districts_meeting_perc, 
                                               locale_df$max_cost_districts_meeting_perc)
                         )


current_extrap_students_meeting <- sum(locale_df$current_num_students_meeting_extrap_by_locale)
cost_constant_extrap_students_meeting <- sum(locale_df$cost_constant_num_students_meeting_extrap_by_locale)
bw_constant_extrap_students_meeting <- sum(locale_df$bw_constant_num_students_meeting_extrap_by_locale)
max_cost_extrap_students_meeting <- sum(locale_df$max_cost_num_students_meeting_extrap_by_locale)

models <- c('Today', 'Pai OOP', 'Pay to Keep BW','Same OOP')
summary_models_total_df <- data.frame(models,
                                      "total_funding" = c(totals_df$district_cost_total,
                                                          totals_df$cost_constant_total_pai_budg,
                                                          totals_df$bw_constant_total_pai_budg,
                                                          totals_df$max_cost_total_pai_budg),
                                      "erate_funding" = c(totals_df$total_erate_share_category,
                                                          totals_df$cost_constant_total_erate_share,
                                                          totals_df$bw_constant_total_erate_share_category,
                                                          totals_df$max_cost_total_erate_share_category),
                                      "district_portion" = c(totals_df$total_current_oop,
                                                          totals_df$cost_constant_total_pai_oop,
                                                          totals_df$bw_constant_total_pai_oop,
                                                          totals_df$max_cost_total_oop),
                                      "total_funding_per_student" = c(totals_df_per_student$current_total_per_student,
                                                                      totals_df_per_student$cost_constant_total_per_student,
                                                                      totals_df_per_student$bw_constant_total_per_student,
                                                                      totals_df_per_student$max_cost_total_per_student),
                                      "erate_funding_per_student" = c(totals_df_per_student$current_erate_per_student,
                                                                      totals_df_per_student$cost_constant_erate_per_student,
                                                                      totals_df_per_student$bw_constant_erate_per_student,
                                                                      totals_df_per_student$max_cost_erate_per_student),
                                      "district_portion_per_student" = c(totals_df_per_student$current_dist_per_student,
                                                                      totals_df_per_student$cost_constant_dist_per_student,
                                                                      totals_df_per_student$bw_constant_dist_per_student,
                                                                      totals_df_per_student$max_cost_dist_per_student),
                                      "districts_meeting" = c(current_districts_meeting_perc,
                                                              cost_constant_districts_meeting_perc,
                                                              bw_constant_districts_meeting_perc,
                                                              max_cost_districts_meeting_perc),
                                      "students_meeting_goals_extrap" = c(current_extrap_students_meeting,
                                                                          cost_constant_extrap_students_meeting,
                                                                          bw_constant_extrap_students_meeting,
                                                                          max_cost_extrap_students_meeting)
                                      )


#adding extrapoloated current num students meeting to districts display
locale_df$current_num_students_meeting_extrap_perc <- (locale_df$current_num_students_meeting_locale / locale_df$current_num_students_sample_locale)
districts_display$current_num_students_meeting_extrap_perc <- ifelse(districts_display$locale == 'Rural', locale_df[1,'current_num_students_meeting_extrap_perc'],
                                                                     ifelse(districts_display$locale == 'Suburban', locale_df[2,'current_num_students_meeting_extrap_perc'], 
                                                                            ifelse(districts_display$locale == 'Town', locale_df[3,'current_num_students_meeting_extrap_perc'],
                                                                                   locale_df[4,'current_num_students_meeting_extrap_perc'])))
districts_display$current_num_students_meeting_extrap <- districts_display$current_num_students_meeting_extrap_perc * districts_display$num_students


#max cost
locale_df$max_cost_num_students_meeting_extrap_perc <- (locale_df$max_cost_num_students_meeting_locale / locale_df$max_cost_num_students_sample_locale)

districts_display$max_cost_num_students_meeting_extrap_perc <- ifelse(districts_display$locale == 'Rural', locale_df[1,'max_cost_num_students_meeting_extrap_perc'],
                                                                     ifelse(districts_display$locale == 'Suburban', locale_df[2,'max_cost_num_students_meeting_extrap_perc'], 
                                                                            ifelse(districts_display$locale == 'Town', locale_df[3,'max_cost_num_students_meeting_extrap_perc'],
                                                                                   locale_df[4,'max_cost_num_students_meeting_extrap_perc'])))

districts_display$max_cost_num_students_meeting_extrap <- districts_display$max_cost_num_students_meeting_extrap_perc * districts_display$num_students

districts_display$total_current_erate_share <-districts_display$district_cost_total - districts_display$total_current_oop

#************************************************************************************************
#creating new summary tables for service provider analysis

districts_sub_display <- data.table(districts_display[,c('postal_cd','locale','total_current_oop','total_current_erate_share','district_cost_total','num_students','current_num_students_meeting_extrap','max_cost_total_oop','max_cost_total_erate_share','max_cost_total_pai_budg','max_cost_num_students_meeting','bw_constant_total_pai_oop','current_districts_meeting','current_districts_sample')])

districts_sum_display <- districts_sub_display[, lapply(.SD,sum), by=c('postal_cd','locale')]
districts_sum_display <- districts_sub_display[, lapply(.SD,sum), by=c('postal_cd','locale')]

districts_sum_display$avg_total_funding_per_student <- districts_sum_display$district_cost_total/districts_sum_display$num_students
districts_sum_display$avg_total_funding_per_student <- districts_sum_display$total_current_erate_share/districts_sum_display$num_students
districts_sum_display$current_districts_meeting_goals_perc <- districts_sum_display$current_districts_meeting/districts_sum_display$current_districts_sample
districts_sum_display$avg_max_cost_total_funding_per_student <- districts_sum_display$max_cost_total_pai_budg/districts_sum_display$num_students
districts_sum_display$avg_max_cost_erate_funding_per_student <- districts_sum_display$max_cost_total_erate_share/districts_sum_display$num_students
districts_sum_display$max_cost_districts_meeting_goals_perc <- districts_sum_display$current_districts_meeting/districts_sum_display$current_districts_sample

sub <- districts_display[,c('esh_id','postal_cd','locale','num_students','total_current_oop','total_current_erate_share','district_cost_total','current_num_students_meeting_extrap','max_cost_total_oop','max_cost_total_erate_share','max_cost_total_pai_budg','max_cost_num_students_meeting_extrap')]
service_providers <- merge(x= service_providers,y = sub, by = 'esh_id')

#dropping service providers that have $0 in total spend
service_providers <- service_providers[!(service_providers$total_spend==0),]

service_providers$max_cost_percent_funding_lost <- (service_providers$max_cost_total_pai_budg - service_providers$district_cost_total)/service_providers$district_cost_total
service_providers$total_funding_change <- service_providers$max_cost_percent_funding_lost * service_providers$total_spend
service_providers$monthly_funding_change <- service_providers$max_cost_percent_funding_lost * service_providers$monthly_spend

service_providers_sub_display <- data.table(service_providers[,c('reporting_name','postal_cd.x','locale','total_spend','total_funding_change','monthly_spend','total_clean_spend','monthly_clean_spend','dedicated_bandwidth_mbps','clean_dedicated_bandwidth_mbps','monthly_funding_change','current_num_students_meeting_extrap','max_cost_num_students_meeting_extrap','purpose')])
service_providers_sum_display <- service_providers_sub_display[, lapply(.SD,sum), by=c('reporting_name'), .SDcols = ! c('locale', 'postal_cd.x','purpose')]
service_providers_sum_display_by_locale <- service_providers_sub_display[, lapply(.SD,sum), by=c('reporting_name','locale'), .SDcols = ! c('postal_cd.x','purpose')]
service_providers_sum_display_by_state <- service_providers_sub_display[, lapply(.SD,sum), by=c('reporting_name','postal_cd.x'), .SDcols = ! c('locale','purpose')]
service_providers_sum_display_by_locale_and_state <- service_providers_sub_display[, lapply(.SD,sum), by=c('reporting_name','postal_cd.x','locale'), .SDcols = ! c('purpose')]

#************************************************************************************************
#creating an extrapolation table for service provider analysis

#by purpose
service_providers_ia <- service_providers[service_providers$purpose == 'Internet Access',]
service_providers_clean_ia <- aggregate(service_providers_ia$total_clean_spend, by=list(service_providers_ia$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_ia) <- c('reporting_name','total_clean_ia_spend')

service_providers_wan <- service_providers[service_providers$purpose == 'WAN',]
service_providers_clean_wan <- aggregate(service_providers_wan$total_clean_spend, by=list(service_providers_wan$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_wan) <- c('reporting_name','total_clean_wan_spend')

service_providers_ia_and_wan <- service_providers
service_providers_clean_ia_and_wan <- aggregate(service_providers_ia_and_wan$total_clean_spend, by=list(service_providers_ia_and_wan$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_ia_and_wan) <- c('reporting_name','total_clean_spend')

service_providers_extrap <- merge(x = service_providers_clean_ia, y = service_providers_clean_wan, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_ia_and_wan, by = 'reporting_name', all = TRUE)
service_providers_extrap[is.na(service_providers_extrap)] <- 0

service_providers_extrap$clean_ia_perc <- service_providers_extrap$total_clean_ia_spend / service_providers_extrap$total_clean_spend
service_providers_extrap$clean_wan_perc <- service_providers_extrap$total_clean_wan_spend / service_providers_extrap$total_clean_spend

#creating national averages to replace NaN
national_average_ia_perc <- sum(service_providers_extrap$total_clean_ia_spend) / sum(service_providers_extrap$total_clean_spend)
national_average_wan_perc <- sum(service_providers_extrap$total_clean_wan_spend) / sum(service_providers_extrap$total_clean_spend)

#replacing NaNs with national averages
service_providers_extrap[is.nan(service_providers_extrap$clean_ia_perc),c('clean_ia_perc')] <- national_average_ia_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_wan_perc),c('clean_wan_perc')] <- national_average_wan_perc

service_providers_extrap <- service_providers_extrap[,c('reporting_name','clean_ia_perc','clean_wan_perc')]

#by connect category. This should be the way to do it, but for now just manually writing them out
#connect_categories <- unique(service_providers$connect_category)
#for(i in 1:length(connect_categories)){
#  print(connect_categories[i])
#}

service_providers$connect_category_summary <- ifelse(service_providers$connect_category %in% c('Lit Fiber', 'Dark Fiber'),
                                                     'Fiber',
                                                     ifelse(service_providers$connect_category == 'ISP Only',
                                                            'ISP',
                                                            'Non-Fiber')
                                                      )

service_providers_fiber <- service_providers[service_providers$connect_category_summary == 'Fiber',]
service_providers_clean_fiber <- aggregate(service_providers_fiber$total_clean_spend, by=list(service_providers_fiber$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_fiber) <- c('reporting_name','total_clean_fiber_spend')

service_providers_isp <- service_providers[service_providers$connect_category_summary == 'ISP',]
service_providers_clean_isp <- aggregate(service_providers_isp$total_clean_spend, by=list(service_providers_isp$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_isp) <- c('reporting_name','total_clean_isp_spend')

service_providers_nonfiber <- service_providers[service_providers$connect_category_summary == 'Non-Fiber',]
service_providers_clean_nonfiber <- aggregate(service_providers_nonfiber$total_clean_spend, by=list(service_providers_nonfiber$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_nonfiber) <- c('reporting_name','total_clean_nonfiber_spend')

service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_fiber, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_isp, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_nonfiber, by = 'reporting_name', all = TRUE)
service_providers_extrap[is.na(service_providers_extrap)] <- 0

service_providers_extrap$total_clean__spend <- service_providers_extrap$total_clean_fiber_spend + service_providers_extrap$total_clean_isp_spend + service_providers_extrap$total_clean_nonfiber_spend
service_providers_extrap$clean_fiber_perc <- service_providers_extrap$total_clean_fiber_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_isp_perc <- service_providers_extrap$total_clean_isp_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_nonfiber_perc <- service_providers_extrap$total_clean_nonfiber_spend / service_providers_extrap$total_clean__spend

#creating national averages to replace NaN
national_average_fiber_perc <- sum(service_providers_extrap$total_clean_fiber_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_isp_perc <- sum(service_providers_extrap$total_clean_isp_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_nonfiber_perc <- sum(service_providers_extrap$total_clean_nonfiber_spend) / sum(service_providers_extrap$total_clean__spend)

#replacing NaNs with national averages
service_providers_extrap[is.nan(service_providers_extrap$clean_fiber_perc),c('clean_fiber_perc')] <- national_average_fiber_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_isp_perc),c('clean_isp_perc')] <- national_average_isp_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_nonfiber_perc),c('clean_nonfiber_perc')] <- national_average_nonfiber_perc

service_providers_extrap <- service_providers_extrap[,c('reporting_name','clean_ia_perc','clean_wan_perc','clean_fiber_perc','clean_isp_perc','clean_nonfiber_perc')]

#************************************************************************************************
#joining clean ia and wan percent into sum_display
service_providers_sum_display <- merge(x = service_providers_sum_display, y = service_providers_extrap, by='reporting_name', all = TRUE)
service_providers_sum_display$extrap_ia_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_ia_perc
service_providers_sum_display$extrap_wan_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_wan_perc
service_providers_sum_display$extrap_ia_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_ia_perc
service_providers_sum_display$extrap_wan_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_wan_perc
service_providers_sum_display$extrap_fiber_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_fiber_perc
service_providers_sum_display$extrap_isp_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_isp_perc
service_providers_sum_display$extrap_nonfiber_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_nonfiber_perc
service_providers_sum_display$extrap_fiber_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_fiber_perc
service_providers_sum_display$extrap_isp_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_isp_perc
service_providers_sum_display$extrap_nonfiber_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_nonfiber_perc

service_providers_sum_display$extrap_cost_per_mbps <- service_providers_sum_display$extrap_ia_spend / service_providers_sum_display$dedicated_bandwidth_mbps
service_providers_sum_display$extrap_bandwidth_change_gbps <- service_providers_sum_display$extrap_ia_change / service_providers_sum_display$extrap_cost_per_mbps / 1000

#ordering by funding change
service_providers_sum_display <- service_providers_sum_display[with(service_providers_sum_display, order(total_funding_change))]
top_15 <- as.vector(service_providers_sum_display[1:15,c('reporting_name')])
top_15

#top 15 sp by funding change
#service_providers_sum_display_by_locale <- service_providers_sum_display_by_locale[service_providers_sum_display_by_locale$reporting_name %in% top_15$reporting_name]
#service_providers_sum_display_by_state <- service_providers_sum_display_by_state[service_providers_sum_display_by_state$reporting_name %in% top_15$reporting_name]

#top 15 sp by purpose
#service_providers_sum_display_by_purpose <- service_providers_sub_display[, lapply(.SD,sum), by=c('reporting_name'), .SDcols = ! c('locale', 'postal_cd.x','purpose')]
#service_providers_sum_display_by_purpose <- service_providers_sum_display_by_purpose[service_providers_sum_display_by_purpose$reporting_name %in% top_15$reporting_name]


write.csv(districts_display, "data/interim/districts_display.csv", row.names = FALSE)
write.csv(category_df_per_student, "data/interim/pai_analysis_per_student_spending.csv", row.names = FALSE)
write.csv(category_df, "data/interim/pai_analysis_category_spending.csv", row.names = FALSE)
write.csv(totals_df, "data/interim/pai_analysis_total_spending.csv", row.names = FALSE)
write.csv(totals_df_per_student, "data/interim/pai_analysis_total_per_student_spending.csv", row.names = FALSE)
write.csv(locale_df, "data/interim/locale_df.csv", row.names = FALSE)
write.csv(locale_df_per_student, "data/interim/locale_df_per_student.csv", row.names = FALSE)
write.csv(summary_df, "data/interim/summary_df.csv", row.names = FALSE)
write.csv(summary_models_total_df, "data/interim/summary_models_total_df.csv", row.names = FALSE)
write.csv(service_providers_sum_display, "data/interim/service_providers_sum_display.csv", row.names = FALSE)
write.csv(service_providers_sum_display_by_locale, "data/interim/service_providers_sum_display_by_locale.csv", row.names = FALSE)
write.csv(service_providers_sum_display_by_state, "data/interim/service_providers_sum_display_by_state.csv", row.names = FALSE)
