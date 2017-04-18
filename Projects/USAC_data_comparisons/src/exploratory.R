## =========================================
##
## Exploratory Analysis
##
## =========================================

rm(list=ls())

##**************************************************************************************************************************************************
## read in data
combined <- read.csv("data/interim/combined_line_items.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)
combined_allocations <- read.csv("data/interim/combined_allocations.csv", as.is = TRUE, header = TRUE, stringsAsFactors = FALSE)

#Counting the matches. Added in connect type and connect category where purpose is not ISP
connect_type_count <- nrow(combined[which(combined$connect_type_match_override == TRUE),])
connect_type_perc <- connect_type_count / length(combined$connect_type_match[combined$purpose.y != 'ISP'])
connect_type_change <-length(combined$connect_type_match[combined$purpose.y != 'ISP']) - connect_type_count

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

all_count <- length(combined$all_match[combined$all_match == TRUE])
all_perc <- all_count / length(combined$all_match)

percents_to_plot <- c(connect_type_perc, connect_cat_perc, purpose_perc, bandwidth_perc, num_lines_perc, cost_perc, all_perc)
changes_to_plot <- c(connect_type_change, connect_cat_change, purpose_change, bandwidth_change, num_lines_change, cost_change)

combined$num_changes <- ifelse(combined$connect_type_match_override %in% FALSE, 1, 0) + 
                        ifelse(combined$connect_category_match_override %in% FALSE, 1, 0) +
                        ifelse(combined$purpose_match == FALSE, 1, 0) +
                        ifelse(combined$bandwidth_in_mbps_match == FALSE, 1, 0) +
                        ifelse(combined$num_lines_match == FALSE, 1, 0) + 
                        ifelse(combined$line_item_recurring_elig_cost_match == FALSE, 1, 0)

table(combined$num_changes)



#makes the x axis labels rotate the other way 
par(las=2)

#created extra margins
par(mar=c(9.5,4.1,5.1,2.1))

#plotted. could add #text
pdf("figures/esh_matches_usac.pdf",width = 12,height = 8)
barplot(percents_to_plot, names.arg = c("connect type","connect category","purpose","bandwidth","num lines","cost","everything"), main = "ESH matches USAC Current", cex.names=1, col='blue')
dev.off()

barplot(changes_to_plot, names.arg = c("connect type","connect category","purpose","bandwidth","num lines","cost"), main = "Number of Changes by Field", cex.names=1, col='blue')

barplot(table(combined$num_changes), main = "Line Item Number of Changes", xlab = 'Number of Changes',ylab = 'Number of Line Items',col='blue')

#bandwidth differences
hist(combined$bandwidth_differences, xlim=c(-1,2), breaks = c(-1,-.8,-.6,-.4,-.2,0,.2,.4,.6,.8,1,7000), freq = TRUE)

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
hist(combined$cost_differences, xlim = c(-1,2), breaks = c(-1,-.8,-.6,-.4,-.2,0,.2,.4,.6,.8,1,max(combined$cost_differences, na.rm = TRUE)), freq = TRUE )

#how many of the recipient BENs listed on USAC are listed on ESH allocations?
## make TRUE/FALSE indicators
combined_allocations$recip_match <- ifelse(is.na(combined_allocations$location.x) | is.na(combined_allocations$location.y), FALSE, TRUE)
combined_allocations$recip_match1 <- ifelse(!is.na(combined_allocations$location.x) & !is.na(combined_allocations$location.y), TRUE, FALSE)
ben_usac_and_esh <- length(combined_allocations$recipient_ben[combined_allocations$location.x == 'USAC' & combined_allocations$location.y == 'ESH'])
ben_usac_only <- length(combined_allocations$recipient_ben[combined_allocations$location.x == 'USAC' & combined_allocations$location.y != 'ESH'])
ben_esh_only <- length(combined_allocations$recipient_ben[combined_allocations$location.x != 'USAC' & combined_allocations$location.y == 'ESH'])



barplot(c(ben_usac_and_esh,ben_esh_only,ben_usac_only), names.arg = c("Recipient in both",'ESH Only','USAC only'), cex.names = 1, col='blue',main = 'Recipients listed in USAC, ESH, Both')

#how many FRNs have all recipient matches

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

#how many students is USAC missing out on?
ben_esh_only_df <- combined_allocations[is.na(combined_allocations$location.x) & combined_allocations$location.y == 'ESH',]
missing_bens <- data.frame(unique(ben_esh_only_df$recipient_ben))

#which applicants are responsible for incorrect BENs?
applicants <- frn_ben_comparisons[which(frn_ben_comparisons$recip_match == FALSE),]

#do line items usually have too many recipients or not enough?
usac_num_reipients <- combined_allocations[!is.na(combined_allocations$location.x),]
usac_num_reipients <- aggregate(usac_num_reipients$counter, by = list(usac_num_reipients$frn_complete), FUN = sum, na.rm = T)
names(usac_num_reipients) <- c('frn_complete','usac_num_recipients')

esh_num_reipients <- combined_allocations[!is.na(combined_allocations$location.y),]
esh_num_reipients <- aggregate(esh_num_reipients$counter, by = list(esh_num_reipients$frn_complete), FUN = sum, na.rm = T)
names(esh_num_reipients) <- c('frn_complete','esh_num_recipients')

total_num_recipients <- merge(x = usac_num_reipients, y = esh_num_reipients, by = 'frn_complete', all = TRUE)

total_num_recipients$more_esh_recips <- ifelse(total_num_recipients$esh_num_recipients > total_num_recipients$usac_num_recipients,
                                              'more esh recips', ifelse(total_num_recipients$esh_num_recipients == total_num_recipients$usac_num_recipients,
                                                                 'same number of recipients', 'more usac recips') )
table(total_num_recipients$more_esh_recips)


write.csv(missing_bens, 'data/interim/ben_esh_only_df.csv', row.names=F)
write.csv(applicants, 'data/interim/applicants_of_incorrect_bens.csv', row.names=F)
