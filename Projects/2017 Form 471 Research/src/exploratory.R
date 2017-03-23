## =========================================
##
## Exploratory Analysis
##
## =========================================

rm(list=ls())

packages.to.install <- c("gridExtra")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

library(gridExtra)

##**************************************************************************************************************************************************
## read in data

frn_line_items <- read.csv("data/interim/frn_line_items.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
recipients_of_services <- read.csv("data/interim/recipients.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
basic_informations <- read.csv("data/interim/basic_informations.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
all_basic_informations <- read.csv("data/interim/all_basic_informations.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
all_recipients_of_services <- read.csv("data/raw/recipients_2017.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)


#reformatting the date fields in basic_informations and all_basic_informations
basic_informations$certified_timestamp <- as.Date(basic_informations$certified_timestamp, "%Y-%m-%d")
all_basic_informations$certified_timestamp <- as.Date(all_basic_informations$certified_timestamp, "%Y-%m-%d")


## Count States, FRNs, FRN Line Items, Functions, Product Types, Purpose, Quantity

frn_fields_count <- c('postal_cd','frn','line_item','function.','type_of_product', 'purpose')

table(frn_line_items$postal_cd)
num_states_and_dc_applied <- length(unique(frn_line_items$postal_cd))
num_frns <- length(unique(frn_line_items$frn))
num_frn_line_items <- length(frn_line_items$line_item)


print(paste(num_states_and_dc_applied,'states (including DC) have applied for a 471.'))
print(paste(num_frns,'distinct FRNS across', num_frn_line_items, 'frn line items'))


table(frn_line_items$postal_cd, useNA = 'ifany')
table(frn_line_items$function., useNA = 'ifany')
table(frn_line_items$type_of_product, useNA = 'ifany')
table(frn_line_items$purpose, useNA = 'ifany')

connect_types <- unique(frn_line_items$type_of_product)
connect_types_max <- aggregate(frn_line_items$bandwidth_in_mbps, by=list(frn_line_items$type_of_product), FUN = max, na.rm=T)
connect_types_min <- aggregate(frn_line_items$bandwidth_in_mbps, by=list(frn_line_items$type_of_product), FUN = min, na.rm=T)
connect_types_median <- aggregate(frn_line_items$bandwidth_in_mbps, by=list(frn_line_items$type_of_product), FUN = median, na.rm=T)
names(connect_types_min) <- c('Connect Type', 'Min Bandwidth')
names(connect_types_median) <- c('Connect Type', 'Median Bandwidth')
names(connect_types_max) <- c('Connect Type', 'Max Bandwidth')
connect_types_df <- merge(x = connect_types_min, y = connect_types_median, by='Connect Type', all=T)
connect_types_df <- merge(x = connect_types_df, y = connect_types_max, by='Connect Type', all=T)

#create a table of the connect types min, med, max instead of plots
pdf("figures/connect_type_bandwidths.pdf",width = 12,height = 12)
grid.table(connect_types_df)
dev.off()

#Want to look at distinct function and type of product combinations
connect_cat_and_types <- frn_line_items[,c('function.','type_of_product')]
connect_cat_and_types <- data.frame(table(connect_cat_and_types))
connect_cat_and_types <- connect_cat_and_types[connect_cat_and_types$Freq > 0,]
connect_cat_and_types <- connect_cat_and_types[order(connect_cat_and_types$function.,connect_cat_and_types$type_of_product),]

#create a table of broadband functions and connect types
pdf("figures/functions_and_connect_types.pdf",width = 12,height = 12)
grid.table(connect_cat_and_types)
dev.off()


#boxplot(frn_line_items$bandwidth_in_mbps ~ frn_line_items$type_of_product, data=frn_line_items)

#hist(frn_line_items$monthly_quantity, xlim=c(0,10), breaks = c(0,1,2,3,4,5,6,7,8,9,10,7000))

## Count Monthly Quantity and monthly cost when = 0
zero_quantity <- nrow(frn_line_items[frn_line_items$monthly_quantity==0,])
zero_recurring_cost <- nrow(frn_line_items[frn_line_items$monthly_recurring_unit_costs==0,])

#counting applicants of broadband by applicant type
num_applications <- table(basic_informations$applicant_type)
#barplot(num_applications)

#summing funding requests of broadband by applicant type
applicant_funding <- aggregate(basic_informations$total_funding_year_commitment_amount_request, by = list(basic_informations$applicant_type), FUN = sum, na.rm=T)
#barplot(applicant_funding$x, names = c(applicant_funding$Group.1))
broadband_funding <- sum(applicant_funding$x)

#counting applicants of broadband by day
num_applications_day <- table(basic_informations$certified_timestamp)
#barplot(num_applications_day)

#summing funding requests of broadband by day
applicant_funding_day <- aggregate(basic_informations$total_funding_year_commitment_amount_request, by = list(basic_informations$certified_timestamp), FUN = sum, na.rm=T)
applicant_funding_day$cumulative_funding <- cumsum(applicant_funding_day$x)
#plot(applicant_funding_day$Group.1, applicant_funding_day$cumulative_funding, type = 'l', xlab = 'date', ylab = 'funding requests', main = 'cumulative sum of broadband funding requests by date')

#counting applicants of all services by applicant type
num_applications_all_services <- table(all_basic_informations$applicant_type)
#barplot(num_applications_all_services)

#summing funding requests of all services by applicant type
all_applicant_funding <- aggregate(all_basic_informations$total_funding_year_commitment_amount_request, by=list(all_basic_informations$applicant_type), FUN = sum, na.rm=T)
pdf("figures/all_funding_by_type.pdf",width = 8,height = 8)
barplot(all_applicant_funding$x, names = c(all_applicant_funding$Group.1), main = 'All funding by applicant type')
dev.off()
all_funding <- sum(all_applicant_funding$x)

#counting applicants of all services by day
num_applications_all_services_day <- table(all_basic_informations$certified_timestamp)
#plot(num_applications_all_services_day, xlab = 'date', ylab = 'num applications', main = 'number of all applicants by date')

#summing funding requests of all services by day
all_applicant_funding_day <- aggregate(all_basic_informations$total_funding_year_commitment_amount_request, by=list(all_basic_informations$certified_timestamp), FUN = sum, na.rm=T)
all_applicant_funding_day$cumulative_funding <- cumsum(all_applicant_funding_day$x)
#plot(all_applicant_funding_day$Group.1, all_applicant_funding_day$cumulative_funding, type = 'l', xlab = 'date', ylab = 'funding requests', main = 'cumulative sum of all funding requests by date')

#plotting broadband and all funding requests by day
pdf("figures/broadband_and_all_funding.pdf",width = 8,height = 8)
plot(all_applicant_funding_day$Group.1, all_applicant_funding_day$cumulative_funding, type = 'l', xlab = 'date', ylab = 'funding requests', main = 'broadband vs. all funding requests by date')
lines(applicant_funding_day$Group.1, applicant_funding_day$cumulative_funding, type = 'l', col=6)
dev.off()

#looking into recipients table
str(recipients_of_services)
table(recipients_of_services$quantity)
table(recipients_of_services$amount, useNA = 'ifany')

#looking into all recipients table
table(all_recipients_of_services$amount, useNA = 'ifany')
non_na_recips_amount <- nrow(all_recipients_of_services[!is.na(all_recipients_of_services$amount),])
na_recips_amount <- nrow(all_recipients_of_services[is.na(all_recipients_of_services$amount),])
