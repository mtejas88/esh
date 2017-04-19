## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

## source functions
source("src/define_broadband.R")

##**************************************************************************************************************************************************
## READ IN DATA

frn.line.items.2016 <- read.csv("data/raw/frn_line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
frn.meta.data.2016 <- read.csv("data/raw/frn_meta_data_2016.csv", as.is=T, header=T, stringsAsFactors=F)
line.items.2016 <- read.csv("data/raw/line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## CLEAN DATA

## first, merge together line item and meta data
frn.dta <- merge(frn.line.items.2016, frn.meta.data.2016[,c('frn', names(frn.meta.data.2016)[!names(frn.meta.data.2016) %in% names(frn.line.items.2016)])],
                 by='frn', all.x=T)

## look into how often was "Not Broadband" changed to a Broadband category
## first, translate the raw line items to whether they came in as not broadband
frn.dta <- define_broadband(frn.dta)

## subset line.items to those that are fit for analysis
line.items.2016 <- line.items.2016[which(line.items.2016$exclude == FALSE),]
## append "clean" to each variable name in line.items
names(line.items.2016)[names(line.items.2016) != 'id'] <- paste(names(line.items.2016)[names(line.items.2016) != 'id'], "clean", sep='.')

## merge in cleaned data
dta <- merge(frn.dta, line.items.2016, by='id', all.y=T)

##**************************************************************************************************************************************************
## examine how often line items that came in as Not Broadband changed to Broadband

## 99% (222,413 / 224,675) stayed Not Broadband
sub.bb <- dta[which(dta$broadband == FALSE),]
table(sub.bb$connect_category)

##**************************************************************************************************************************************************

## Format data for Random Forest
## requirements:
## 1) no categorical variables with more than 32 factors
## 2) change the remaining categorical variables to factors
## 3) no NA fields

## 1st Attempt: Connect Category (defined as the class variable)
## subset the dataset to the dirty columns plus the clean version of connect_type
dta$class <- dta$connect_category.clean
## the class frequencies of connect category are imbalanced
prop.table(table(dta$class))

## based on the investigation above, we can confidently ignore "Not Broadband" line items for now
dta <- dta[which(dta$broadband == TRUE),]

dta.ml <- dta[,names(dta)[!names(dta) %in% names(dta)[grepl(".clean", names(dta))]]]

##================================================================================================
## Translating character variables to factors

## change all categorical variables to factors
#str(dta.ml)
character_vars <- lapply(dta.ml, class) == "character"
character_vars <- character_vars[character_vars == TRUE]
dta.ml[,names(character_vars)] <- lapply(dta.ml[,names(character_vars)], as.factor)
#str(dta.ml)
num_factor_levels <- sapply(dta.ml[,sapply(dta.ml, is.factor)], nlevels)

## need to remove the categorical variables with greater than 32 levels
names(num_factor_levels)[num_factor_levels >= 32]
## but first, convert the postal_cd variable to integer
dta.ml$postal_cd <- unclass(dta.ml$postal_cd)
## now remove the variables that have more than 32 factors
factors.over.32 <- names(num_factor_levels)[num_factor_levels >= 32 & names(num_factor_levels) != "postal_cd"]
dta.ml <- dta.ml[,which(!names(dta.ml) %in% factors.over.32)]

## also remove variables that only have one factor
dta.ml <- dta.ml[,which(!names(dta.ml) %in% names(num_factor_levels)[num_factor_levels == 1])]

## also take out id variables (ones that are specific to the line item/FRN)
dta.ml <- dta.ml[,which(!names(dta.ml) %in% c('id','frn', 'applicant_ben', 'application_number', 'line_item'))]

##================================================================================================
## Removing NA fields

## how many rows do not have an NA in the field?
## 0! all rows have at least 1 NA
perc.no.na <- rowSums(!is.na(dta.ml)) / ncol(dta.ml)
## 1 means all columns do not have an NA
table(perc.no.na)

## find out which variables have the highest percentage of being NA
na_percentage <- function(dta){
  na.percentage <- data.frame(matrix(NA, nrow=ncol(dta), ncol=2))
  names(na.percentage) <- c('variable', 'percentage.na.entries')
  for (i in 1:ncol(dta)){
    na.percentage$variable[i] <- names(dta)[i]
    if (NA %in% dta[,i]){
      na.percentage$percentage.na.entries[i] <- (length(which(is.na(dta[,i]))) / nrow(dta))*100
    }
  }
  na.percentage <- na.percentage[order(na.percentage$percentage.na.entries, decreasing=T),]
  return(na.percentage)
}

na.percentage <- na_percentage(dta.ml)
high.na.vars <- na.percentage$variable[which(na.percentage$percentage.na.entries > 1)]
high.na.vars
## take out variables with a high NA percentage:
##[1] "award_date"                                         "expiration_date"
##[3] "service_start_date"                                 "contract_expiry_date"
##[5] "total_monthly_ineligible_charges"                   "total_eligible_pre_discount_recurring_charges"
##[7] "total_eligible_pre_discount_one_time_charges"       "number_of_erate_eligible_strands"
##[9] "total_number_of_terms_in_months"                    "baloon_payment"
##[11] "annual_interest_rate"                               "total_amount_financed"
##[13] "match_amount"                                       "source_of_matching_funds"
##[15] "pricing_confidentiality_type"                       "special_construction_state_tribal_match_percentage"
##[17] "total_project_plant_route_feet"                     "average_cost_per_foot_of_outside_plant"
##[19] "total_strands"                                      "fiber_type"
##[21] "fiber_sub_type"                                     "burstable_speed_units"
##[23] "burstable_speed"                                    "remaining_voluntary_extensions"
##[25] "total_remaining_contract_length"                    "user_entered_establishing_fcc_form470"
##[27] "establishing_fcc_form470"

## taking out the variables with high NA percentage
dta.ml <- dta.ml[,which(!names(dta.ml) %in% high.na.vars)]

## how many rows do not have an NA in the field now?
perc.no.na <- rowSums(!is.na(dta.ml)) / ncol(dta.ml)
## 1 means all rows do not have an NA
table(perc.no.na)

## remove the last rows that have an NA
dta.ml <- dta.ml[complete.cases(dta.ml),]


## OLD NOTES:
## consider over-sampling since we don't have a lot of data (tens of thousands of records or less)
## also play around with different resampled ratios
## add copies of lower frequency categories, using SMOTE package

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(dta.ml, "data/interim/ml_connect_type_2016.csv", row.names=F)
