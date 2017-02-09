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
services <- read.csv("~/Google Drive/R/Service Providers/data/mode/services_received_20160224.csv", as.is = TRUE)
providers <- read.csv("~/Google Drive/R/Service Providers/data/mode/service_provider_categories_20160225.csv", as.is = TRUE)
deluxe <- read.csv("~/Google Drive/R/Service Providers/data/mode/deluxe_districts_20160229.csv", as.is = TRUE)
#line <- read.csv("~/Google Drive/R/Service Providers/data/mode/line_items_20160222.csv", as.is = TRUE)
#neca <- read.csv("~/Google Drive/R/Service Providers/data/neca/neca_members_2016.csv", as.is = TRUE)

# import manually matched NECA providers -- national providers are excluded
neca_review <- read.csv("~/Google Drive/R/Service Providers/data/neca/neca_manual_review_20160309.csv", as.is = TRUE)

# import NECA manual matches -- national providers are included
possible_neca_review <- read.csv("~/Google Drive/R/Service Providers/data/neca/neca_manual_review_20160226.csv", as.is = TRUE)

# take care of un-clean import / rename columns in NECA data
neca_review <- neca_review[, c(2, 5)]
names(neca_review) <- c("neca_name", "service_provider_name")

possible_neca_review <- possible_neca_review[, c(2, 5)]
names(possible_neca_review) <- c("neca_name", "possible_service_provider_name")

# merge
neca_review <- dplyr::left_join(neca_review, possible_neca_review, by = c("neca_name"))

# change column types in deluxe table
deluxe$ia_cost_per_mbps <- as.numeric(deluxe$ia_cost_per_mbps)
deluxe$ia_bandwidth_per_student <- as.numeric(deluxe$ia_bandwidth_per_student)

# join provider SPINS to services
providers <- providers[!duplicated(providers$name), ]
providers<- dplyr::rename(providers, service_provider_name = name)
services <-  left_join(services, providers, by = c("service_provider_name"))

# tagging NECA in three step
# 1. service providers matched through manual review
# 2. additional restriction for small town or rural locale
services$neca <- ifelse(tolower(services$service_provider_name) %in% tolower(neca_review$service_provider_name), 1, 0)
#                        & services$locale %in% c('Rural', 'Small Town'), 1, 0)
services$possible_neca <- ifelse(tolower(services$service_provider_name) %in% tolower(neca_review$possible_service_provider_name), 1, 0)
#                        & services$locale %in% c('Rural', 'Small Town'), 1, 0)

# 2. large service providers who are under neca tariffs only in certain region
# table this part of tagging for now because there is concern that we may be over-tagging
# update per conversation with Jen O. on 2.29.2016

##Armstrong
##Contains ‘Armstrong Tel’ in service_provider_name
##Allocated to a rural & small town locale in NY, PA, WV, MD
armstrong <- 
which(grepl("Armstrong Cable", services$service_provider_name, ignore.case = TRUE) &
        services$locale %in% c("Rural", "Small Town") &
        services$postal_cd %in% c("NY", "PA", "WV", "MD"))

services[armstrong, ]$possible_neca  <- 1
rm(armstrong)

##Centurytel
##Contains ‘CenturyLink’ in service_provider_name
##Allocated to a rural & small town locale in LA, MI, AR, AL, IN, WI, CO, ID, MN, MO, MS, OH, OR, NV, WA, WY

centurylink <- 
  which(grepl("CenturyLink", services$service_provider_name, ignore.case = TRUE) &
          services$locale %in% c("Rural", "Small Town") &
          services$postal_cd %in% c("LA", "MI", "AR", "AL", "IN", "WI", "CO", "ID", "MN", "MO", "MS", "OH", "OR", "NV", "WA", "WY"))

services[centurylink, ]$possible_neca  <- 1
rm(centurylink)

##Citizens Telecommunications
##Contains ‘Citizens Tel’ in service_provider_name
##Allocated to a rural & small town locale in NY, NE, WV, CA, OR, TN, UT, ID, IL, MN, MT, NV
citizenstel <- 
  which(grepl("citizens tel", services$service_provider_name, ignore.case = TRUE) &
          services$locale %in% c("Rural", "Small Town") &
          services$postal_cd %in% c("NY", "NE", "WV", "CA", "OR", "TN", "UT", "ID", "IL", "MN", "MT", "NV"))

services[citizenstel, ]$possible_neca  <- 1
rm(citizenstel)

##Frontier Communications
##Contains ‘Frontier Comm’ in service_provider_name
##Allocated to a rural & small town district in TX, AL, GA, IL, IN, IA, MI, MN, MS, NY, PA, NC, SC, WI

frontier <- 
  which(grepl("Frontier Comm", services$service_provider_name, ignore.case = TRUE) &
          services$locale %in% c("Rural", "Small Town") &
          services$postal_cd %in% c("TX", "AL", "GA", "IL", "IN", "IA", "MI", "MN", "MS", "NY", "PA", "NC", "SC", "WI"))
services[frontier, ]$possible_neca  <- 1
rm(frontier)

##Verizon
##Contains ‘Verizon’ in service_provider_name
##Allocated to a rural & small town district in CA, AZ, DE, FL, MD, NJ, NY, PA, VA, DC, NC

verizon <- 
  which(grepl("Verizon", services$service_provider_name, ignore.case = TRUE) &
          services$locale %in% c("Rural", "Small Town") &
          services$postal_cd %in% c("CA", "AZ", "DE", "FL", "MD", "NJ", "NY", "PA", "VA", "DC", "NC"))
services[verizon, ]$possible_neca  <- 1
rm(verizon)

##Windstream
##Contains ‘Windstream’ in service_provider_name
##Allocated to a rural & small town district in AL, AR, FL, GA, IA, KY, MS, MO, NE, NY, NC, OH, OK, PA, SC

windstream <- 
  which(grepl("windstream", services$service_provider_name, ignore.case = TRUE) &
          services$locale %in% c("Rural", "Small Town") &
          services$postal_cd %in% c("AL", "AR", "FL", "GA", "IA", "KY", "MS", "MO", "NE", "NY", "NC", "OH", "OK", "PA", "SC"))
services[windstream, ]$possible_neca  <- 1
rm(windstream)

# 3. TDS telecom which has many many subsidiaries
# subsidiaries that appear in the NECA data 
# and their SPINs according to website http://www.tdsbusiness.com/e-rate/spin.aspx
# Communication Corporation of Michigan	143001691
# Concord Telephone Exchange	143001627
# Continental Telephone Co.	143001658
# Decatur Telephone Co.	143002261
# Deposit Telephone Co.	143001327
# Dickeyville Telephone, LLC	143001791
# EastCoast Telecom, Inc.	143001813
# Edwards Telephone Co., Inc.	143001329	
# Kearsarge Telephone Co.	143001297
# Leslie County Telephone Co.	143001572
# Lewis River Telephone Co.	143002599
# Lewisport Telephone Co.	143001573	
# Little Miami Communications Corporation	143001661
# Ludlow Telephone Company	143001307
# McClellanville Telephone Co.	143001523	
# Mahanoy & Mahantango Tel. Co.	143001380
# McDaniel Telephone Company	143002600	
# Merchants & FarmersTelephone Co.	143001744	
# Merrimack County Telephone	143001299
# 	Mid-State Telephone Co.	143002119
# 	Mid-Plains Telephone, LLC	143001795
# Midway Telephone Co.	143001809
# Myrtle Telephone Co., Inc	143001621
# New Castle Telephone Co.	143001421
# New London Telephone Co.	143002354
# Norway Telephone Company	143001524
# Oakman Telephone Co.	143001555	
# Oakwood	Oakwood Telephone Company	143001672	
# Oklahoma Communication Systems, Inc.	143002382
# Orchard Farm Telephone Co.	143002359
# Port Byron Telephone Co.	143001347
# Potlatch Telephone Co.	143002520	ID
# Quincy Telephone Co.	143001447
# Riverside Telecom, LLC	143001831
# S & W Telephone Co.	143001755
# Salem Telephone Company	143001577	
# Saluda Mountain Telephone Co.	143001498
# Scandinavia Telephone Co.	143001833
# Service Telephone Co.	143001499
# Shiawassee Telephone Co.	143001719
# Stockbridge & Sherwood Telephone Company	143001840
# The Stoutland Telephone Co.	143002365	
# Strasburg	Strasburg Telephone Co.	143002505
# Sugar Valley Telephone Co.	143001393	
# Tenney Telephone Co.	143001843
# Tipton Telephone	143001762
# Tri-County Telephone Co.	143001763	
# The Vanlue Telephone Company	143001681
# 	Virginia Telephone Co.	143001417
# Warren Telephone Co.	143001283
# Winsted Telephone Company	143002149
# Winterhaven Telephone Co.	143002654
# Wolverine Telephone Co.	143001725

tds <- which(services$spin %in% c(143001691, 143001627, 143001658, 143002261, 143001327, 143001791, 143001813, 
                                  143001329, 143001297, 143001572, 143002599, 143001573, 143001661, 143001307, 
                                  143001523, 143001380, 143002600, 143001744, 143001299, 143002119, 143001795, 
                                  143001809, 143001621, 143001421, 143002354, 143001524, 143001555, 143001672, 
                                  143002382, 143002359,143001347 , 143002520, 143001447, 143001831, 143001755, 
                                  143001577, 143001498, 143001833, 143001499, 143001719, 143001840, 143002365, 
                                  143002505, 143001393, 143001843, 143001762, 143001763, 143001681, 143001417, 
                                  143001283, 143002149, 143002654, 143001725) &
               services$locale %in% c('Rural', 'Small Town')) 

services[tds, ]$neca  <- 1
services[tds, ]$possible_neca <- 1
rm(tds)

# NECA tags?
#sum(services$possible_neca)

write.csv(services, "01_services_tagged_neca.csv", row.names = FALSE)

# version for the engineering team
# no duplicates
services_eng <- services[!duplicated(services$line_item_id), ]
# both are 0
services_eng <- services[services$neca == 1 | services$possible_neca == 1, ]

write.csv(services_eng, "01_services_tagged_neca_eng.csv", row.names = FALSE)
## end