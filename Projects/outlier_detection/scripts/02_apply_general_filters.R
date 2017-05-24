# clear the console
cat("\014")
rm(list=ls())

# disable scientific notation
options(scipen=999)

#packages needed
packages.to.install <- c("magrittr","dplyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(magrittr)
library(dplyr)

# load csv files
# deluxe districts
d_16_all <- read.csv( paste0("../data/mode/crusher_dd_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)
#d_17_all <- read.csv( paste0("../data/mode/crusher_dd_fy2017_", Sys.Date(), ".csv"), as.is = TRUE)
# services received
s_16_all <- read.csv(  paste0("../data/mode/crusher_sr_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)
#s_17_all <- read.csv(  paste0("../data/mode/crusher_sr_fy2017_", Sys.Date(), ".csv"), as.is = TRUE)



# Munge Deluxe Districts
logical <- c("exclude_from_ia_analysis", "exclude_from_ia_cost_analysis", "exclude_from_wan_analysis",
             "exclude_from_wan_cost_analysis", "exclude_from_current_fiber_analysis", "include_in_universe_of_districts",
             "meeting_2014_goal_no_oversub", "meeting_2014_goal_oversub", 
             "meeting_2018_goal_no_oversub", "meeting_2018_goal_oversub", 
             "at_least_one_line_not_meeting_broadband_goal", "meeting_knapsack_affordability_target",
             "received_c2_15", "received_c2_16", "budget_used_c2_15", "budget_used_c2_16", "upgrade_indicator")
d_16_all[, logical] <- sapply(d_16_all[, logical], function(x) ifelse(x == "t", TRUE, 
                                                                      ifelse(x == "f", FALSE, x)))
#d_17_all[, logical] <- sapply(d_17_all[, logical], function(x) ifelse(x == "t", TRUE, 
#                                                                      ifelse(x == "f", FALSE, x)))
d_16 <- d_16_all %>%
          filter(exclude_from_ia_analysis == FALSE,
                 include_in_universe_of_districts==TRUE)
# d_17 <- d_17_all %>%
#   filter(exclude_from_ia_analysis == FALSE,
#   include_in_universe_of_districts==TRUE)

# Munge Services Received
## ensure all binary columns appear as TRUE/FALSE rather than t/f (error unique to the R script)
## ensure all numeric columns are numeric, rather than character

munge_sr <- function(data) {
  logical <- c("recipient_include_in_universe_of_districts", "recipient_exclude_from_ia_analysis",
               "erate", "consortium_shared")
  numeric <- c("line_item_total_num_lines")
  
  data[, logical] <- sapply(data[, logical], function(x) ifelse(x %in% "t", TRUE, 
                                                                        ifelse(x %in% "f", FALSE, x)))
  data[, numeric] <- sapply(data[, numeric], function(x) as.numeric(x))
  
  # filter down to line items that are in our consideration; this would most likely be generally applicable to all outlier analysis
  # for instance, filter dataset so that we only consider
  
  output <- data %>%
            filter(
              # exclude Alaska from consideration since analysis likely involves costs
              recipient_postal_cd != "AK",
              # district inclusion
              recipient_include_in_universe_of_districts == TRUE,
              # cleanliness
              recipient_exclude_from_ia_analysis == FALSE,
              inclusion_status %in% c("clean_with_cost"),
              # erate
              erate == TRUE,
              # line item must have no special construction tag
              grepl('special_construction_tag', open_tags) == FALSE,
              # non-duplicates
              !duplicated(line_item_id)) %>%
            select(line_item_id, purpose, bandwidth_in_mbps, connect_category, line_item_recurring_elig_cost, line_item_total_num_lines, open_flags,
                   recipient_exclude_from_ia_analysis, inclusion_status,
                   recipient_id, recipient_postal_cd) %>%
            mutate(
              monthly_cost_per_circuit = line_item_recurring_elig_cost / line_item_total_num_lines,
              monthly_cost_per_mbps = monthly_cost_per_circuit / bandwidth_in_mbps
             ) 
  return(output)
}

s_16=munge_sr(s_16_all)

#while 2017 data is still dirty
# s_17=s_17_all %>%
#   filter(
#   recipient_include_in_universe_of_districts == TRUE,
#     # non-duplicates
#     !duplicated(line_item_id)) %>%
#   select(line_item_id, purpose, bandwidth_in_mbps, connect_category, line_item_recurring_elig_cost, line_item_total_num_lines, open_flags,
#          recipient_exclude_from_ia_analysis, inclusion_status,
#          recipient_id, recipient_postal_cd) %>%
#   mutate(
#     monthly_cost_per_circuit = line_item_recurring_elig_cost / line_item_total_num_lines,
#     monthly_cost_per_mbps = monthly_cost_per_circuit / bandwidth_in_mbps
#   ) 

# export intermediate data
write.csv(d_16, "../data/intermediate/d16_custom_filters.csv", row.names = FALSE)
write.csv(s_16, "../data/intermediate/s16_custom_filters.csv", row.names = FALSE)
#write.csv(d_17, "../data/intermediate/d17_custom_filters.csv", row.names = FALSE)
#write.csv(s_17, "../data/intermediate/s17_custom_filters.csv", row.names = FALSE)
