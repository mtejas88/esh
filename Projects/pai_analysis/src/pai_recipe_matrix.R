# clear the console
cat("\014")
# remove every object in the environment
rm(list = ls())
#install and load packages
lib <- c( "plyr","data.table")
sapply(lib, function(x) require(x, character.only = TRUE))
options(scipen=999)
#import data
districts_display <- read.csv("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/Pai Recipe/2016_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##Assuming Districts Won't Pay More

#e-rate funding for C1
c1 <- 1364343502

#e-rate funding for C2
districts_display$adjusted_c2 <- ifelse(is.na(districts_display$discount_rate_c2), mean(districts_display$discount_rate_c2, na.rm=T), districts_display$discount_rate_c2)
c2 <- sum((30 * districts_display$adjusted_c2) * (districts_display$num_students))

total_funds <- c1+c2

#e-rate funding for IA
ia_total_funds <-  583053227

#e-rate funding for WAN
wan_total_funds <- c1 - ia_total_funds

#student counts
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

#weights
weight_rural_town_rich <- 1.5 * (1/9.75)
weight_rural_town_middleclass <- 2 * (1/9.75)
weight_rural_town_poor <- 3 * (1/9.75)
weight_urban_suburban_rich <- .75 * (1/9.75)
weight_urban_suburban_middleclass <- 1 * (1/9.75)
weight_urban_suburban_poor <- 1.5 * (1/9.75)

#dollars per student
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





#ia dollars per student
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



#ia budget
districts_display$ia_district_budget_pai <- ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                   & districts_display$adj_c1_discount_rate >= .8,
                                                   1.33*ia_urban_suburban_poor_dollars_per_student*districts_display$num_students,
                                                   
                                                   ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                          & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <= .7,
                                                          1.33*ia_urban_suburban_middleclass_dollars_per_student*districts_display$num_students,
                                                          
                                                          ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                                 & districts_display$adj_c1_discount_rate <= .4,
                                                                 1.33*ia_urban_suburban_rich_dollars_per_student*districts_display$num_students,
                                                                 
                                                                 ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                        & districts_display$adj_c1_discount_rate >= .8,
                                                                        1.33*ia_rural_town_poor_dollars_per_student*districts_display$num_students,
                                                                        
                                                                        ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                               & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                                 .7,
                                                                               1.33*ia_rural_town_middleclass_dollars_per_student*districts_display$num_students,
                                                                               
                                                                               ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                                      & districts_display$adj_c1_discount_rate <= .4,
                                                                                      1.33*ia_rural_town_rich_dollars_per_student*districts_display$num_students, "NA"))))))



districts_display$ia_yearly_district_cost_total <- (districts_display$ia_monthly_cost_total*12)


districts_display$ia_current_oop <- (1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)


districts_display$ia_pai_oop <- ifelse(districts_display$ia_yearly_district_cost_total/as.numeric(districts_display$ia_district_budget_pai)>1,
                                    (districts_display$ia_yearly_district_cost_total-(as.numeric(districts_display$ia_district_budget_pai)/1.33)), .25*districts_display$ia_yearly_district_cost_total)   

districts_display$ia_cant_afford_pai_budj <- ifelse (3*(districts_display$ia_current_oop)<districts_display$ia_district_budget_pai,
                                                  4*(districts_display$ia_current_oop),districts_display$ia_district_budget_pai)



districts_display$ia_pai_monthly_budget <- (as.numeric(districts_display$ia_district_budget_pai)/12)

districts_display$ia_pai_bandwidth_per_student <- (((as.numeric(districts_display$ia_cant_afford_pai_budj)/12)/districts_display$ia_monthly_cost_per_mbps)*1000)/(districts_display$num_students)


#overall budget
districts_display$district_cost_total <- (districts_display$ia_monthly_cost_total*12)+(districts_display$wan_monthly_cost_total*12)+(30*districts_display$num_students)



districts_display$district_budget_pai <-  as.numeric(ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                 & districts_display$adj_c1_discount_rate >= .8,
                                                 1.33*urban_suburban_poor_dollars_per_student*districts_display$num_students,
                                                 
                                                 ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                        & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <= .7,
                                                        1.33*urban_suburban_middleclass_dollars_per_student*districts_display$num_students,
                                                        
                                                        ifelse((districts_display$locale == 'Urban'| districts_display$locale == 'Suburban')
                                                               & districts_display$adj_c1_discount_rate <= .4,
                                                               1.33*urban_suburban_rich_dollars_per_student*districts_display$num_students,
                                                               
                                                               ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                      & districts_display$adj_c1_discount_rate >= .8,
                                                                      1.33*rural_town_poor_dollars_per_student*districts_display$num_students,
                                                                      
                                                                      ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                             & districts_display$adj_c1_discount_rate >=.5 & districts_display$adj_c1_discount_rate <=
                                                                               .7,
                                                                             1.33*rural_town_middleclass_dollars_per_student*districts_display$num_students,
                                                                             
                                                                             ifelse((districts_display$locale == 'Rural'|districts_display$locale == 'Town')
                                                                                    & districts_display$adj_c1_discount_rate <= .4,
                                                                                    1.33*rural_town_rich_dollars_per_student*districts_display$num_students, "NA")))))))


      
districts_display$pai_oop <- ifelse(districts_display$district_cost_total/(districts_display$district_budget_pai)>1,
                                    (districts_display$district_cost_total-(districts_display$district_budget_pai/1.33)), .25*districts_display$district_cost_total)                                 

districts_display$current_oop <- (((1-districts_display$adjusted_c2)*(30*districts_display$num_students)) + 
  ((1-districts_display$adj_c1_discount_rate)*(districts_display$ia_monthly_cost_total*12)) + ((1-districts_display$adj_c1_discount_rate)*(districts_display$wan_monthly_cost_total*12)))




districts_display$pai_vs_current_oop <- ifelse ((districts_display$pai_oop>districts_display$current_oop),"Higher New OOP", "Not Higher New OOP")

districts_display$cant_afford_pai_budj <- ifelse (4*(districts_display$current_oop)<districts_display$district_budget_pai,
                                                  4*(districts_display$current_oop),districts_display$district_budget_pai)

##Assuming districts will pay more

districts_display$ia_oop_under_pai_same_svcs <- districts_display$ia_yearly_district_cost_total/4
districts_display$ia_total_cost_pai_oop_current_framework <- districts_display$ia_oop_under_pai_same_svcs / (1-districts_display$adj_c1_discount_rate)
districts_display$ia_bw_pai_oop_current_framework <- districts_display$ia_total_cost_pai_oop_current_framework / (districts_display$ia_monthly_cost_per_mbps*12)

#export district data  
write.csv(districts_display, "C:/Users/Justine/Documents/GitHub/ficher/Projects/pai_analysis/data/interim/pai_analysis_districts_grouped.csv")
