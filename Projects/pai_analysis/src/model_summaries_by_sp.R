## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

# remove every object in the environment
rm(list = ls())

##**************************************************************************************************************************************************
## read in data
districts_display <- read.csv("data/processed/districts_display.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
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
                                                            service_providers$connect_category)
)

service_providers_fiber <- service_providers[service_providers$connect_category_summary == 'Fiber',]
service_providers_clean_fiber <- aggregate(service_providers_fiber$total_clean_spend, by=list(service_providers_fiber$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_fiber) <- c('reporting_name','total_clean_fiber_spend')

service_providers_isp <- service_providers[service_providers$connect_category_summary == 'ISP',]
service_providers_clean_isp <- aggregate(service_providers_isp$total_clean_spend, by=list(service_providers_isp$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_isp) <- c('reporting_name','total_clean_isp_spend')

service_providers_t1 <- service_providers[service_providers$connect_category_summary == 'T-1',]
service_providers_clean_t1 <- aggregate(service_providers_t1$total_clean_spend, by=list(service_providers_t1$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_t1) <- c('reporting_name','total_clean_t1_spend')

service_providers_dsl <- service_providers[service_providers$connect_category_summary == 'DSL',]
service_providers_clean_dsl <- aggregate(service_providers_dsl$total_clean_spend, by=list(service_providers_dsl$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_dsl) <- c('reporting_name','total_clean_dsl_spend')

service_providers_fixed_wireless <- service_providers[service_providers$connect_category_summary == 'Fixed Wireless',]
service_providers_clean_fixed_wireless <- aggregate(service_providers_fixed_wireless$total_clean_spend, by=list(service_providers_fixed_wireless$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_fixed_wireless) <- c('reporting_name','total_clean_fixed_wireless_spend')

service_providers_cable <- service_providers[service_providers$connect_category_summary == 'Cable',]
service_providers_clean_cable <- aggregate(service_providers_cable$total_clean_spend, by=list(service_providers_cable$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_cable) <- c('reporting_name','total_clean_cable_spend')

service_providers_other <- service_providers[service_providers$connect_category_summary %in% c('Other Copper','Uncategorized','Satellite/LTE'),]
service_providers_clean_other <- aggregate(service_providers_other$total_clean_spend, by=list(service_providers_other$reporting_name), FUN = sum, na.rm = TRUE)
names(service_providers_clean_other) <- c('reporting_name','total_clean_other_spend')

service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_fiber, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_isp, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_t1, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_dsl, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_fixed_wireless, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_cable, by = 'reporting_name', all = TRUE)
service_providers_extrap <- merge(x = service_providers_extrap, y = service_providers_clean_other, by = 'reporting_name', all = TRUE)
service_providers_extrap[is.na(service_providers_extrap)] <- 0

service_providers_extrap$total_clean__spend <- service_providers_extrap$total_clean_fiber_spend + service_providers_extrap$total_clean_isp_spend + 
    service_providers_extrap$total_clean_t1_spend + service_providers_extrap$total_clean_dsl_spend + service_providers_extrap$total_clean_fixed_wireless_spend + 
    service_providers_extrap$total_clean_cable_spend + service_providers_extrap$total_clean_other_spend
service_providers_extrap$clean_fiber_perc <- service_providers_extrap$total_clean_fiber_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_isp_perc <- service_providers_extrap$total_clean_isp_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_t1_perc <- service_providers_extrap$total_clean_t1_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_dsl_perc <- service_providers_extrap$total_clean_dsl_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_fixed_wireless_perc <- service_providers_extrap$total_clean_fixed_wireless_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_cable_perc <- service_providers_extrap$total_clean_cable_spend / service_providers_extrap$total_clean__spend
service_providers_extrap$clean_other_perc <- service_providers_extrap$total_clean_other_spend / service_providers_extrap$total_clean__spend

#creating national averages to replace NaN
national_average_fiber_perc <- sum(service_providers_extrap$total_clean_fiber_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_isp_perc <- sum(service_providers_extrap$total_clean_isp_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_t1_perc <- sum(service_providers_extrap$total_clean_t1_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_dsl_perc <- sum(service_providers_extrap$total_clean_dsl_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_fixed_wireless_perc <- sum(service_providers_extrap$total_clean_fixed_wireless_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_cable_perc <- sum(service_providers_extrap$total_clean_cable_spend) / sum(service_providers_extrap$total_clean__spend)
national_average_other_perc <- sum(service_providers_extrap$total_clean_other_spend) / sum(service_providers_extrap$total_clean__spend)

#replacing NaNs with national averages
service_providers_extrap[is.nan(service_providers_extrap$clean_fiber_perc),c('clean_fiber_perc')] <- national_average_fiber_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_isp_perc),c('clean_isp_perc')] <- national_average_isp_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_t1_perc),c('clean_t1_perc')] <- national_average_t1_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_dsl_perc),c('clean_dsl_perc')] <- national_average_dsl_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_fixed_wireless_perc),c('clean_fixed_wireless_perc')] <- national_average_fixed_wireless_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_cable_perc),c('clean_cable_perc')] <- national_average_cable_perc
service_providers_extrap[is.nan(service_providers_extrap$clean_other_perc),c('clean_other_perc')] <- national_average_other_perc

service_providers_extrap <- service_providers_extrap[,c('reporting_name','clean_ia_perc','clean_wan_perc','clean_fiber_perc','clean_isp_perc',
                                                        'clean_t1_perc','clean_dsl_perc','clean_fixed_wireless_perc','clean_cable_perc','clean_other_perc')]

#************************************************************************************************
#joining clean ia and wan percent into sum_display
service_providers_sum_display <- merge(x = service_providers_sum_display, y = service_providers_extrap, by='reporting_name', all = TRUE)
service_providers_sum_display$extrap_ia_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_ia_perc
service_providers_sum_display$extrap_wan_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_wan_perc
service_providers_sum_display$extrap_ia_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_ia_perc
service_providers_sum_display$extrap_wan_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_wan_perc
service_providers_sum_display$extrap_fiber_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_fiber_perc
service_providers_sum_display$extrap_isp_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_isp_perc
service_providers_sum_display$extrap_t1_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_t1_perc
service_providers_sum_display$extrap_dsl_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_dsl_perc
service_providers_sum_display$extrap_fixed_wireless_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_fixed_wireless_perc
service_providers_sum_display$extrap_cable_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_cable_perc
service_providers_sum_display$extrap_other_spend <- service_providers_sum_display$total_spend * service_providers_sum_display$clean_other_perc
service_providers_sum_display$extrap_fiber_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_fiber_perc
service_providers_sum_display$extrap_isp_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_isp_perc
service_providers_sum_display$extrap_t1_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_t1_perc
service_providers_sum_display$extrap_dsl_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_dsl_perc
service_providers_sum_display$extrap_fixed_wireless_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_fixed_wireless_perc
service_providers_sum_display$extrap_cable_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_cable_perc
service_providers_sum_display$extrap_other_change <- service_providers_sum_display$total_funding_change * service_providers_sum_display$clean_other_perc

service_providers_sum_display$extrap_cost_per_mbps <- service_providers_sum_display$extrap_ia_spend / service_providers_sum_display$dedicated_bandwidth_mbps
service_providers_sum_display$extrap_bandwidth_change_gbps <- service_providers_sum_display$extrap_ia_change / service_providers_sum_display$extrap_cost_per_mbps / 1000

#ordering by funding change
service_providers_sum_display <- service_providers_sum_display[with(service_providers_sum_display, order(total_funding_change))]
top_15 <- as.vector(service_providers_sum_display[1:15,c('reporting_name')])
top_15

write.csv(service_providers_sum_display, "data/processed/service_providers_sum_display.csv", row.names = FALSE)
write.csv(service_providers_sum_display_by_locale, "data/processed/service_providers_sum_display_by_locale.csv", row.names = FALSE)
write.csv(service_providers_sum_display_by_state, "data/processed/service_providers_sum_display_by_state.csv", row.names = FALSE)
