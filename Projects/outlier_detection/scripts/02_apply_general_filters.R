# clear the console
cat("\014")
rm(list=ls())

# disable scientific notation
options(scipen=999)

#packages needed
packages.to.install <- c("dplyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)

# load csv files
# deluxe districts
d_16_all <- read.csv( paste0("../data/mode/crusher_dd_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)
d_17_all <- read.csv( paste0("../data/mode/crusher_dd_fy2017_", Sys.Date(), ".csv"), as.is = TRUE)
# services received
s_16_all <- read.csv(  paste0("../data/mode/crusher_sr_fy2016_", Sys.Date(), ".csv"), as.is = TRUE)
s_17_all <- read.csv(  paste0("../data/mode/crusher_sr_fy2017_", Sys.Date(), ".csv"), as.is = TRUE)


# Munge Deluxe Districts
logical <- c("exclude_from_ia_analysis", "exclude_from_ia_cost_analysis", "exclude_from_wan_analysis",
               "exclude_from_wan_cost_analysis", "exclude_from_current_fiber_analysis", "include_in_universe_of_districts",
               "meeting_2014_goal_no_oversub", "meeting_2014_goal_oversub", 
               "meeting_2018_goal_no_oversub", "meeting_2018_goal_oversub")
logical17 <- append(logical,c("meeting_to_not_meeting_connectivity", "meeting_to_not_meeting_affordability"))

d_16_all[, logical] <- sapply(d_16_all[, logical], function(x) ifelse(x == "t", TRUE, 
                                                                      ifelse(x =="f", FALSE, x)))
d_17_all[, logical17] <- sapply(d_17_all[, logical17], function(x) ifelse(x == "t", TRUE,
                                                                     ifelse(x == "f", FALSE, x)))
d_16 <- d_16_all %>%
          filter(exclude_from_ia_analysis == FALSE,
                 include_in_universe_of_districts==TRUE,
                 postal_cd != 'AK') %>%
          select(esh_id,postal_cd,locale,district_size,ia_bandwidth_per_student_kbps,ia_monthly_cost_per_mbps,change_in_bw_tot,change_in_bw_pct,change_in_cost_tot,change_in_cost_pct)
d_17 <- d_17_all %>%
          filter(exclude_from_ia_analysis == FALSE,
                 include_in_universe_of_districts==TRUE,
                 postal_cd != 'AK') %>%
          select(esh_id,postal_cd,locale,district_size,ia_bandwidth_per_student_kbps,ia_monthly_cost_per_mbps,change_in_bw_tot,change_in_bw_pct,change_in_cost_tot,change_in_cost_tot_nb,change_in_cost_pct,meeting_to_not_meeting_connectivity,meeting_to_not_meeting_affordability)


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
  
  
  output <- data %>%
            filter(
              # exclude Alaska from consideration since analysis likely involves costs
              recipient_postal_cd != "AK", #applicant
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
            select(line_item_id, purpose, bandwidth_in_mbps, connect_category, line_item_recurring_elig_cost, line_item_total_num_lines) %>%
            mutate(
              monthly_cost_per_circuit = line_item_recurring_elig_cost / line_item_total_num_lines,
              monthly_cost_per_mbps = monthly_cost_per_circuit / bandwidth_in_mbps
             ) 
  return(output)
}

s_16=munge_sr(s_16_all)

#while 2017 data is still dirty
s_17=s_17_all %>%
  filter(
  recipient_postal_cd != "AK",
  erate == 't') %>%
  select(line_item_id, purpose, bandwidth_in_mbps, connect_category, line_item_recurring_elig_cost, line_item_total_num_lines) %>%
  mutate(
    monthly_cost_per_circuit = line_item_recurring_elig_cost / line_item_total_num_lines,
    monthly_cost_per_mbps = monthly_cost_per_circuit / bandwidth_in_mbps
  )

#s_17=munge_sr(s_17_all)

# export intermediate data
write.csv(d_16, "../data/intermediate/d16_custom_filters.csv", row.names = FALSE)
write.csv(s_16, "../data/intermediate/s16_custom_filters.csv", row.names = FALSE)
write.csv(d_17, "../data/intermediate/d17_custom_filters.csv", row.names = FALSE)
write.csv(s_17, "../data/intermediate/s17_custom_filters.csv", row.names = FALSE)
