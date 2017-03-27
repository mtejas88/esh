source("scripts/04_identify_outliers.R")

###
# use case #1 
# identify cost outliers on line item-level data
###

use_case_1 <- function (circuit_size, technology, line_item_purpose) {
  
  output <- s_16 %>%
    filter(
      
      # arguments should be in an array; i.e. c()
      bandwidth_in_mbps %in% circuit_size,
      connect_category %in% technology,
      purpose %in% line_item_purpose
    )
  
  str1 <- paste0("circuit_size_in_mbps: ", circuit_size, collapse = "; ")
  str2 <- paste0("technology: ", technology, collapse = "; ")
  str3 <- paste0("purpose: ", line_item_purpose, collapse = "; ")
  
  use_case_parameters <- paste(str1, str2, str3, sep = " | ")
  output <- cbind(use_case_parameters, output)
  identify_outliers(output, 0.05, "monthly_cost_per_circuit", "line_item_id")
  
}

###
# use case #2
# identify bandwidth outliers based on district-level data
###

use_case_2 <- function (district_locale, size) {
  output <- d_16 %>%
    filter(
      locale %in% district_locale,
      district_size %in% size
    )
  
  str1 <- paste0("district_locale: ", district_locale, collapse = "; ")
  str2 <- paste0("district_size: ", size, collapse = "; ")
  
  use_case_parameters <- paste(str1, str2, sep = " | ")
  output <- cbind(use_case_parameters, output)
  identify_outliers(output, 0.2, "ia_bw_mbps_total", "esh_id")
  
  
}
