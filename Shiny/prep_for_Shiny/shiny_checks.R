wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)


  lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
  #sapply(lib, function(x) install.packages(x))
  sapply(lib, function(x) require(x, character.only = TRUE))
  
  services_check <- read.csv("services_received_shiny.csv", as.is = TRUE)
  districts <- read.csv("districts_shiny.csv", as.is = TRUE)
  # nrow(services) #83203
  # nrow(districts) #13025
  
services_check <- dplyr::filter(services_check, bandwidth_in_mbps == 100)
nrow(services_check)

services_check <- filter(services_check, new_purpose == "Internet")
nrow(services_check)

services_check <- filter(services_check, district_size %in% c("Tiny", "Medium"))
nrow(services_check)
sum(services_check$line_item_total_num_lines)


services_check <- filter(services_check, locale %in% c("Suburban"))
nrow(services_check)
print(sum(services_check$line_item_total_num_lines))


services_check <- filter(services_check, postal_cd %in% c("CA"))
print(sum(services_check$line_item_total_num_lines))

