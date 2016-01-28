### PRELIMINARY AND UNCHECKED ###

# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "ggmap", "ggplot2", "raster", "maps", "mapproj")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Google Drive/R/Illinois CR/data/export/for_graphing")


###
# load data
counties <- read.csv("~/Google Drive/R/Illinois CR/data/mode/il_county_names.csv", as.is = TRUE)
deluxe <- read.csv("~/Google Drive/R/Illinois CR/data/mode/deluxe_districts_20160105.csv", as.is = TRUE)
services_all <- read.csv("~/Google Drive/R/Illinois CR/data/mode/services_received_20160105.csv", as.is = TRUE)
rep <- read.csv("~/Google Drive/R/Illinois CR/data/intermediate/rep_sample_20160105.csv", as.is = TRUE)
sp_cat <- read.csv("~/Google Drive/R/Illinois CR/data/intermediate/sp_categories.csv", as.is = TRUE)

# merge county name data to deluxe table
deluxe <- merge(deluxe, counties, all.x = TRUE, all.y = FALSE, by = c("nces_cd"))

# simplify county names
deluxe$county <- gsub("[[:space:]]COUNTY$", "", deluxe$CONAME)
deluxe$CONAME <- NULL


## filtering
# check filter conditions
services_all <- services_all[#services$exclude_from_analysis == FALSE & 
                       services_all$shared_service == "District-dedicated", ]

# select relevant columns or create ones if ncessary
services_all <- dplyr::select(services_all, esh_id = district_esh_id, purpose, bandwidth_in_mbps, open_flags,
                          total_monthly_cost = line_item_total_monthly_cost, item_num_lines = quantity_of_lines_received_by_district,
                          service_provider_name, connect_type, internet_conditions_met, wan_conditions_met, 
                          isp_conditions_met, upstream_conditions_met,
                          shared_service, exclude_from_analysis)
services_all$item_num_lines <- as.numeric(services_all$item_num_lines)

services_all$monthly_cost_per_circuit <- services_all$total_monthly_cost / services_all$item_num_lines
services_all$monthly_cost_per_mbps <- services_all$monthly_cost_per_circuit / services_all$bandwidth_in_mbps

# fiber
services_all$fiber <- ifelse(grepl("Fiber", services_all$connect_type), 1, 0)

# total annual cost column
services_all$total_annual_cost <- services_all$total_monthly_cost * 12

# rep. sample
deluxe$rep_sample <- ifelse(deluxe$nces_cd %in% rep$nces_cd, 1, 0)

# merge columns from deluxe districst table
deluxe <- dplyr::select(deluxe, esh_id, nces_cd, rep_sample, meeting_2014_goal = meeting_2014_goal_no_oversub, county)
services_all <- merge(services_all, deluxe, all.x = TRUE, all.y = FALSE, by = c("esh_id"))

# which conditions
ia <- which(services_all$internet_conditions_met == TRUE)
wan <- which(services_all$wan_conditions_met == TRUE)

# filter to IA
services <- services_all[ia, ]

# merge service provider categories
services <- left_join(services, sp_cat, by = c("service_provider_name"))

### analyses

# IA market share

market_share <-
  services %>%
  group_by(reporting_name) %>%
  summarize(n = n(),
            sp_total = sum(total_annual_cost, na.rm = TRUE))
         

market_share <- arrange(market_share, -sp_total)

# number of districts servced
services_rep <- services[services$rep_sample == 1, ]

num_districts_served <- 
services_rep %>%
  group_by(reporting_name) %>%
  summarize(districts_served = length(unique(esh_id)))


# districts meeting goals
services_rep_nodup <- services_rep[!duplicated(services_rep[c("reporting_name", "esh_id")]), ]

num_districts_goal <- 
services_rep_nodup %>%
  group_by(reporting_name) %>%
  summarize(districts_goal = sum(meeting_2014_goal))
    
# merge

summary <- merge(market_share, num_districts_served, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))
summary <- merge(summary, num_districts_goal, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))

# merge on service category
sp_map <- sp_cat[!duplicated(sp_cat[c("reporting_name", "prelim_service_category")]), c("reporting_name", "prelim_service_category")]
summary <- merge(summary, sp_map, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))


# percentages
summary$market_share <- summary$sp_total / sum(services$total_annual_cost)
summary$perc_districts_served <- summary$districts_served / nrow(rep)
summary$perc_districts_goal <- summary$districts_goal / nrow(rep)


# rank by number of districts served
summary <- arrange(summary, -districts_served)

# export
write.csv(summary, "ia_sp_summary.csv", row.names = FALSE)

# service provider cost

top_providers <- 
services[services$reporting_name %in% c("Comcast", "Illinois Century", "AT&T","Delta Comm") &
           services$connect_type == "Lit Fiber Service" & services$bandwidth_in_mbps == 100, ]

top_providers_summary <- 
top_providers %>%
  group_by(reporting_name) %>%
  summarize(n = n(),
            median= median(monthly_cost_per_mbps, na.rm = TRUE))


write.csv(top_providers_summary, "ia_top_providers.csv", row.names = FALSE)


# filter to transport
services <- services_all[wan, ]

# merge service provider categories
services <- left_join(services, sp_cat, by = c("service_provider_name"))

### analyses

# Transport market share

market_share <-
  services %>%
  group_by(reporting_name) %>%
  summarize(n = n(),
            sp_total = sum(total_annual_cost, na.rm = TRUE))


market_share <- arrange(market_share, -sp_total)


# number of districts servced
services_rep <- services[services$rep_sample == 1, ]

num_districts_served <- 
  services_rep %>%
  group_by(reporting_name) %>%
  summarize(districts_served = length(unique(esh_id)))

# districts meeting goals
services_rep_nodup <- services_rep[!duplicated(services_rep[c("reporting_name", "esh_id")]), ]

num_districts_goal <- 
  services_rep_nodup %>%
  group_by(reporting_name) %>%
  summarize(districts_goal = sum(meeting_2014_goal))

# merge

summary <- merge(market_share, num_districts_served, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))
summary <- merge(summary, num_districts_goal, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))

# merge on service category
sp_map <- sp_cat[!duplicated(sp_cat[c("reporting_name", "prelim_service_category")]), c("reporting_name", "prelim_service_category")]
summary <- merge(summary, sp_map, all.x = TRUE, all.y = FALSE, by = c("reporting_name"))


# percentages
summary$market_share <- summary$sp_total / sum(services$total_annual_cost)
summary$perc_districts_served <- summary$districts_served / nrow(rep)
summary$perc_districts_goal <- summary$districts_goal / nrow(rep)


# rank by number of districts served
summary <- arrange(summary, -districts_served)

# export
write.csv(summary, "wan_sp_summary.csv", row.names = FALSE)


# service provider cost

top_providers <- 
  services[services$reporting_name %in% c("Comcast", "AT&T","Charter", "Winstream") &
             services$connect_type == "Lit Fiber Service" & services$bandwidth_in_mbps == 1000, ]

top_providers_summary <- 
  top_providers %>%
  group_by(reporting_name) %>%
  summarize(n = n(),
            median= median(monthly_cost_per_circuit, na.rm = TRUE))

# export
write.csv(top_providers_summary, "wan_top_providers.csv", row.names = FALSE)

## let's analyze iFiber
# filter to CLEAN and district-dedicated data only
services <- services_all[services_all$exclude_from_analysis == FALSE & 
                       services_all$shared_service == "District-dedicated", ]

# counties that are connect through fiber network on the iFibermap:
# http://www.ifiber.org/ifiber/pdf/iFiberMap_Final_Aug2015.pdf
frg_counties <- c("JO DAVIESS", "STEPHENSON", "WINNEBAGO", "BOONE", "MCHENRY", "KANE", 
            "DEKALB", "OGLE", "LEE", "CARROLL", "WHITESIDE", "BUREAU", "LASALLE", 
            "PUTNAM", "MARSHALL")

# which -- districts in the counties on the FRG serviced counties
services$in_frg_region <- ifelse(services$county %in% frg_counties, 1, 0)

# Fiber Resources Group 
services$frg <- ifelse(grepl("Fiber Resources Group", services$service_provider_name), 1, 0)

## FRG stats

frg_stats <- 
  services[services$upstream_conditions_met == TRUE & services$connect_type == "Lit Fiber Service", ] %>%
  group_by(frg) %>%
  summarize(n = n(),
            q25_cost_mbps = quantile(monthly_cost_per_mbps, 0.25, na.rm = TRUE),
            median_cost_mbps = median(monthly_cost_per_mbps, na.rm = TRUE),
            q75_cost_mbps = quantile(monthly_cost_per_mbps, 0.75, na.rm = TRUE))
  

write.csv(frg_stats, "frg_stats.csv", row.names= FALSE)

## ICN stats
  
services$icn <- ifelse(grepl("Illinois Century Network", services$service_provider_name), 1, 0)

services[services$isp_conditions_met == TRUE, ] %>%
  group_by(icn) %>%
  summarize(n = n(),
            q25_cost_mbps = quantile(monthly_cost_per_mbps, 0.25, na.rm = TRUE),
            median_cost_mbps = median(monthly_cost_per_mbps, na.rm = TRUE),
            q75_cost_mbps = quantile(monthly_cost_per_mbps, 0.75, na.rm = TRUE))

  # observation: there are districts that are in cities on the FRG network
#but are themselves not FRG customers
# elgin SD U-46 NCES CD: 1713710
# Hononegah 1719620
# prairie Hill 1732550 --- unclear if it makes a good story
# model district: montmorency CCSD

write.csv(services, "services_received_ifiber.csv", row.names = FALSE)

# districts that do not have iFiber but are in the network
services_sub <- services[services$in_frg_region == 1, ]

frg_districts <- unique(services_sub[services_sub$frg == 1, ]$nces_cd)

services_non_frg_districts <- filter(services_sub, !(nces_cd %in% frg_districts))

deluxe_sub <- deluxe[deluxe$nces_cd %in% services_non_frg_districts$nces_cd, ]

write.csv(deluxe_sub, "districts_of_interest_in_frg_counties.csv", row.names = FALSE)