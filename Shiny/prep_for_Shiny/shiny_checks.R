wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)


  lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
  #sapply(lib, function(x) install.packages(x))
  sapply(lib, function(x) require(x, character.only = TRUE))
  
  services <- read.csv("services_received_20160404.csv", as.is = TRUE)
  districts <- read.csv("deluxe_districts_20160404.csv", as.is = TRUE)
  # nrow(services) #83203
  # nrow(districts) #13025
  
  ### SERVICES RECEIVED
  # filter the data, using proper conditions
  services <- services %>% 
         filter(shared_service == "District-dedicated" & 
                  dirty_status == "include clean" & exclude == "FALSE")
  # nrow(services) #15844
  # length(unique(services$line_item_id)) #13586
  
  # exclude rows that should be excluded for cost calculations
  services <- services[!grepl("exclude_for_cost_only", services$open_flags),] 
  # nrow(services) #15,060
  
  # Convert variables to relevant types
  services$ia_bandwidth_per_student <- as.numeric(services$ia_bandwidth_per_student)
  services$postal_cd <- as.character(services$postal_cd)
  services$band_factor <- as.factor(services$bandwidth_in_mbps)
  
  # Append new column for purpose type
  services$new_purpose[services$internet_conditions_met == TRUE] <- "Internet"
  services$new_purpose[services$wan_conditions_met == TRUE] <- "WAN"
  services$new_purpose[services$isp_conditions_met == TRUE] <- "ISP Only"
  services$new_purpose[services$upstream_conditions_met == TRUE] <- "Upstream"
  # table(services$new_purpose)
  
  # Appending new column for monthly cost per circuit:
  services$monthly_cost_per_circuit <- services$line_item_total_monthly_cost / services$line_item_total_num_lines 
  services$monthly_cost_per_mbps <- services$monthly_cost_per_circuit / services$bandwidth_in_mbps
  
  ##  SERVICES RECEIVED DATA: END ##
  
services_b_w <- filter(services, services$bandwidth_in_mbps %in% c(50, 100, 500, 1000, 10000))  

services_b_w %>%
  group_by(bandwidth_in_mbps) %>%
  summarize(n = n())