wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)


lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

services_check <- read.csv("services_received_shiny.csv", as.is = TRUE)
districts_check <- read.csv("districts_shiny.csv", as.is = TRUE)


  
data <- districts_check %>%
        filter(exclude_from_analysis == FALSE) %>%
        filter(not_all_scalable == 1) %>%
        filter(postal_cd == "IL")

data <- dplyr::select(data, esh_id, name, postal_cd, c1_discount_rate, not_all_scalable, 
               nga_v2_known_unscalable_campuses, nga_v2_assumed_unscalable_campuses, zero_build_cost_to_district)

#%>%
        group_by(zero_build_cost_to_district) %>%
        summarize(n = n())


data <- services_check %>%
        filter(postal_cd == "PA") %>%
        filter(internet_conditions_met == TRUE) %>%
        filter(band_factor %in% c(50, 100, 200, 500, 1000, 10000))

test <- 
data %>%
  group_by(band_factor) %>% 
  summarise(num_line_items = n(), 
            num_circuits = sum(line_item_total_num_lines),
            min_cost_per_mbps = round(min(monthly_cost_per_mbps, na.rm = TRUE)),
            q25_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.25, na.rm = TRUE)),
            median_cost_per_mbps = round(median(monthly_cost_per_mbps, na.rm = TRUE)),
            q75_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.75, na.rm = TRUE)),
            max_cost_per_mbps = round(max(monthly_cost_per_mbps, na.rm = TRUE)))


# nrow(services) #83203
# nrow(districts) #13025
#services_check <- dplyr::filter(services_check, bandwidth_in_mbps == 100)
#nrow(services_check)
#services_check <- filter(services_check, new_purpose == "Internet")
#nrow(services_check)
#services_check <- filter(services_check, district_size %in% c("Tiny", "Medium"))
#nrow(services_check)
#sum(services_check$line_item_total_num_lines)
#services_check <- filter(services_check, locale %in% c("Suburban"))
#nrow(services_check)
#services_check <- filter(services_check, !new_connect_type %in% c("Lit Fiber"))
#nrow(services_check)
#sum(services_check$line_item_total_num_lines)
#services_check <- filter(services_check, postal_cd %in% c("CA"))
#print(sum(services_check$line_item_total_num_lines))
#table(services_check$connect_type)

