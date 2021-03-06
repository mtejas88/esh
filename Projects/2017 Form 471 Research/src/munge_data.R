## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())

##**************************************************************************************************************************************************
## read in data

frn_line_items <- read.csv("data/raw/frn_line_items_2017.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
basic_informations <- read.csv("data/raw/basic_informations_2017.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
recipients_of_services <- read.csv("data/raw/recipients_2017.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)

##**************************************************************************************************************************************************
## subset and format data

#creating all basic informations so don't can also analyze cat 2 and voice services
all_basic_informations <- basic_informations

#adjusting all basic informatins certified timestamp field from character to date
all_basic_informations$certified_timestamp <- as.Date(all_basic_informations$certified_timestamp, "%m/%d/%y")


#adding a 0 to line items missing it in their frn line item
frn_line_items$line_item <- as.character(frn_line_items$line_item)
frn_line_items$line_item <- ifelse(nchar(frn_line_items$line_item) == 13,
                                   paste(frn_line_items$line_item, '0', sep = ''), frn_line_items$frn)

#taking out cat 2 services from basic informations
basic_informations <- basic_informations[basic_informations$category_of_service == 1,]

#taking out voice line items from frn line items
frn_line_items <- frn_line_items[frn_line_items$function. != 'Voice',]

#getting rid of certain states
frn_line_items <- frn_line_items[!frn_line_items$postal_cd %in% c('GU','PR'),]

#common IDs between cat 1 basic informations dataframe and frn line items
commonID <- intersect(frn_line_items$application_number, basic_informations$application_number)

#taking out cat 2 line items from frn line items
frn_line_items <- frn_line_items[frn_line_items$application_number %in% commonID,]

#taking out voice and Guam / PR from basic informations
basic_informations <- basic_informations[basic_informations$application_number %in% commonID,]

#converting basic information certified timestamp from character to date
basic_informations$certified_timestamp <- as.Date(basic_informations$certified_timestamp, "%m/%d/%y")

#adding a 0 to line items missing it in their recipient allocations line item
recipients_of_services$line_item <- as.character(recipients_of_services$line_item)
recipients_of_services$line_item <- ifelse(nchar(recipients_of_services$line_item) == 13,
                                   paste(recipients_of_services$line_item, '0', sep = ''), recipients_of_services$frn)

#common IDs between recips and cat 1 non-voice frns
commonIDRecip <- intersect(frn_line_items$application_number, recipients_of_services$application_number)

#taking out cat 2 line from recips
recipients_of_services <- recipients_of_services[recipients_of_services$application_number %in% commonIDRecip,]

#creating a bandwidth field for frn line items
frn_line_items$bandwidth_in_mbps <- ifelse(frn_line_items$download_speed_units == 'Gbps', frn_line_items$download_speed * 1000, frn_line_items$download_speed)

#adjusting purpose
frn_line_items$purpose[frn_line_items$purpose == 
                     "Internet access service that includes a connection from any applicant site directly to the Internet Service Provider"] <- "Internet"
frn_line_items$purpose[frn_line_items$purpose == 
                     "Data Connection between two or more sites entirely within the applicant’s network"] <- "WAN"
frn_line_items$purpose[frn_line_items$purpose == 
                     "Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately"] <- "Upstream"
frn_line_items$purpose[frn_line_items$purpose == 
                     "Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)"] <- "ISP"
frn_line_items$purpose[frn_line_items$purpose == 
                     "Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities"] <- "Backbone"


#subsetting
frn_line_items <- frn_line_items[,c('id','postal_cd','application_number','ben','billed_entity_name', 'frn', 'line_item','function.',
                                    'type_of_product','purpose','bandwidth_in_mbps','upload_speed','upload_speed_units',
                                    'monthly_recurring_unit_costs','monthly_quantity','total_eligible_recurring_costs',
                                    'total_eligible_one_time_costs')]

recipients_of_services <- recipients_of_services[,!names(recipients_of_services) %in% c('contact_email')]

##**************************************************************************************************************************************************
## write out the iterim datasets
write.csv(frn_line_items, 'data/interim/frn_line_items.csv', row.names=F)
write.csv(recipients_of_services, 'data/interim/recipients.csv', row.names=F)
write.csv(basic_informations, 'data/interim/basic_informations.csv', row.names=F)
write.csv(all_basic_informations, 'data/interim/all_basic_informations.csv', row.names=F)

