### PRELIMINARY AND UNCHECKED ###

# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "stringdist", "tidyr")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Google Drive/R/Service Providers/data/intermediate/")

###
# load data
services <- read.csv("02_clean_services.csv", as.is = TRUE)
deluxe <- read.csv("~/Google Drive/R/Service Providers/data/mode/deluxe_districts_20160229.csv", as.is = TRUE)

# convert columns
deluxe$ia_cost_per_mbps <- as.numeric(deluxe$ia_cost_per_mbps)
deluxe$ia_bandwidth_per_student <- as.numeric(deluxe$ia_bandwidth_per_student)
deluxe$wan_bandwidth_per_student <- as.numeric(deluxe$wan_bandwidth_per_student)

# order locale and districts
deluxe$locale <- factor(deluxe$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
deluxe$district_size <- factor(deluxe$district_size, levels = c("Tiny", "Small", "Medium", "Large", "Mega"))

# tag districts that receive neca services
# separate IA / WAN, NECA/possible NECA

deluxe$receives_neca_internet <- ifelse(deluxe$esh_id %in% services[services$neca == 1 & services$internet_conditions_met == 'true', ]$esh_id, 1, 0)
deluxe$maybe_receives_neca_internet <- ifelse(deluxe$esh_id %in% services[services$possible_neca == 1 & services$internet_conditions_met == 'true', ]$esh_id, 1, 0)

deluxe$receives_neca_wan <- ifelse(deluxe$esh_id %in% services[services$neca == 1 & services$wan_conditions_met == 'true', ]$esh_id, 1, 0)
deluxe$maybe_receives_neca_wan <- ifelse(deluxe$esh_id %in% services[services$possible_neca == 1 & services$wan_conditions_met == 'true', ]$esh_id, 1, 0)

deluxe$receives_neca_upstream <- ifelse(deluxe$esh_id %in% services[services$neca == 1 & services$upstream_conditions_met == 'true', ]$esh_id, 1, 0)
deluxe$maybe_receives_neca_upstream <- ifelse(deluxe$esh_id %in% services[services$possible_neca == 1 & services$upstream_conditions_met == 'true', ]$esh_id, 1, 0)


# column which indicates bandwith needs for each NECA district
# assuming 1M per student applying concurrency
deluxe$bw_needs_in_mbps <- (deluxe$num_students * 1) / deluxe$ia_oversub_ratio

# round bandwidth needs since circuitz are purchased in round numbers
# note that maximum of bw_neds_in_mbps for deluxe districts that receive NECA internet is 8,950 mbps
# only considers up to 10g circuits :)
deluxe$bw_needs_in_mbps_rnd <-
  ifelse(deluxe$bw_needs_in_mbps <= 110, 100,
       ifelse(deluxe$bw_needs_in_mbps <= 220, 200, 
              ifelse(deluxe$bw_needs_in_mbps <= 550, 500, 
                     ifelse(deluxe$bw_needs_in_mbps <= 1100, 1000,
                                   ifelse(deluxe$bw_needs_in_mbps <= 2200, 2000,
                                          ifelse(deluxe$bw_needs_in_mbps <= 5500, 5000, 10000))))))

# additional bandwidth_in_mbps column for join!
deluxe$bandwidth_in_mbps <- deluxe$bw_needs_in_mbps_rnd

# create cost per mbps column 
services$monthly_cost_per_mbps <- services$monthly_cost_per_line / services$bandwidth_in_mbps

# target pricing
# national median for lit fiber at various bandwidths
# starting point: lit fiber for IA (Ethernet at 100 mbps or greater or explicilty lit fiber)
lit_ia <- 
which(services$internet_conditions_met == 'true' &
  # lit fiber
  (services$connect_type == 'Lit Fiber Service' |
        (services$connect_type == 'Ethernet' & services$bandwidth_in_mbps >= 100)) &
  services$bandwidth_in_mbps %in% c(100, 200, 500, 1000, 2000, 5000, 10000))
#    services$bandwidth_in_mbps == 100)

# target pricing
# Lit fiber per state: 100, 200, 500, 1000, 1500, 2000, 5000, 10000
# target pricing eachs state: median prices 100, 500mb, 1g lit fiber 
# national median as target pricing (lit fiber)
target_ia_pricing <-
services[lit_ia, ] %>%
  group_by(bandwidth_in_mbps) %>%
  summarize(national_median_ia_fiber = median(monthly_cost_per_mbps, na.rm = TRUE))
#rename
target_ia_pricing <- dplyr::rename(target_ia_pricing, bw_needs_in_mbps_rnd = bandwidth_in_mbps)  


# NECA Current pricing
# calculate NECA cost per mbps for each state (NOT PROVIDER SPECIFIC) 
# tariff bands 100, 200, 500, 1000, 1500, 2000, 5000, 10000
costs_ia_all <- 
 services[services$neca == 1 & 
             services$internet_conditions_met == 'true', ] %>%
#            services$bandwidth_in_mbps %in% c(100, 200, 500, 1000, 2000, 5000, 10000), ] %>%
  group_by(postal_cd, bandwidth_in_mbps) %>%
  summarize(n = n(),
            neca_monthly_cost_per_mbps = median(monthly_cost_per_mbps, na.rm = TRUE))

####
# grab the name of the NECA provider using the services table
#neca_ia <- which(services$internet_conditions_met == 'true' & services$neca == 1)
#deluxe <- dplyr::left_join(deluxe, services[neca_ia, c("esh_id", "service_provider_name")], by = c("esh_id"))

# merge cost per mbps for each state median - bandwidth bucket
deluxe <- dplyr::left_join(deluxe, costs_ia_all[, c("postal_cd", "bandwidth_in_mbps", "neca_monthly_cost_per_mbps")], 
                by = c("postal_cd", "bandwidth_in_mbps"))

deluxe <- rename(deluxe,neca_monthly_cost_per_mbps_0 = neca_monthly_cost_per_mbps)
# check whether NECA IA districts are missing the NECA pricing
# length(which(deluxe$receives_neca_internet == 1 & is.na(deluxe$neca_monthly_cost_per_mbps)))
missing_specific_price <- which(deluxe$receives_neca_internet == 1 & is.na(deluxe$neca_monthly_cost_per_mbps_0))
deluxe[missing_specific_price, ]$bandwidth_in_mbps <- NA

# for those missing specific tariff band pricing, just match to state median NECA pricing 
# for whatever bandwidth available
costs_ia_all2 <- 
  services[services$neca == 1 & 
             services$internet_conditions_met == 'true', ] %>%
  group_by(postal_cd) %>%
  summarize(n = n(),
            neca_monthly_cost_per_mbps= median(monthly_cost_per_mbps, na.rm = TRUE))

deluxe <- dplyr::left_join(deluxe, costs_ia_all2[, c("postal_cd", "neca_monthly_cost_per_mbps")], 
                           by = c("postal_cd"))
deluxe$neca_monthly_cost_per_mbps_0 <- ifelse(is.na(deluxe$neca_monthly_cost_per_mbps_0),
                                        deluxe$neca_monthly_cost_per_mbps, 
                                        deluxe$neca_monthly_cost_per_mbps_0)

deluxe$neca_monthly_cost_per_mbps <- NULL
deluxe <- dplyr::rename(deluxe, neca_monthly_cost_per_mbps = neca_monthly_cost_per_mbps_0)

# total projected cost of IA, assuming current pricing, and  bandwidth needs of 1 mbps per student (+ concurrency ratio)
# use the rounded columns
deluxe$projected_total_ia_monthly_cost <- deluxe$bw_needs_in_mbps_rnd * deluxe$neca_monthly_cost_per_mbps

# merge in state median pricing
deluxe <- dplyr::left_join(deluxe, target_ia_pricing, by = c("bw_needs_in_mbps_rnd"))

# total projected cost of IA, assuming national median pricing for each fiber bucket,  bandwidth needs of 1 mbps per student (+ concurrency ratio)
deluxe$national_target_total_ia_monthly_cost <- deluxe$bw_needs_in_mbps_rnd * deluxe$national_median_ia_fiber

# total projects cost of IA, assuming $3 per mbps
deluxe$target_total_ia_monthly_cost <- deluxe$bw_needs_in_mbps_rnd * 3

############
# research questions
# IA
# cross table!
#table(deluxe[deluxe$receives_neca_internet == 1, ]$locale, deluxe[deluxe$receives_neca_internet == 1, ]$district_size)

# WAN
#table(deluxe[deluxe$receives_neca_wan == 1, ]$locale, deluxe[deluxe$receives_neca_wan == 1, ]$district_size)

## districts
# How many districts receive bundled internet services from NECA providers?: 586 - 988 districts out of 7,345 clean districts
nrow(deluxe[deluxe$receives_neca_internet == 1, ])
nrow(deluxe[deluxe$maybe_receives_neca_internet == 1, ])
nrow(deluxe)

# How many districts receive upstream services from NECA providers?: 167 - 503 districts
nrow(deluxe[deluxe$receives_neca_upstream == 1, ])
nrow(deluxe[deluxe$maybe_receives_neca_upstream == 1, ])

# How many districts receive WAN services from NECA providers?: 352 - 899 districts
nrow(deluxe[deluxe$receives_neca_wan == 1, ])
nrow(deluxe[deluxe$maybe_receives_neca_wan == 1, ])

## campuses
# How many campuses are in districts that receive bundled internet services from NECA providers?: 2,774 - 7,286
sum(deluxe[deluxe$receives_neca_internet == 1, ]$num_campuses)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$num_campuses)
sum(deluxe$num_campuses)
# 47,146 campuses total in clean data

# How many campuses are in districts that receive upstream services from NECA providers?: 767 - 4471
sum(deluxe[deluxe$receives_neca_upstream == 1, ]$num_campuses - 1)
sum(deluxe[deluxe$maybe_receives_neca_upstream == 1, ]$num_campuses - 1)

# How many campuses are in districts that receive WAN services from NECA providers?: 2,188 - 6,298 campuses
# subtract 1 from the WAN compus figures 
sum(deluxe[deluxe$receives_neca_internet == 1, ]$num_campuses - 1)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$num_campuses - 1)

## students
# How many students are in districts that receive bundled internet services from NECA providers?: 1,378,934 - 4,496,555
sum(deluxe[deluxe$receives_neca_internet == 1, ]$num_students)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$num_students)
sum(deluxe$num_students)
# # 28.6 million total students in clean data

# How many students are in districts that receive upstream services from NECA providers?: 475,932 - 3,261,156
sum(deluxe[deluxe$receives_neca_upstream == 1, ]$num_students)
sum(deluxe[deluxe$maybe_receives_neca_upstream == 1, ]$num_students)

# How many students are in districts that receive WAN services from NECA providers?: 2,723,095 - 8,820,150
sum(deluxe[deluxe$receives_neca_wan == 1, ]$num_students)
sum(deluxe[deluxe$maybe_receives_neca_wan == 1, ]$num_students)

# How many of districts/campuses/students have <= 100 Mbps?
# Bundled IA
ia_low_bw <- which(deluxe$receives_neca_internet == 1 &
                  (deluxe$num_students * deluxe$ia_bandwidth_per_student) / 1000 <= 100)

ia_low_bw_maybe <- which(deluxe$maybe_receives_neca_internet == 1 &
                     (deluxe$num_students * deluxe$ia_bandwidth_per_student) / 1000 <= 100)


nrow(deluxe[ia_low_bw, ])
# 254 districts
sum(deluxe[ia_low_bw, ]$num_campuses)
sum(deluxe[ia_low_bw_maybe, ]$num_campuses)

# 388 - 603 campuses
sum(deluxe[ia_low_bw, ]$num_students)
sum(deluxe[ia_low_bw_maybe, ]$num_students)
# 94,610 - 174,961students
rm(ia_low_bw)

# WAN
wan_low_bw <- which(deluxe$receives_neca_wan == 1 &
                      (deluxe$num_students * deluxe$wan_bandwidth_per_student) / 1000 <= 100)
wan_low_bw_maybe <- which(deluxe$maybe_receives_neca_wan == 1 &
                      (deluxe$num_students * deluxe$wan_bandwidth_per_student) / 1000 <= 100)

nrow(deluxe[wan_low_bw, ])
# 72 districts
sum(deluxe[wan_low_bw, ]$num_campuses)
sum(deluxe[wan_low_bw_maybe, ]$num_campuses)
# 198 - 370 campuses
sum(deluxe[wan_low_bw, ]$num_students)
sum(deluxe[wan_low_bw_maybe, ]$num_students)
# 71,578 - 142,794 students
rm(wan_low_bw)

#How many of these schools (campuses?) have <= 100 Mbps but more than 100 students
# Bundled Internet
ia_low_bw_large <- which(deluxe$receives_neca_internet == 1 &
                           (deluxe$num_students * deluxe$ia_bandwidth_per_student) / 1000 <= 100 &
                           deluxe$num_students > 100)
ia_low_bw_large_maybe <- which(deluxe$maybe_receives_neca_internet == 1 &
                           (deluxe$num_students * deluxe$ia_bandwidth_per_student) / 1000 <= 100 &
                           deluxe$num_students > 100)

nrow(deluxe[ia_low_bw_large, ])
# 193 districts
sum(deluxe[ia_low_bw_large, ]$num_campuses)
sum(deluxe[ia_low_bw_large_maybe, ]$num_campuses)
# 323 - 510 campuses
sum(deluxe[ia_low_bw_large, ]$num_students)
sum(deluxe[ia_low_bw_large_maybe, ]$num_students)

# 91,520 -170,340 students
rm(ia_low_bw_large)

# WAN
wan_low_bw_large <- which(deluxe$receives_neca_wan == 1 &
                            (deluxe$num_students * deluxe$wan_bandwidth_per_student) / 1000 <= 100 &
                            deluxe$num_students > 100)
nrow(deluxe[wan_low_bw_large, ])
# 72 districts
sum(deluxe[wan_low_bw_large, ]$num_campuses)
# 198 campuses
sum(deluxe[wan_low_bw_large, ]$num_students)
# 71,578 students
rm(wan_low_bw_large)

# How much would it cost for districts that received bundled NECA IA to all upgrade to 1 Mbps per student given current NECA pricing?
# Bundled IA (district level view)

# CURRENT bw purchased by NECA districts
sum(deluxe[deluxe$receives_neca_internet == 1, ]$total_ia_bw_mbps)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$total_ia_bw_mbps)
# 253,582 - 644,421 mbps 
sum(deluxe[deluxe$receives_neca_internet == 1, ]$total_ia_monthly_cost, na.rm = TRUE)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$total_ia_monthly_cost, na.rm = TRUE)
# $3,643,179 - $5,911,378

# NEEDED bw 
sum(deluxe[deluxe$receives_neca_internet == 1, ]$bw_needs_in_mbps)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$bw_needs_in_mbps)
# 886,744 - 2,555,757 mbps

# NEEDED bw rounded!
sum(deluxe[deluxe$receives_neca_internet == 1, ]$bw_needs_in_mbps_rnd)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$bw_needs_in_mbps_rnd)
# 900,300 - 2,056,000 mbps

sum(deluxe[deluxe$receives_neca_internet == 1, ]$projected_total_ia_monthly_cost, na.rm = TRUE)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$projected_total_ia_monthly_cost, na.rm = TRUE)
# based on rounded bw needs
# $18,166,606 - $39,710,448

# how much would that save the schools in districtsaffected by NECA tariffs(at 1 Mbps per student)? 
sum(deluxe[deluxe$receives_neca_internet == 1, ]$national_target_total_ia_monthly_cost, na.rm = TRUE)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$national_target_total_ia_monthly_cost, na.rm = TRUE)
# $3,197,198 - $6,217,504

sum(deluxe[deluxe$receives_neca_internet == 1, ]$target_total_ia_monthly_cost, na.rm = TRUE)
sum(deluxe[deluxe$maybe_receives_neca_internet == 1, ]$target_total_ia_monthly_cost, na.rm = TRUE)
# $2,700,900 - $6,168,000
