## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())

##**************************************************************************************************************************************************
## read in data

current_frn_file <- read.csv("data/interim/all_frn.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
original_frn_file <- read.csv("data/raw/original_frns.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_frn_file <- read.csv("data/raw/fy2016_line_items.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
current_allocations <- read.csv("data/interim/all_recip.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_allocations <- read.csv("data/raw/fy2016_allocations.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

##**************************************************************************************************************************************************
## subset and format current frn

current_frn_mod <- current_frn_file[,c("Application.Number","Line.Item","Type.of.Product","Function",
                                       "Purpose","Download.Speed","Download.Speed.Units","Monthly.Quantity",
                                       "Total.Monthly.Eligible.Recurring.Costs")]


current_frn_mod$bandwidth_in_mbps <- ifelse(current_frn_mod$Download.Speed.Units=='Gbps',
                                            current_frn_mod$Download.Speed * 1000, current_frn_mod$Download.Speed)

current_frn_mod <- current_frn_mod[,c("Application.Number","Line.Item","Type.of.Product","Function",
                                      "Purpose","bandwidth_in_mbps","Monthly.Quantity",
                                      "Total.Monthly.Eligible.Recurring.Costs")]
current_frn_mod$Line.Item <- as.character(current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==13,
                                    paste(current_frn_mod$Line.Item,'0',sep=''), current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==12,
                                    paste(current_frn_mod$Line.Item,'00',sep=''), current_frn_mod$Line.Item)

##**************************************************************************************************************************************************
## subset and format original frn
original_frn_file$bandwidth_in_mbps <- ifelse(original_frn_file$download_speed_units=='Gbps',
                                              original_frn_file$download_speed * 1000, original_frn_file$download_speed)

original_frn_mod <- original_frn_file[,c("application_number","line_item","type_of_product","function.",
                                         "purpose","bandwidth_in_mbps","monthly_quantity",
                                         "total_monthly_eligible_recurring_costs")]

original_frn_mod$line_item <- as.character(original_frn_mod$line_item)

original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==13,
                                     paste(original_frn_mod$line_item,'0',sep=''), original_frn_mod$line_item)
original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==12,
                                     paste(original_frn_mod$line_item,'00',sep=''), original_frn_mod$line_item)


##**************************************************************************************************************************************************
## joining together current and original
commonOrigCurrent <- intersect(current_frn_mod$Line.Item, original_frn_mod$line_item)
print(commonOrigCurrent)

#checked with adrianna - use which to make sure NAs aren't included. the first way is the old way
#original_frn_not_current <- original_frn_file[!original_frn_file$line_item %in% commonOrigCurrent,] 
original_frn_not_current <- original_frn_mod[which(!original_frn_mod$line_item %in% commonOrigCurrent),]
names(original_frn_not_current) <- names(esh_frn_file)
names(current_frn_mod) <- names(esh_frn_file)


#combined the current frns with the original frns
all_usac_frns <- rbind(current_frn_mod, original_frn_not_current)

##**************************************************************************************************************************************************
## joining together all usac and esh

#Intersection of all usac FRNs and ESH (so that we only look at line items that are c1 and go to districts in our universe)
commonId <- intersect(all_usac_frns$frn_complete, esh_frn_file$frn_complete)


all_usac_frns <- all_usac_frns[which(all_usac_frns$frn_complete %in% commonId),]
esh_frn_file <- esh_frn_file[which(esh_frn_file$frn_complete %in% commonId),]

#commonPurpose <- intersect(current_frn_mod_2$connect_type, esh_frn_file_2$connect_type)
combined <- merge(x = all_usac_frns, y = esh_frn_file, by = 'frn_complete') #inner join

current_num <- nrow(combined[which(combined$frn_complete %in% current_frn_mod$frn_complete),])
original_frn_not_current_num <- nrow(combined[which(combined$frn_complete %in% original_frn_not_current$frn_complete),])

##**************************************************************************************************************************************************
## formatting combined dataframe

#Making purpose fields match up
combined$purpose.x[combined$purpose.x == 
                     "Internet access service that includes a connection from any applicant site directly to the Internet Service Provider"] <- "Internet"
combined$purpose.x[combined$purpose.x == 
                     "Data Connection between two or more sites entirely within the applicant’s network"] <- "WAN"
combined$purpose.x[combined$purpose.x == 
                     "Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately"] <- "Upstream"
combined$purpose.x[combined$purpose.x == 
                     "Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)"] <- "ISP"
combined$purpose.x[combined$purpose.x == 
                     "Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities"] <- "Backbone"

#Making connect category fields match up
combined$connect_category.y[combined$connect_category.y == "Lit Fiber"] <- "Fiber"
combined$connect_category.y[combined$connect_category.y == "Dark Fiber"] <- "Fiber"
combined$connect_category.y[combined$connect_category.y == "Fixed Wireless"] <- "Wireless"
combined$connect_category.y[combined$connect_category.y == "Satellite/LTE"] <- "Wireless"
combined$connect_category.y[combined$connect_category.y == "Cable"] <- "Copper"
combined$connect_category.y[combined$connect_category.y == "DSL"] <- "Copper"
combined$connect_category.y[combined$connect_category.y == "T-1"] <- "Copper"
combined$connect_category.y[combined$connect_category.y == "Other Copper"] <- "Copper"
combined$connect_category.y[combined$connect_category.y == "Uncategorized"] <- "Other"


#Creating a loop to check to see if the ESH value matched USAC for the various columns
col.names <- names(combined)[3:8]

for (i in 1:length(col.names)){
  new_col_name <- paste(gsub('\\.x','',col.names[i]),'match',sep='_')
  print(new_col_name)
  combined$temp <- NA
  combined$temp <- ifelse(combined[i+2] == combined[i+2+7], TRUE, FALSE)
  names(combined)[names(combined) == "temp"] <- new_col_name
  #next line needs to use the ^ logic
  #combined$new_col_name <- ifelse(combined[i+2] == combined[i+2+7], TRUE, FALSE)
}

#REPLACING NA WITH FALSE IN THE MATCH COLUMNS
combined[c("connect_type_match","connect_category_match",
           "purpose_match","bandwidth_in_mbps_match",
           "num_lines_match",
           "line_item_recurring_elig_cost_match")][is.na(combined[c("connect_type_match",
                                                                    "connect_category_match", "purpose_match",
                                                                    "bandwidth_in_mbps_match", "num_lines_match",
                                                                    "line_item_recurring_elig_cost_match")])] <- FALSE

#Counting the matches. Added in connect type and connect category where purpose is not ISP
combined$connect_type_match_override <- ifelse(combined$connect_type_match == TRUE & combined$purpose.y != 'ISP', TRUE,
                                               ifelse(combined$purpose.y == 'ISP', NA, FALSE))

combined$connect_category_match_override <- ifelse(combined$connect_category_match == TRUE & combined$purpose.y != 'ISP', TRUE,
                                                   ifelse(combined$purpose.y == 'ISP', NA, FALSE))

combined$all_match <- ifelse((combined$connect_type_match_override == TRUE | is.na(combined$connect_type_match_override))
                             & (combined$connect_category_match_override == TRUE | is.na(combined$connect_category_match_override))
                             & combined$purpose_match == TRUE & combined$bandwidth_in_mbps_match == TRUE
                             & combined$num_lines_match == TRUE & combined$line_item_recurring_elig_cost_match == TRUE, TRUE, FALSE)

combined$cost_differences <- (combined$line_item_recurring_elig_cost.y - combined$line_item_recurring_elig_cost.x) / combined$line_item_recurring_elig_cost.x
combined$cost_differences[combined$cost_differences == 'Inf'] <- NA

combined$bandwidth_differences <- (combined$bandwidth_in_mbps.y - combined$bandwidth_in_mbps.x) / combined$bandwidth_in_mbps.x

##**************************************************************************************************************************************************
## formatting and subsetting current allocations
current_alloc_mod <- current_allocations[,c("BEN","Line.Item","Quantity")]
current_alloc_mod$Line.Item <- as.character(current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==13,
                                      paste(current_alloc_mod$Line.Item,'0',sep=''), current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==12,
                                      paste(current_alloc_mod$Line.Item,'00',sep=''), current_alloc_mod$Line.Item)


names(current_alloc_mod) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

##**************************************************************************************************************************************************
## formatting and subsetting esh allocations

#took out BENs from ESH where we de-allocated the line (i.e. made the num lines to allocate = 0)
esh_alloc_mod <- esh_allocations[esh_allocations$num_lines_to_allocate > 0,]
esh_alloc_mod$location <- 'ESH'

##**************************************************************************************************************************************************
## merging together original USAC allocations and current USAC allocations

#common IDs between current allocations and ESH allocations
commonIDAlloc <- intersect(current_alloc_mod$frn_complete, esh_alloc_mod$frn_complete)
current_alloc_mod <- current_alloc_mod[which(current_alloc_mod$frn_complete %in% commonIDAlloc),]

#creating original USAC allocations from ESH allocations that aren't in current
original_alloc_usac <- esh_allocations[which(!esh_allocations$frn_complete %in% current_alloc_mod$frn_complete),]

#subsetting and renaming original allocations
original_alloc_usac <- original_alloc_usac[,c('recipient_ben','frn_complete','original_num_lines_to_allocate')]
names(original_alloc_usac) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

# merging original and USAC allocations
all_usac_alloc <- rbind(current_alloc_mod, original_alloc_usac)
all_usac_alloc$location <- 'USAC'

##**************************************************************************************************************************************************
## merging together all USAC and ESH allocations
combined_allocations = merge(x = all_usac_alloc, y = esh_alloc_mod, by = c('frn_complete','recipient_ben'), all = TRUE)

#There are duplicated bens on the USAC side (so removing duplicates)
combined_allocations <- combined_allocations[!duplicated(combined_allocations),]

##**************************************************************************************************************************************************
## write out the iterim datasets
#create a file from these dataframes to interim: combined, combined_allocations
write.csv(combined, 'data/interim/combined_line_items.csv', row.names=F)
write.csv(combined_allocations, 'data/interim/combined_allocations.csv', row.names=F)
