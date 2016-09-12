# Clear the console
cat("\014")
# Remove every object in the environment
rm(list = ls())

lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))


wd <- "~/Desktop/ficher/Shiny/prep_for_Shiny"
setwd(wd)

services <- read.csv("services_received_20160912.csv", as.is = TRUE)
districts <- read.csv("deluxe_districts_20160912.csv", as.is = TRUE)
discounts <- read.csv("district_discount_rates_20160414.csv", as.is = TRUE)
usac_matrix <- read.csv("usac_discount_matrix.csv", as.is = TRUE)
schools_needing_wan <- read.csv("schools_needing_wan_20160725.csv", as.is = TRUE)

### SERVICES RECEIVED
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
rm(out)

### DELUXE DISTRICTS TABLE: 
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
out <- which(names(districts) %in% c("esh_id", "ia_oversub_ratio", "district_type",
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
## END

## locale and district size cuts

districts_clean <- districts %>%
                   filter(exclude == "Clean")
districts_clean$postal_cd <- paste0(districts_clean$postal_cd, " Clean")

data <- rbind(districts, districts_clean)

n_all <- data %>%
         group_by(postal_cd) %>%
         summarize(n_districts = n(),
                   n_schools = sum(num_schools),
                   n_students = sum(num_students))

# by locale
locale_cuts <- data %>%
          group_by(postal_cd, locale) %>%
          summarize(n_districts_locale = n())

locale_cuts <- left_join(locale_cuts, n_all, by = c("postal_cd"))

locale_cuts$percent <- 100 * locale_cuts$n_districts_locale / locale_cuts$n_districts

locale_cuts$locale <- factor(locale_cuts$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
locale_cuts <- arrange(locale_cuts, postal_cd, locale)
locale_cuts <- select(locale_cuts, postal_cd, locale, percent, n_districts_locale, n_districts, n_schools, n_students)

# by district sizes
size_cuts <- data %>%
                  group_by(postal_cd, district_size) %>%
                  summarize(n_districts_size = n())

size_cuts <- left_join(size_cuts, n_all, by = c("postal_cd"))

size_cuts$percent <- 100 * size_cuts$n_districts_size / size_cuts$n_districts

size_cuts$district_size <- factor(size_cuts$district_size, levels = c("Mega", "Large", "Medium", "Small", "Tiny"))
size_cuts <- arrange(size_cuts, postal_cd, district_size)
size_cuts <- select(size_cuts, postal_cd, district_size, percent, n_districts_size, n_districts, n_schools, n_students)

wd <- "~/Desktop/ficher/Shiny"
setwd(wd)

# export
write.csv(services, "services_received_shiny.csv", row.names = FALSE)
write.csv(districts, "districts_shiny.csv", row.names = FALSE)
write.csv(locale_cuts, "locale_cuts.csv", row.names = FALSE)
write.csv(size_cuts, "size_cuts.csv", row.names = FALSE)