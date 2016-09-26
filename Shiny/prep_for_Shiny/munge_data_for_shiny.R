# Clear the console
cat("\014")
# Remove every object in the environment
rm(list = ls())

lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))


wd <- "~/Desktop/ficher/Shiny/prep_for_Shiny"
setwd(wd)

services <- read.csv("services_received_20160725.csv", as.is = TRUE) # services received '15
services16 <- read.csv("2016_services_received_20160916.csv", as.is = TRUE) # services received '16

districts <- read.csv("deluxe_districts_20160831.csv", as.is = TRUE) # deluxe districts '15
districts16 <- read.csv("2016_deluxe_districts_20160916.csv", as.is = TRUE) # deluxe districts '16

discounts <- read.csv("district_discount_rates_20160414.csv", as.is = TRUE)
usac_matrix <- read.csv("usac_discount_matrix.csv", as.is = TRUE)
schools_needing_wan <- read.csv("schools_needing_wan_20160725.csv", as.is = TRUE)
us_sen <- read.csv("us_senatorial_ids.csv", as.is = TRUE)


### SERVICES RECEIVED '15
# filter the data, using proper conditions
services <- services %>% 
  filter(shared_service == "District-dedicated" & 
           dirty_status == "include clean" & exclude == "FALSE" & exclude_from_analysis == "FALSE")

# exclude rows that that contain duplicate line items
services <- services[!duplicated(services$line_item_id), ]
# nrow(services)
# exclude rows that should be excluded for cost calculations
services <- services[!grepl("exclude_for_cost_only", services$open_flags),] 
# nrow(services) #12,939

# Convert variables to relevant types

services$ia_bandwidth_per_student <- as.numeric(services$ia_bandwidth_per_student)
services$postal_cd <- as.character(services$postal_cd)

# Append new column for purpose type
services$new_purpose[services$internet_conditions_met == TRUE] <- "Internet"
services$new_purpose[services$wan_conditions_met == TRUE] <- "WAN"
services$new_purpose[services$isp_conditions_met == TRUE] <- "ISP Only"
services$new_purpose[services$upstream_conditions_met == TRUE] <- "Upstream"

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

# take out columns that are internal only
out <- which(names(services) %in% c("consortium_shared",
                                     "shared_service",
                                     "purpose",
                                     "wan",
                                     "broadband",
                                     "exclude",
                                     "open_flags",
                                     "dqs_excluded",
                                     "district_monthly_ia_cost_per_mbps",
                                     "district_total_ia_rounded_to_nearest_mbps",
                                     "exclude_from_analysis",
                                     "isp_conditions_met",
                                     "wan_conditions_met",
                                     "ia_conditions_met",
                                     "internet_conditions_met",
                                     "upstream_conditions_met",
                                     "num_students_and_staff",
                                     "consortium_member",
                                     "line_item_one_time_cost",
                                     "line_item_recurring_elig_cost",
                                     "orig_r_months_of_service",
                                     "recipient_districts",
                                     "recipient_postal_cd",
                                     "dirty_status",
                                     "band_factor",
                                     "connect_type"))

services <- services[, -out]
services <- left_join(services, us_sen, by = c("recipient_id" = "esh_id"))
services <- services %>% select(-c(name,postal_cd.y, latitude.y, longitude.y))
services <- rename(services,  c("postal_cd.x" = "postal_cd", 
                                "latitude.x" = "latitude", 
                                "longitude.x" = "longitude",
                                "cat.1_allocations_to_district" = "quantity_of_line_items_received_by_district"))


rm(out)


### SERVICES RECEIVED '16 ###
# filter the data, using proper conditions
#services16 <- services16 %>% 
#          filter(inclusion_status == "clean_with_cost" & recipient_exclude_from_analysis == "FALSE") 
#nrow(services16) #14,257

# exclude rows that that contain duplicate line items
services16 <- services16[!duplicated(services16$line_item_id), ]
#nrow(services16) #8,632


# Convert variables to relevant types
services16$recipient_postal_cd <- as.character(services16$recipient_postal_cd)

# Create new column for monthly cost per circuit:
services16$monthly_cost_per_circuit <- services16$line_item_total_monthly_cost / services16$line_item_total_num_lines 
services16$monthly_cost_per_mbps <- services16$monthly_cost_per_circuit / services16$bandwidth_in_mbps

# Create new column for connection types
services16$new_connect_type <- as.character(services16$connect_category)
services16$new_connect_type[services16$connect_category %in% c("T-1", "Other Copper")] <- "Copper"
services16$new_connect_type[services16$connect_category %in% c("ISP Only", "Satellite/LTE", "Uncategorized")] <- "Other / Uncategorized"
services16$new_connect_type <- as.factor(services16$new_connect_type)




# take out columns that are internal only
out16 <- which(names(services16) %in% c("inclusion_status",
                                        "open_tags",
                                        "open_flags",
                                        "erate",
                                        "consortium_shared",
                                        "broadband",
                                        "connect_category",
                                        "recipient_consortium_member"))

services16 <- services16[, -out16]
services16 <- left_join(services16, us_sen, by = c("recipient_id" = "esh_id"))
services16 <- services16 %>% select(-c(name, postal_cd, latitude, longitude))

#Renaming columns in services 2016 data for simplicity
services16 <- rename(services16,  c("recipient_postal_cd" = "postal_cd", 
                                    "recipient_latitude" = "latitude", 
                                    "recipient_longitude" = "longitude",
                                    "recipient_ia_monthly_cost_per_mbps" = "ia_monthly_cost_per_mbps",
                                    "recipient_ia_bw_mbps_total" = "ia_bw_mbps_total",
                                    "recipient_ia_bandwidth_per_student_kbps" = "ia_bandwidth_per_student",
                                    "recipient_num_students" = "num_students",
                                    "recipient_num_schools" = "num_schools",
                                    "recipient_locale" = "locale",
                                    "recipient_district_size" = "district_size",
                                    "recipient_exclude_from_analysis" = "exclude_from_analysis",
                                    "purpose" = "new_purpose"))

rm(out16)

### End munging for SERVICES RECEIVED '16 ###



### DELUXE DISTRICTS '15 ###
districts$ia_bandwidth_per_student <- as.numeric(districts$ia_bandwidth_per_student)
districts$monthly_ia_cost_per_mbps <- as.numeric(districts$monthly_ia_cost_per_mbps)
## Keep original goals variables
# District Meeting Goals: 1 if district is meeting goal
districts$meeting_goals_district <- ifelse(districts$meeting_2014_goal_no_oversub == "TRUE", 1, 0)

# New Variables for mapping #
districts$exclude <- ifelse(districts$exclude_from_analysis == "FALSE", "Clean", "Dirty")
districts$meeting_2014_goal_no_oversub <- ifelse(districts$meeting_2014_goal_no_oversub == "TRUE", 
                                                 "Meeting Goal",
                                                 "Not Meeting Goal")
districts$meeting_2018_goal_oversub <- ifelse(districts$meeting_2018_goal_oversub == "TRUE", 
                                              "Meeting 2018 Goals",
                                              "Not Meeting 2018 Goals")
districts$meeting_2018_goal_oversub <- as.factor(districts$meeting_2018_goal_oversub)
districts$meeting_2014_goal_no_oversub <- as.factor(districts$meeting_2014_goal_no_oversub)

# create indicator for district having at least 1 unscalable campus
districts$not_all_scalable <- ifelse(districts$nga_v2_known_unscalable_campuses + districts$nga_v2_assumed_unscalable_campuses > 0, 1, 0)

# deluxe districts
districts$new_connect_type_goals <- ifelse(districts$hierarchy_connect_category %in% c("None - Error", "Other/Uncategorized"), 
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
# since they are also missing FRL percentage, :/
districts$usac_c1_urban <- NULL
districts$usac_c1_rural <- NULL

# no cost to district - district discount rate is at least 80%
districts$zero_build_cost_to_district <- ifelse(districts$c1_discount_rate >= 80, 1, 0)

# calculate % of schools that have > 100 students

schools_needing_wan$need_wan <- ifelse(schools_needing_wan$MEMBER > 100, 1, 0)

data <- schools_needing_wan %>%
        group_by(esh_id) %>%
        summarize(n_schools_wan_needs = sum(need_wan, na.rm = TRUE),
                  n_schools_in_wan_needs_calculation = n())

districts <- left_join(districts, data, by = c("esh_id"))

missing_n <- which(is.na(districts$n_schools_in_wan_needs_calculation))
districts[missing_n, ]$n_schools_wan_needs <- 0
districts[missing_n, ]$n_schools_in_wan_needs_calculation <- 0

rm(data, missing_n)

districts$schools_on_fiber <- ((districts$nga_v2_known_scalable_campuses + districts$nga_v2_assumed_scalable_campuses)  / districts$num_campuses) * districts$num_schools
districts$schools_may_need_upgrades <- (districts$nga_v2_assumed_unscalable_campuses / districts$num_campuses) * districts$num_schools
districts$schools_need_upgrades <- (districts$nga_v2_known_unscalable_campuses / districts$num_campuses) * districts$num_schools

# filter to relevant columns
out <- which(names(districts) %in% c("ia_oversub_ratio", "district_type",
                                 "num_campuses", "num_open_dirty_flags", "clean_categorization",
                                 "meeting_2014_goal_oversub", "meeting_2018_goal_no_oversub",
                                 "meeting_.3_per_mbps_affordability_target",
                                 "hierarchy_connect_category", "nga_v2_known_scalable_campuses",
                                 "nga_v2_assumed_scalable_campuses", "nga_v2_known_unscalable_campuses",
                                 "nga_v2_assumed_unscalable_campuses",
                                 "known_fiber_campuses", "assumed_fiber_campuses", "known_nonfiber_campuses",
                                 "assumed_nonfiber_campuses", "fiber_lines", "fixed_wireless_lines",
                                 "cable_lines", "copper_dsl_lines", "other_uncategorized_lines",
                                 "fiber_internet_upstream_lines", "fixed_wireless_internet_upstream_lines",
                                 "cable_internet_upstream_lines", "copper_dsl_internet_upstream_lines",
                                 "other_uncategorized_internet_upstream_lines",
                                 "wan_lines", "ia_applicants", "dedicated_isp_sp",
                                 "dedicated_isp_services", "dedicated_isp_contract_expiration",
                                 "bundled_internet_sp", "bundled_internet_connections",
                                 "bundled_internet_contract_expiration", "upstream_applicants",
                                 "upstream_sp", "upstream_connections", "upstream_contract_expiration",
                                 "wan_applicants", "wan_sp", "wan_connections",
                                 "ULOCAL",
                                 "num_students_and_staff",
                                 "ia_cost_per_mbps",
                                 "all_ia_connectcat",
                                 "all_ia_connecttype",
                                 "wan_cost_per_connection",
                                 "wan_bandwidth_low",
                                 "wan_bandwidth_high",
                                 "wan_contract_expiration"))

districts <- districts[, -out]
districts <- left_join(districts, us_sen, by = "esh_id")
districts <- districts %>% select(-c(nces_cd.y, name.y, postal_cd.y, latitude.y, longitude.y))
districts <- rename(districts,  c("nces_cd.x" = "nces_cd", "name.x" = "name", "postal_cd.x" = "postal_cd", "latitude.x" = "latitude", "longitude.x" = "longitude"))

## End DISTRICT DELUXE '15 ###


### Start DISTRICT DELUXE '16 ###

## Keep original goals variables
# District Meeting Goals: 1 if district is meeting goal
districts16$meeting_goals_district <- ifelse(districts16$meeting_2014_goal_no_oversub == "TRUE", 1, 0)

# new variables for mapping #
districts16$exclude <- ifelse(districts16$exclude_from_analysis == "FALSE", "Clean", "Dirty")

districts16$meeting_2014_goal_no_oversub <- ifelse(districts16$meeting_2014_goal_no_oversub == "TRUE", 
                                                    "Meeting Goal",
                                                    "Not Meeting Goal")
districts16$meeting_2018_goal_oversub <- ifelse(districts16$meeting_2018_goal_oversub == "TRUE", 
                                                  "Meeting 2018 Goals",
                                                  "Not Meeting 2018 Goals")
districts16$meeting_2018_goal_oversub <- as.factor(districts16$meeting_2018_goal_oversub)
districts16$meeting_2014_goal_no_oversub <- as.factor(districts16$meeting_2014_goal_no_oversub)

# create indicator for district having at least 1 unscalable campus
districts16$not_all_scalable <- ifelse(districts16$nga_known_unscalable_campuses + districts16$nga_assumed_unscalable_campuses > 0, 1, 0)

# deluxe districts16
districts16$hierarchy_connect_category <- as.character(districts16$hierarchy_ia_connect_category)
districts16$new_connect_type_goals <- ifelse(districts16$hierarchy_connect_category %in% c("None - Error", "Satellite/LTE", "Uncategorized"), 
                                           "Other / Uncategorized", districts16$hierarchy_connect_category)


# merge on discount rates

# now use the USAC matrix to find discount rates for the districts
# missing discount rates
missing_discount_rate_urban <- which(is.na(districts16$discount_rate_c1) & districts16$locale %in% c("Suburban", "Urban")) #637
missing_discount_rate_rural <- which(is.na(districts16$discount_rate_c1) & districts16$locale %in% c("Rural", "Small Town")) #428

districts16$usac_c1_urban <- 
  ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[1], usac_matrix$c1_urban[1],
         ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[2], usac_matrix$c1_urban[2],
                ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[3], usac_matrix$c1_urban[3],
                       ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[4], usac_matrix$c1_urban[4], usac_matrix$c1_urban[5]))))

districts16$usac_c1_rural <- 
  ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[1], usac_matrix$c1_rural[1],
         ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[2], usac_matrix$c1_rural[2],
                ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[3], usac_matrix$c1_rural[3],
                       ifelse(districts16$frl_percent < usac_matrix$frl_ceiling[4], usac_matrix$c1_rural[4], usac_matrix$c1_rural[5]))))

districts16[missing_discount_rate_urban, ]$discount_rate_c1 <- districts16[missing_discount_rate_urban, ]$usac_c1_urban
districts16[missing_discount_rate_rural, ]$discount_rate_c1 <- districts16[missing_discount_rate_rural, ]$usac_c1_rural

# there are 322 districts still missing discount rates
# since they are also missing FRL percentage, :/
summary(districts16$discount_rate_c1) #NA: 322

districts16$usac_c1_urban <- NULL
districts16$usac_c1_rural <- NULL

# no cost to district - district discount rate is at least 80%
districts16$zero_build_cost_to_district <- ifelse(districts16$discount_rate_c1 >= 80, 1, 0)

# calculate % of schools that have > 100 students
schools_needing_wan$need_wan <- ifelse(schools_needing_wan$MEMBER > 100, 1, 0)

data <- schools_needing_wan %>%
  group_by(esh_id) %>%
  summarize(n_schools_wan_needs = sum(need_wan, na.rm = TRUE),
            n_schools_in_wan_needs_calculation = n())

districts16 <- left_join(districts16, data, by = c("esh_id"))

missing_n <- which(is.na(districts16$n_schools_in_wan_needs_calculation))
districts16[missing_n, ]$n_schools_wan_needs <- 0
districts16[missing_n, ]$n_schools_in_wan_needs_calculation <- 0

rm(data, missing_n)

districts16$schools_on_fiber <- ((districts16$nga_known_scalable_campuses + districts16$nga_assumed_scalable_campuses)  / districts16$num_campuses) * districts16$num_schools
districts16$schools_may_need_upgrades <- (districts16$nga_assumed_unscalable_campuses / districts16$num_campuses) * districts16$num_schools
districts16$schools_need_upgrades <- (districts16$nga_known_unscalable_campuses / districts16$num_campuses) * districts16$num_schools

# filter to relevant columns
out <- which(names(districts16) %in% c("union_code", "state_senate_district", "state_assembly_district",
                                       "ulocal", "ia_oversub_ratio", "district_type", "num_campuses",
                                       "address", "city", "zip", "county", "flag_array", "tag_array",
                                       "num_open_district_flags", "clean_categorization",
                                       "meeting_2014_goal_oversub", "meeting_2014_goal_no_oversub_fcc_25",
                                       "meeting_2018_goal_no_oversub", "meeting_2018_goal_no_oversub_fcc_25", 
                                       "meeting_3_per_mbps_affordability_target", "hierarchy_connect_category", 
                                       "nga_known_scalable_campuses", "nga_assumed_scalable_campuses", 
                                       "nga_known_unscalable_campuses", "nga_assumed_unscalable_campuses",
                                       "known_fiber_campuses", "assumed_fiber_campuses", "known_nonfiber_campuses",
                                       "assumed_nonfiber_campuses", "fiber_internet_upstream_lines", 
                                       "fixed_wireless_internet_upstream_lines", "cable_internet_upstream_lines", 
                                       "copper_internet_upstream_lines", "satellite_lte_internet_upstream_lines",
                                       "uncategorized_internet_upstream_lines", "wan_lines", "wan_bandwidth_low",
                                       "wan_bandwidth_high","ia_applicants", "dedicated_isp_sp",
                                       "dedicated_isp_services", "dedicated_isp_contract_expiration",
                                       "bundled_internet_sp", "bundled_internet_services",
                                       "bundled_internet_contract_expiration", "upstream_sp",
                                       "upstream_sp", "upstream_contract_expiration",
                                       "wan_applicants", "wan_sp", "wan_contract_expiration"))

districts16 <- districts16[, -out]
districts16 <- left_join(districts16, us_sen, by = "esh_id")
districts16 <- districts16 %>% select(-c(nces_cd.y, name.y, postal_cd.y, latitude.y, longitude.y))
districts16 <- rename(districts16,  c("nces_cd.x" = "nces_cd", 
                                      "name.x" = "name", 
                                      "postal_cd.x" = "postal_cd", 
                                      "latitude.x" = "latitude", 
                                      "longitude.x" = "longitude",
                                      "ia_monthly_cost_total" = "total_ia_monthly_cost",
                                      "ia_monthly_cost_per_mbps" = "monthly_ia_cost_per_mbps",
                                      "ia_bw_mbps_total" = "total_ia_bw_mbps",
                                      "ia_bandwidth_per_student_kbps" = "ia_bandwidth_per_student",
                                      "discount_rate_c1" = "c1_discount_rate"))

### End Munging for DELUXE DISTRICTS '16 ###


### Districts '15: locale and district size cuts ###
districts_clean <- districts %>% filter(exclude == "Clean")
districts_clean$postal_cd <- paste0(districts_clean$postal_cd, " Clean")

data <- rbind(districts, districts_clean)

n_all <- data %>% group_by(postal_cd) %>%
                  summarize(n_districts = n(),
                            n_schools = sum(num_schools),
                            n_students = sum(num_students))

# by locale
locale_cuts <- data %>% group_by(postal_cd, locale) %>%
                        summarize(n_districts_locale = n())

locale_cuts <- left_join(locale_cuts, n_all, by = c("postal_cd"))

locale_cuts$percent <- 100 * locale_cuts$n_districts_locale / locale_cuts$n_districts

locale_cuts$locale <- factor(locale_cuts$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
locale_cuts <- arrange(locale_cuts, postal_cd, locale)
locale_cuts <- select(locale_cuts, postal_cd, locale, percent, n_districts_locale, n_districts, n_schools, n_students)

# by district sizes
size_cuts <- data %>% group_by(postal_cd, district_size) %>%
                      summarize(n_districts_size = n())

size_cuts <- left_join(size_cuts, n_all, by = c("postal_cd"))

size_cuts$percent <- 100 * size_cuts$n_districts_size / size_cuts$n_districts

size_cuts$district_size <- factor(size_cuts$district_size, levels = c("Mega", "Large", "Medium", "Small", "Tiny"))
size_cuts <- arrange(size_cuts, postal_cd, district_size)
size_cuts <- select(size_cuts, postal_cd, district_size, percent, n_districts_size, n_districts, n_schools, n_students)

### END Districts '15: locale and district size cuts ###


### Districts '16: locale and district size cuts ###
districts16_clean <- districts16 %>% filter(exclude == "Clean")
districts16_clean$postal_cd <- paste0(districts16_clean$postal_cd, " Clean")

data16 <- rbind(districts16, districts16_clean)

n_all16 <- data16 %>% group_by(postal_cd) %>%
                      summarize(n_districts = n(),
                                n_schools = sum(num_schools),
                                n_students = sum(num_students))

# by locale
locale_cuts16 <- data16 %>% group_by(postal_cd, locale) %>%
                            summarize(n_districts_locale = n())

locale_cuts16 <- left_join(locale_cuts16, n_all16, by = c("postal_cd"))

locale_cuts16$percent <- 100 * locale_cuts16$n_districts_locale / locale_cuts16$n_districts

#Rename locale "Town" to "Small Town"
locale_cuts16$locale[locale_cuts16$locale %in% c("Town")] <- "Small Town"
locale_cuts16$locale <- factor(locale_cuts16$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
locale_cuts16 <- arrange(locale_cuts16, postal_cd, locale)
locale_cuts16 <- select(locale_cuts16, postal_cd, locale, percent, n_districts_locale, n_districts, n_schools, n_students)

# by district sizes
size_cuts16 <- data16 %>% group_by(postal_cd, district_size) %>%
                          summarize(n_districts_size = n())

size_cuts16 <- left_join(size_cuts16, n_all16, by = c("postal_cd"))

size_cuts16$percent <- 100 * size_cuts16$n_districts_size / size_cuts16$n_districts

size_cuts16$district_size <- factor(size_cuts16$district_size, levels = c("Mega", "Large", "Medium", "Small", "Tiny"))
size_cuts16 <- arrange(size_cuts16, postal_cd, district_size)
size_cuts16 <- select(size_cuts16, postal_cd, district_size, percent, n_districts_size, n_districts, n_schools, n_students)

### END Districts '16: locale and district size cuts ###



wd <- "~/Desktop/ficher/Shiny"
setwd(wd)

# export 2015 datasets
write.csv(services, "services_received_shiny.csv", row.names = FALSE)
write.csv(districts, "districts_shiny.csv", row.names = FALSE)
write.csv(locale_cuts, "locale_cuts.csv", row.names = FALSE)
write.csv(size_cuts, "size_cuts.csv", row.names = FALSE)

# export 2016 datasets
write.csv(services16, "2016_services_received_shiny.csv", row.names = FALSE)
write.csv(districts16, "2016_districts_shiny.csv", row.names = FALSE)
write.csv(locale_cuts16, "2016_locale_cuts.csv", row.names = FALSE)
write.csv(size_cuts16, "2016_size_cuts.csv", row.names = FALSE)


