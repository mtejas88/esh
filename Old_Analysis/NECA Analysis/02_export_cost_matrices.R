### PRELIMINARY AND UNCHECKED ###

# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "stringdist", "tidyr")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Google Drive/R/Service Providers/data/intermediate/")

###
# load data
services <- read.csv("01_services_tagged_neca.csv", as.is = TRUE)
## filtering
# limit services to clean
services <- filter(services, dirty_status == 'include clean')
# limit to unique line items  - 14,561 items
services <- services[!duplicated(services$line_item_id), ]

# create monthly cost per column for services received table
services$monthly_cost_per_line <- services$line_item_total_monthly_cost / services$line_item_total_num_lines

# export for analysis
write.csv(services, "02_clean_services.csv", row.names = FALSE)


# create a table of services

# Copper (T-1) - IA
cost_matrix_ia_t1 <- 
    services[services$neca == 1 & 
             services$internet_conditions_met == 'true' & 
             services$bandwidth_in_mbps %in% c(1.5) &
             services$connect_type == 'DS-1 (T-1)', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))

cost_matrix_ia_t1 <- spread(cost_matrix_ia_t1, bandwidth_in_mbps, median_monthly_cost_per_line)

# Copper (T-1) - WAN
cost_matrix_wan_t1 <- 
  services[services$neca == 1 & 
             services$wan_conditions_met == 'true' & 
             services$bandwidth_in_mbps %in% c(1.5) &
             services$connect_type == 'DS-1 (T-1)', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))

cost_matrix_wan_t1 <- spread(cost_matrix_wan_t1, bandwidth_in_mbps, median_monthly_cost_per_line)

# Cable - IA
cost_matrix_ia_cable <- 
  services[services$neca == 1 & 
             services$internet_conditions_met == 'true' & 
        #     services$bandwidth_in_mbps %in% c(1.5) &
             services$connect_type == 'Cable Modem', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))

cost_matrix_ia_cable <- spread(cost_matrix_ia_cable, bandwidth_in_mbps, median_monthly_cost_per_line)


# Cable - WAN
# no cable WAN for NECA providers
no_cable <- function(x) {
  cost_matrix_wan_cable <- 
  services[services$neca == 1 & 
             services$wan_conditions_met == 'true' & 
             #     services$bandwidth_in_mbps %in% c(1.5) &
             services$connect_type == 'Cable Modem', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))
}

# DSL - IA
cost_matrix_ia_dsl <- 
  services[services$neca == 1 & 
           services$internet_conditions_met == 'true' & 
           services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
           services$connect_type == 'Digital Subscriber Line (DSL)', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))
cost_matrix_ia_dsl <- spread(cost_matrix_ia_dsl, bandwidth_in_mbps, median_monthly_cost_per_line)


# DSL - WAN
cost_matrix_wan_dsl <- 
  
services[services$neca == 1 & 
           services$wan_conditions_met == 'true' & 
           services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
           services$connect_type == 'Digital Subscriber Line (DSL)', ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line, na.rm = TRUE))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line, na.rm = TRUE))

cost_matrix_wan_dsl <- spread(cost_matrix_wan_dsl, bandwidth_in_mbps, median_monthly_cost_per_line)

# Fiber - IA
cost_matrix_ia_fiber <- 
  services[services$neca == 1 & 
             services$internet_conditions_met == 'true' & 
             services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
             services$connect_type == 'Lit Fiber Service' |
             (services$connect_type == 'Ethernet' & services$bandwidth_in_mbps >= 150), ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line))
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line))

cost_matrix_ia_fiber <- spread(cost_matrix_ia_fiber, bandwidth_in_mbps, median_monthly_cost_per_line)


cost_matrix_wan_fiber <- 
  services[services$neca == 1 & 
             services$wan_conditions_met == 'true' & 
             services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
             services$connect_type == 'Lit Fiber Service' | 
             (services$connect_type == 'Ethernet' & services$bandwidth_in_mbps >= 100), ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line))#
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line))
cost_matrix_wan_fiber <- spread(cost_matrix_wan_fiber, bandwidth_in_mbps, median_monthly_cost_per_line)

#
cost_matrix_ia_all <- 
  services[services$neca == 1 & 
             services$internet_conditions_met == 'true' , ] %>%
  #services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
  #services$connect_type == 'Lit Fiber Service' | 
  #(services$connect_type == 'Ethernet' & services$bandwidth_in_mbps >= 100), ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line))#
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line))
cost_matrix_ia_all <- spread(cost_matrix_ia_all, bandwidth_in_mbps, median_monthly_cost_per_line)

cost_matrix_wan_all <- 
  services[services$neca == 1 & 
             services$wan_conditions_met == 'true' , ] %>%
             #services$bandwidth_in_mbps %in% c(10, 20, 50, 100, 200, 500, 1000) &
             #services$connect_type == 'Lit Fiber Service' | 
             #(services$connect_type == 'Ethernet' & services$bandwidth_in_mbps >= 100), ] %>%
  group_by(service_provider_name, bandwidth_in_mbps) %>%
  summarize(n = n(),
            median_monthly_cost_per_line = median(monthly_cost_per_line))#
#            mean_monthly_cost_per_line = mean(monthly_cost_per_line))
cost_matrix_wan_all <- spread(cost_matrix_wan_all, bandwidth_in_mbps, median_monthly_cost_per_line)

# cable, copper etc.non-fiber, technology-specific

# switch directory
setwd("~/Google Drive/R/Service Providers/data/export/csv/20160309")
# export files
write.csv(cost_matrix_ia_t1, "cost_matrix_ia_t1.csv", row.names = FALSE)
write.csv(cost_matrix_wan_t1, "cost_matrix_wan_t1.csv", row.names = FALSE)
write.csv(cost_matrix_ia_cable, "cost_matrix_ia_cable.csv", row.names = FALSE)
#write.csv(cost_matrix_wan_cable, "cost_matrix_wan_cable.csv", row.names = FALSE)
write.csv(cost_matrix_ia_dsl, "cost_matrix_ia_dsl.csv", row.names = FALSE)
write.csv(cost_matrix_wan_dsl, "cost_matrix_wan_dsl.csv", row.names = FALSE)
write.csv(cost_matrix_ia_fiber, "cost_matrix_ia_fiber.csv", row.names = FALSE)
write.csv(cost_matrix_wan_fiber, "cost_matrix_wan_fiber.csv", row.names = FALSE)
write.csv(cost_matrix_ia_all, "cost_matrix_ia_all.csv", row.names = FALSE)
write.csv(cost_matrix_wan_all, "cost_matrix_wan_all.csv", row.names = FALSE)
