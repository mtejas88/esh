## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

# remove every object in the environment
rm(list = ls())

##**************************************************************************************************************************************************
## read in data
districts_display <- read.csv("data/interim/districts_display.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
total_funding_by_district <- read.csv("data/raw/2016_total_funding_by_district.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

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
#Merging tables, and creating TODAY model

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


write.csv(districts_display, "data/interim/districts_display_part2.csv", row.names = FALSE)
