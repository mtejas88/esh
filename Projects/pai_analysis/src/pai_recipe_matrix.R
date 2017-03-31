# clear the console
cat("\014")

# remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c( "plyr","data.table")
sapply(lib, function(x) require(x, character.only = TRUE))

options(scipen=999)


wd <- "~/Documents/Analysis"
setwd(wd)

districts_display <- read.csv("2016_districts.csv", as.is=T, header=T, stringsAsFactors=F)

#might want to add the total voice $

#e-rate funding for C1 (does not include voice)
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

#ia_current_oop is districts share of their total cost
districts_display$ia_current_oop <- (1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)

##**************************************************************************************************************************************************

#TOTAL FUNDING

districts_display$district_cost_total <- (districts_display$ia_monthly_cost_total*12)+(districts_display$wan_monthly_cost_total*12)+(30*districts_display$num_students)



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

districts_display$total_current_oop <- (((1-districts_display$adjusted_c2)*(30*districts_display$num_students)) + 
                                          ((1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)) + 
                                          ((1-districts_display$adj_c1_discount_rate)*(districts_display$wan_monthly_cost_total*12)))

##**************************************************************************************************************************************************
#MAXIMIZED COST
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

#BW CONSTANT

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

#COST CONSTANT
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



#joining tables
category_df <- merge(x=num_students_category,y=cost_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=district_cost_total_category, by='category')
category_df <- merge(x=category_df,y=cost_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_oop_category, by='category')
category_df <- merge(x=category_df,y=total_current_oop_category, by='category')
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


write.csv(districts_display, "pai_analysis_districts_max_spending.csv", row.names = FALSE)
write.csv(category_df_per_student, "pai_analysis_per_student_spending.csv", row.names = FALSE)
write.csv(category_df, "pai_analysis_category_spending.csv", row.names = FALSE)
write.csv(totals_df, "pai_analysis_total_spending.csv", row.names = FALSE)
write.csv(totals_df_per_student, "pai_analysis_total_per_student_spending.csv", row.names = FALSE)