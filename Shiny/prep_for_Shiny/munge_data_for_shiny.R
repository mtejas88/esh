# Clear the console
cat("\014")
# Remove every object in the environment
rm(list = ls())

lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))


wd <- "~/Google Drive/github/ficher/Shiny/prep_for_Shiny"
setwd(wd)

services <- read.csv("services_received_20160404.csv", as.is = TRUE)
districts <- read.csv("deluxe_districts_20160404.csv", as.is = TRUE)
# nrow(services) #83196
# nrow(districts) #13025

### SERVICES RECEIVED
# filter the data, using proper conditions
services <- services %>% 
  filter(shared_service == "District-dedicated" & 
           dirty_status == "include clean" & exclude == "FALSE")
# nrow(services) #15812
# length(unique(services$line_item_id)) #13,554

# exclude rows that that contain duplicate line items
services <- services[!duplicated(services$line_item_id), ]
# nrow(services)
# exclude rows that should be excluded for cost calculations
services <- services[!grepl("exclude_for_cost_only", services$open_flags),] 
# nrow(services) #12,939

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

# Create new column for monthly cost per circuit:
services$monthly_cost_per_circuit <- services$line_item_total_monthly_cost / services$line_item_total_num_lines 
services$monthly_cost_per_mbps <- services$monthly_cost_per_circuit / services$bandwidth_in_mbps

# Create new column for connection types
services$new_connect_type[services$connect_type %in% c("Cable Modem")] <- "Cable"
services$new_connect_type[services$connect_type %in% c("Digital Subscriber Line (DSL)")] <- "DSL"
services$new_connect_type[services$connect_type %in% c("Dark Fiber Service")] <- "Dark Fiber"
services$new_connect_type[services$connect_type %in% c("E.g., Microwave Service")] <- "Fixed Wireless"
services$new_connect_type[services$connect_type %in% c("Lit Fiber Service")] <- "Lit Fiber"
services$new_connect_type[services$connect_type %in% c("DS-1 (T-1)", "DS-3 (T-3)")] <- "Copper"
services$new_connect_type <- ifelse(is.na(services$new_connect_type), "Other / Uncategorized", services$new_connect_type)

# Create National column for overall national
services$national <- rep("National", nrow(services))

##  SERVICES RECEIVED DATA: END ##

### DELUXE DISTRICTS TABLE:  prepping the data to be the correct subset to use ###
districts$ia_bandwidth_per_student <- as.numeric(districts$ia_bandwidth_per_student)

# New Variables for mapping #
districts$exclude <- ifelse(districts$exclude_from_analysis == "FALSE", "Clean", "Dirty")
districts$meeting_2014_goal_no_oversub <- ifelse(districts$meeting_2014_goal_no_oversub == "TRUE", 
                                                 "Meeting 2014 Goals",
                                                 "Not Meeting 2014 Goals")
districts$meeting_2018_goal_oversub <- ifelse(districts$meeting_2018_goal_oversub == "TRUE", 
                                              "Meeting 2018 Goals",
                                              "Not Meeting 2018 Goals")
districts$meeting_2018_goal_oversub <- as.factor(districts$meeting_2018_goal_oversub)
districts$meeting_2014_goal_no_oversub <- as.factor(districts$meeting_2014_goal_no_oversub)

# create indicator for district having at least 1 unscalable campus
districts$not_all_scalable <- ifelse(districts$nga_v2_known_unscalable_campuses + districts$nga_v2_assumed_unscalable_campuses > 0, 1, 0)

# deluxe districts
districts$new_connect_type <- ifelse(districts$hierarchy_connect_category %in% c("None - Error", "Other/Uncategorized"), 
                                     "Other / Uncategorized", districts$hierarchy_connect_category)

## END



wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)


# export
write.csv(services, "services_received_shiny.csv", row.names = FALSE)
write.csv(districts, "districts_shiny.csv", row.names = FALSE)