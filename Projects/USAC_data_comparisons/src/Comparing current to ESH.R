
#setwd('~/Documents/Analysis/Current 2016 471s/')
setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/Current 2016 471s/")

# clear the console
cat("\014")

rm(list=ls())

current_frn_file <- read.csv("data/interim/all_frn.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
original_frn_file <- read.csv("data/raw/original_frns.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_frn_file <- read.csv("data/raw/fy2016_line_items.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

current_frn_mod <- current_frn_file[,c("Application.Number","Line.Item","Type.of.Product","Function",
                                       "Purpose","Download.Speed","Download.Speed.Units","Monthly.Quantity",
                                       "Total.Monthly.Eligible.Recurring.Costs")]


current_frn_mod$bandwidth_in_mbps <- ifelse(current_frn_mod$Download.Speed.Units=='Gbps',
                                            current_frn_mod$Download.Speed * 1000, current_frn_mod$Download.Speed)
original_frn_file$bandwidth_in_mbps <- ifelse(original_frn_file$download_speed_units=='Gbps',
                                              original_frn_file$download_speed * 1000, original_frn_file$download_speed)

current_frn_mod <- current_frn_mod[,c("Application.Number","Line.Item","Type.of.Product","Function",
                                      "Purpose","bandwidth_in_mbps","Monthly.Quantity",
                                      "Total.Monthly.Eligible.Recurring.Costs")]
current_frn_mod$Line.Item <- as.character(current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==13,
                                    paste(current_frn_mod$Line.Item,'0',sep=''), current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==12,
                                    paste(current_frn_mod$Line.Item,'00',sep=''), current_frn_mod$Line.Item)

original_frn_mod <- original_frn_file[,c("application_number","line_item","type_of_product","function.",
                                         "purpose","bandwidth_in_mbps","monthly_quantity",
                                         "total_monthly_eligible_recurring_costs")]
original_frn_mod$line_item <- as.character(original_frn_mod$line_item)
original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==13,
                                     paste(original_frn_mod$line_item,'0',sep=''), original_frn_mod$line_item)
original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==12,
                                     paste(original_frn_mod$line_item,'00',sep=''), original_frn_mod$line_item)

commonOrigCurrent <- intersect(current_frn_mod$Line.Item, original_frn_mod$line_item)
print(commonOrigCurrent)

#checked with adrianna - use which to make sure NAs aren't included. the first way is the old way
#original_frn_not_current <- original_frn_file[!original_frn_file$line_item %in% commonOrigCurrent,] 
original_frn_not_current <- original_frn_mod[which(!original_frn_mod$line_item %in% commonOrigCurrent),]
names(original_frn_not_current) <- names(esh_frn_file)
names(current_frn_mod) <- names(esh_frn_file)

#combined the current frns with the original frns
all_usac_frns <- rbind(current_frn_mod, original_frn_not_current)

#Intersection of all usac FRNs and ESH (so that we only look at line items that are c1 and go to districts in our universe)
commonId <- intersect(all_usac_frns$frn_complete, esh_frn_file$frn_complete)


all_usac_frns <- all_usac_frns[which(all_usac_frns$frn_complete %in% commonId),]
esh_frn_file <- esh_frn_file[which(esh_frn_file$frn_complete %in% commonId),]

#commonPurpose <- intersect(current_frn_mod_2$connect_type, esh_frn_file_2$connect_type)
combined <- merge(x = all_usac_frns, y = esh_frn_file, by = 'frn_complete') #inner join

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
connect_type_count <- nrow(combined[which(combined$connect_type_match_override == TRUE),])
connect_type_perc <- connect_type_count / length(combined$connect_type_match[combined$purpose.y != 'ISP'])
connect_type_change <-length(combined$connect_type_match[combined$purpose.y != 'ISP']) - connect_type_count

combined$connect_category_match_override <- ifelse(combined$connect_category_match == TRUE & combined$purpose.y != 'ISP', TRUE,
                                               ifelse(combined$purpose.y == 'ISP', NA, FALSE))
connect_cat_count <- nrow(combined[which(combined$connect_category_match_override == TRUE),])
connect_cat_perc <- connect_cat_count / length(combined$connect_category_match[combined$purpose.y != 'ISP'])
connect_cat_change <- length(combined$connect_category_match[combined$purpose.y != 'ISP']) - connect_cat_count

purpose_count <- length(combined$purpose_match[combined$purpose_match == TRUE])
purpose_perc <- purpose_count / length(combined$purpose_match)
purpose_change <- length(combined$purpose_match) - purpose_count

bandwidth_count <- length(combined$bandwidth_in_mbps_match[combined$bandwidth_in_mbps_match == TRUE])
bandwidth_perc <- bandwidth_count / length(combined$bandwidth_in_mbps_match)
bandwidth_change <- length(combined$bandwidth_in_mbps_match) - bandwidth_count

num_lines_count <- length(combined$num_lines_match[combined$num_lines_match == TRUE])
num_lines_perc <- num_lines_count / length(combined$num_lines_match)
num_lines_change <- length(combined$num_lines_match) - num_lines_count

cost_count <- length(combined$line_item_recurring_elig_cost_match[combined$line_item_recurring_elig_cost_match == TRUE])
cost_perc <- cost_count / length(combined$line_item_recurring_elig_cost_match)
cost_change <- length(combined$line_item_recurring_elig_cost_match) - cost_count

combined$all_match <- ifelse((combined$connect_type_match_override == TRUE | is.na(combined$connect_type_match_override))
                             & (combined$connect_category_match_override == TRUE | is.na(combined$connect_category_match_override))
                             & combined$purpose_match == TRUE & combined$bandwidth_in_mbps_match == TRUE
                             & combined$num_lines_match == TRUE & combined$line_item_recurring_elig_cost_match == TRUE, TRUE, FALSE)
all_count <- length(combined$all_match[combined$all_match == TRUE])
all_perc <- all_count / length(combined$all_match)

percents_to_plot <- c(connect_type_perc, connect_cat_perc, purpose_perc, bandwidth_perc, num_lines_perc, cost_perc, all_perc)
changes_to_plot <- c(connect_type_change, connect_cat_change, purpose_change, bandwidth_change, num_lines_change, cost_change)

#makes the x axis labels rotate the other way 
par(las=2)

#created extra margins
par(mar=c(9.5,4.1,5.1,2.1))

#plotted. could add #text
pdf("figures/esh_matches_usac.pdf",width = 4,height = 6)
barplot(percents_to_plot, names.arg = c("connect type","connect category","purpose","bandwidth","num lines","cost","everything"), main = "ESH matches USAC Current", cex.names=1, col='blue')
dev.off()

barplot(changes_to_plot, names.arg = c("connect type","connect category","purpose","bandwidth","num lines","cost"), main = "Number of Changes by Field", cex.names=1, col='blue')

#want to create histogram of bandwidth differences
combined$bandwidth_differences <- (combined$bandwidth_in_mbps.y - combined$bandwidth_in_mbps.x) / combined$bandwidth_in_mbps.x
hist(combined$bandwidth_differences, xlim=c(-1,2), breaks = c(-1,-.8,-.6,-.4,-.2,0,.2,.4,.6,.8,1,7000), freq = TRUE)


#if want to see min and max
min(combined$bandwidth_differences, na.rm=TRUE)
max(combined$bandwidth_differences, na.rm=TRUE)

#which purpose fields were most accurate?
values <- unique(combined$purpose.y)

backbone_count <- length(combined$purpose_match[combined$purpose_match == TRUE & combined$purpose.x == 'Backbone'])
backbone_perc <- backbone_count / length(combined$purpose.x[combined$purpose.x == 'Backbone'])

isp_count <- length(combined$purpose_match[combined$purpose_match == TRUE & combined$purpose.x == 'ISP'])
isp_perc <- isp_count / length(combined$purpose.x[combined$purpose.x == 'ISP'])

internet_count <- length(combined$purpose_match[combined$purpose_match == TRUE & combined$purpose.x == 'Internet'])
internet_perc <- internet_count / length(combined$purpose.x[combined$purpose.x == 'Internet'])

upstream_count <- length(combined$purpose_match[combined$purpose_match == TRUE & combined$purpose.x == 'Upstream'])
upstream_perc <- upstream_count / length(combined$purpose.x[combined$purpose.x == 'Upstream'])

wan_count <- length(combined$purpose_match[combined$purpose_match == TRUE & combined$purpose.x == 'WAN'])
wan_perc <- wan_count / length(combined$purpose.x[combined$purpose.x == 'WAN'])

#plot purpose fields
barplot(c(backbone_perc,isp_perc,internet_perc,upstream_perc,wan_perc), names.arg = c("Backbone",'ISP','Internet','Upstream','WAN'), cex.names = 1, col='blue',main = 'Accuracy of Purpose Fields')


#How accurate are is the num lines field by purpose?
num_lines_backbone <- length(combined$num_lines_match[combined$num_lines_match == TRUE & combined$purpose.x == 'Backbone'])
num_lines_backbone_perc <- num_lines_backbone / length(combined$purpose.x[combined$purpose.x == 'Backbone'])

num_lines_isp <- length(combined$num_lines_match[combined$num_lines_match == TRUE & combined$purpose.x == 'ISP'])
num_lines_isp_perc <- num_lines_isp / length(combined$purpose.x[combined$purpose.x == 'ISP'])

num_lines_internet <- length(combined$num_lines_match[combined$num_lines_match == TRUE & combined$purpose.x == 'Internet'])
num_lines_internet_perc <- num_lines_internet / length(combined$purpose.x[combined$purpose.x == 'Internet'])

num_lines_upstream <- length(combined$num_lines_match[combined$num_lines_match == TRUE & combined$purpose.x == 'Upstream'])
num_lines_upstream_perc <- num_lines_upstream / length(combined$purpose.x[combined$purpose.x == 'Upstream'])

num_lines_wan <- length(combined$num_lines_match[combined$num_lines_match == TRUE & combined$purpose.x == 'WAN'])
num_lines_wan_perc <- num_lines_wan / length(combined$purpose.x[combined$purpose.x == 'WAN'])

#plot num lines accuracy by purpose
barplot(c(num_lines_backbone_perc,num_lines_isp_perc,num_lines_internet_perc,num_lines_upstream_perc,num_lines_wan_perc), names.arg = c("Backbone",'ISP','Internet','Upstream','WAN'), cex.names = 1, col='blue',main = 'Accuracy of Num Lines field by Purpose')

#cost difference
combined$cost_differences <- (combined$line_item_recurring_elig_cost.y - combined$line_item_recurring_elig_cost.x) / combined$line_item_recurring_elig_cost.x
combined$cost_differences[combined$cost_differences == 'Inf'] <- NA
hist(combined$cost_differences, xlim = c(-1,2), breaks = c(-1,-.8,-.6,-.4,-.2,0,.2,.4,.6,.8,1,max(combined$cost_differences, na.rm = TRUE)), freq = TRUE )

#see the max and min
min(combined$cost_differences, na.rm = TRUE)
max(combined$cost_differences, na.rm = TRUE)

#allocations checking
current_allocations <- read.csv("data/interim/all_recip.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_allocations <- read.csv("data/raw/fy2016_allocations.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
current_alloc_mod <- current_allocations[,c("BEN","Line.Item","Quantity")]
current_alloc_mod$Line.Item <- as.character(current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==13,
                                      paste(current_alloc_mod$Line.Item,'0',sep=''), current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==12,
                                      paste(current_alloc_mod$Line.Item,'00',sep=''), current_alloc_mod$Line.Item)


names(current_alloc_mod) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

#took out BENs from ESH where we de-allocated the line (i.e. made the num lines to allocate = 0)
esh_alloc_mod <- esh_allocations[esh_allocations$num_lines_to_allocate > 0,]
esh_alloc_mod$location <- 'ESH'


commonIDAlloc <- intersect(current_alloc_mod$frn_complete, esh_alloc_mod$frn_complete)


current_alloc_mod <- current_alloc_mod[which(current_alloc_mod$frn_complete %in% commonIDAlloc),]

original_alloc_usac <- esh_allocations[which(!esh_allocations$frn_complete %in% current_alloc_mod$frn_complete),]
original_alloc_usac <- original_alloc_usac[,c('recipient_ben','frn_complete','original_num_lines_to_allocate')]
names(original_alloc_usac) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

all_usac_alloc <- rbind(current_alloc_mod, original_alloc_usac)
all_usac_alloc$location <- 'USAC'
  
combined_allocations = merge(x = all_usac_alloc, y = esh_alloc_mod, by = c('frn_complete','recipient_ben'), all = TRUE)

#There are duplicated bens on the USAC side (so removing duplicates)
combined_allocations <- combined_allocations[!duplicated(combined_allocations),]

#how many of the recipient BENs listed on USAC are listed on ESH allocations?
## make TRUE/FALSE indicators
combined_allocations$recip_match <- ifelse(is.na(combined_allocations$location.x) | is.na(combined_allocations$location.y), FALSE, TRUE)
combined_allocations$recip_match1 <- ifelse(!is.na(combined_allocations$location.x) & !is.na(combined_allocations$location.y), TRUE, FALSE)
ben_usac_and_esh <- length(combined_allocations$recipient_ben[combined_allocations$location.x == 'USAC' & combined_allocations$location.y == 'ESH'])
ben_usac_only <- length(combined_allocations$recipient_ben[combined_allocations$location.x == 'USAC' & combined_allocations$location.y != 'ESH'])
ben_esh_only <- length(combined_allocations$recipient_ben[combined_allocations$location.x != 'USAC' & combined_allocations$location.y == 'ESH'])

barplot(c(ben_usac_and_esh,ben_esh_only,ben_usac_only), names.arg = c("Recipient in both",'ESH Only','USAC only'), cex.names = 1, col='blue',main = 'Recipients listed in USAC, ESH, Both')

#how many FRNs have all recipient matches
#library(plyr)


#frn_all_recip_matches <- length(unique(combined_allocations$frn_complete[length(combined_allocations$location.x == 'USAC' & combined_allocations$location.y == 'ESH')==length(combined_allocations$recipient_ben)]))
#frn_not_all_recip_matches <- length(unique(combined_allocations$frn_complete[length(combined_allocations$recip_match == FALSE)==0]))

frn_match_counts <- aggregate(combined_allocations$recip_match, by=list(combined_allocations$frn_complete), FUN = sum, na.rm=T)
names(frn_match_counts) <- c('frn_complete','count_matching_bens')

combined_allocations$counter <- 1
count_total_bens <- aggregate(combined_allocations$counter, by=list(combined_allocations$frn_complete), FUN = sum, na.rm=T)
count_total_bens2 <- aggregate(combined_allocations$recipient_ben, by=list(combined_allocations$frn_complete), FUN = length)
names(count_total_bens) <- c('frn_complete','count_total_bens')

frn_ben_comparisons <- merge(x=frn_match_counts,y=count_total_bens, by='frn_complete')
frn_ben_comparisons$recip_match <- frn_ben_comparisons$count_matching_bens == frn_ben_comparisons$count_total_bens

num_matching_bens <- length(frn_ben_comparisons$recip_match[frn_ben_comparisons$recip_match == TRUE])
num_not_matching_bens <- length(frn_ben_comparisons$frn_complete)-num_matching_bens

barplot(c(num_matching_bens,num_not_matching_bens), names.arg = c("All recipients match",'Not all recips match'), cex.names = 1, col='blue',main = 'FRNs with the all same recipients listed')
