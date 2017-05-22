# clear the console
cat("\014")
rm(list=ls())

# disable scientific notation
options(scipen=999)

# load csv files
# deluxe districts
#d_16_all <- read.csv(paste0("data/mode/crusher_dd_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)
# services received
#s_16_all <- read.csv(paste0("data/mode/crusher_sr_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)

d_16_all <- read.csv( "/Users/sdelosreyes/Documents/r/outliers/outlier_detection/data/mode/crusher_dd_fy2016_2017-04-20.csv", as.is = TRUE)
# services received
s_16_all <- read.csv( "/Users/sdelosreyes/Documents/r/outliers/outlier_detection/data/mode/crusher_sr_fy2016_2017-04-20.csv", as.is = TRUE)



# Munge Deluxe Districts
logical <- c("exclude_from_ia_analysis", "exclude_from_ia_cost_analysis", "exclude_from_wan_analysis",
             "exclude_from_wan_cost_analysis", "exclude_from_current_fiber_analysis", "include_in_universe_of_districts",
             "meeting_2014_goal_no_oversub", "meeting_2014_goal_oversub", 
             "meeting_2018_goal_no_oversub", "meeting_2018_goal_oversub", 
             "at_least_one_line_not_meeting_broadband_goal", "meeting_knapsack_affordability_target",
             "received_c2_15", "received_c2_16", "budget_used_c2_15", "budget_used_c2_16", "upgrade_indicator")
#numeric <- c()

d_16_all[, logical] <- sapply(d_16_all[, logical], function(x) ifelse(x == "t", TRUE, 
                                                                      ifelse(x == "f", FALSE, x)))

d_16 <- d_16_all %>%
          filter(
            exclude_from_ia_analysis == FALSE
          )

# Munge Services Received
## ensure all binary columns appear as TRUE/FALSE rather than t/f (error unique to the R script)
## ensure all numeric columns are numeric, rather than character

logical <- c("recipient_include_in_universe_of_districts", "recipient_exclude_from_ia_analysis",
             "erate", "consortium_shared")
numeric <- c("line_item_total_num_lines")

s_16_all[, logical] <- sapply(s_16_all[, logical], function(x) ifelse(x == "t", TRUE, 
                                                                      ifelse(x == "f", FALSE, x)))

s_16_all[, numeric] <- sapply(s_16_all[, numeric], function(x) as.numeric(x))

# filter down to line items that are in our consideration; this would most likely be generally applicable to all outlier analysis
# for instance, filter dataset so that we only consider

s_16 <- s_16_all %>%
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


# export intermediate data
#write.csv(s_16, paste0(wd, "intermediate/pre_custom_filters.csv"), row.names = FALSE)
