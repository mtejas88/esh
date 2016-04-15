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
# https://modeanalytics.com/educationsuperhighway889/reports/960fa62420ca
discounts <- read.csv("district_discount_rates_20160414.csv", as.is = TRUE)
# http://www.usac.org/_res/documents/sl/pdf/samples/Discount-Matrix.pdf
usac_matrix <- read.csv("usac_discount_matrix.csv", as.is = TRUE)
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

## prepare data for IA price dispersion chart, holding  circuit size and type constant

ia_prices <- services %>%
             filter(band_factor %in% c(50, 100, 500, 1000, 10000))
                      
dispersion <- ia_prices %>%
              group_by(postal_cd, band_factor, new_connect_type, new_purpose) %>%
              summarize(n = n(),
                        min = round(quantile(monthly_cost_per_circuit, 0.10, na.rm = TRUE), -2),
                        q10 = round(quantile(monthly_cost_per_circuit, 0.10, na.rm = TRUE), -2),
                        q50 = round(quantile(monthly_cost_per_circuit, 0.50, na.rm = TRUE), -2),
                        q90 = round(quantile(monthly_cost_per_circuit, 0.90, na.rm = TRUE), -2),
                        max = round(quantile(monthly_cost_per_circuit, 0.90, na.rm = TRUE), -2))

dispersion$bucket_1 <- paste("$", dispersion$min, " - ", "less than ", "$", dispersion$q10, sep = "")
dispersion$bucket_2 <- paste("$", dispersion$q10, " - ", "less than ", "$", dispersion$q50, sep = "")
dispersion$bucket_3 <- paste("$", dispersion$q50, " - ", "less than ", "$", dispersion$q90, sep = "")
dispersion$bucket_4 <- paste("$", dispersion$q90, " - ", "up to ", "$", dispersion$max, sep = "")

services <- left_join(services, dispersion, by = c("postal_cd", "band_factor", "new_connect_type", "new_purpose"))

services$price_bucket <- ifelse(services$monthly_cost_per_circuit < services$q10, services$bucket_1,
                                ifelse(services$monthly_cost_per_circuit < services$q50, services$bucket_2,
                                       ifelse(services$monthly_cost_per_circuit < services$q90, services$bucket_3, services$bucket_4)))

services$bubble_size <- ifelse(services$monthly_cost_per_circuit < services$q10, 3,
                              ifelse(services$monthly_cost_per_circuit < services$q50, 6,
                                    ifelse(services$monthly_cost_per_circuit < services$q90, 9, 12)))

# filter to relevant columns
# names(services)

services <- dplyr::select(services, recipient_id, postal_cd,
                          line_item_total_num_lines, line_item_total_monthly_cost,
                          num_students, num_schools, latitude, longitude,
                          locale, district_size, band_factor, new_purpose,
                          monthly_cost_per_circuit, monthly_cost_per_mbps,
                          new_connect_type, national, q10, q50, q90, bubble_size, price_bucket)


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

# merge on discount rates

# first, rid discounts query by any duplicates
discounts <- dplyr::select(discounts, esh_id, c1_discount_rate_max)
discounts <- arrange(discounts, esh_id, -c1_discount_rate_max)
discounts <- discounts[!duplicated(discounts$esh_id), ]
names(discounts)  <- c("esh_id", "c1_discount_rate")

districts <- left_join(districts, discounts, by = c("esh_id"))

# now use the USAC matrix to find discount rates for the districts

# missing discount rates
missing_discount_rate_urban <- which(is.na(districts$c1_discount_rate) & 
                                       districts$locale %in% c("Suburban", "Urban"))
missing_discount_rate_rural <- which(is.na(districts$c1_discount_rate) & 
                                       districts$locale %in% c("Rural", "Small Town"))

districts$usac_c1_urban <- 
ifelse(districts$frl_percent < usac_matrix$frl_ceiling[1], usac_matrix$c1_urban[1],
       ifelse(districts$frl_percent < usac_matrix$frl_ceiling[2], usac_matrix$c1_urban[2],
              ifelse(districts$frl_percent < usac_matrix$frl_ceiling[3], usac_matrix$c1_urban[3],
                     ifelse(districts$frl_percent < usac_matrix$frl_ceiling[4], usac_matrix$c1_urban[4], usac_matrix$c1_urban[5]))))

districts$usac_c1_rural <- 
  ifelse(districts$frl_percent < usac_matrix$frl_ceiling[1], usac_matrix$c1_rural[1],
         ifelse(districts$frl_percent < usac_matrix$frl_ceiling[2], usac_matrix$c1_rural[2],
                ifelse(districts$frl_percent < usac_matrix$frl_ceiling[3], usac_matrix$c1_rural[3],
                       ifelse(districts$frl_percent < usac_matrix$frl_ceiling[4], usac_matrix$c1_rural[4], usac_matrix$c1_rural[5]))))

districts[missing_discount_rate_urban, ]$c1_discount_rate <- districts[missing_discount_rate_urban, ]$usac_c1_urban
districts[missing_discount_rate_rural, ]$c1_discount_rate <- districts[missing_discount_rate_rural, ]$usac_c1_rural

# there are 165 districts still missing discount rates
# since they are also missing FLR percentage, :/
districts$usac_c1_urban <- NULL
districts$usac_c1_rural <- NULL

# no cost to district - district discount rate is at least 80%
districts$zero_build_cost_to_district <- ifelse(districts$c1_discount_rate >= 80, 1, 0)
## END

wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)

# export
write.csv(services, "services_received_shiny.csv", row.names = FALSE)
write.csv(districts, "districts_shiny.csv", row.names = FALSE)