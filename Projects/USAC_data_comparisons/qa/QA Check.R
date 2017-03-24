
# clear the console
cat("\014")


rm(list=ls())
#QA Step C. Check that the number of distinct FRN completes in the ESH line item data matches the distinct number of FRN completes in the USAC current + USAC original line item data.
#Step D. Check that the number of distinct FRN completes in the ESH line item data is equal to the number of all ESH FRN completes that were erate = True
current_frn_file <- read.csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/all_frn.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
original_frn_file <- read.csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/original_frns.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_frn_file <- read.csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/fy2016_line_items.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

current_frn_mod <- current_frn_file[,c("Application.Number","Line.Item","Type.of.Product","Function","Purpose","Download.Speed","Download.Speed.Units","Monthly.Quantity","Total.Monthly.Eligible.Recurring.Costs")]


current_frn_mod$bandwidth_in_mbps <- ifelse(current_frn_mod$Download.Speed.Units=='Gbps', current_frn_mod$Download.Speed * 1000,current_frn_mod$Download.Speed)
original_frn_file$bandwidth_in_mbps <- ifelse(original_frn_file$download_speed_units=='Gbps', original_frn_file$download_speed * 1000,original_frn_file$download_speed)

current_frn_mod <- current_frn_mod[,c("Application.Number","Line.Item","Type.of.Product","Function","Purpose","bandwidth_in_mbps","Monthly.Quantity","Total.Monthly.Eligible.Recurring.Costs")]
current_frn_mod$Line.Item <- as.character(current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==13,paste(current_frn_mod$Line.Item,'0',sep=''),current_frn_mod$Line.Item)
current_frn_mod$Line.Item <- ifelse(nchar(current_frn_mod$Line.Item)==12,paste(current_frn_mod$Line.Item,'00',sep=''),current_frn_mod$Line.Item)

original_frn_mod <- original_frn_file[,c("application_number","line_item","type_of_product","function.","purpose","bandwidth_in_mbps","monthly_quantity","total_monthly_eligible_recurring_costs")]
original_frn_mod$line_item <- as.character(original_frn_mod$line_item)
original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==13,paste(original_frn_mod$line_item,'0',sep=''),original_frn_mod$line_item)
original_frn_mod$line_item <- ifelse(nchar(original_frn_mod$line_item)==12,paste(original_frn_mod$line_item,'00',sep=''),original_frn_mod$line_item)

commonOrigCurrent <- intersect(current_frn_mod$Line.Item,original_frn_mod$line_item)
print(commonOrigCurrent)

#checked with adrianna - use which to make sure NAs aren't included. the first way is the old way
#original_frn_not_current <- original_frn_file[!original_frn_file$line_item %in% commonOrigCurrent,] 
original_frn_not_current <- original_frn_mod[which(!original_frn_mod$line_item %in% commonOrigCurrent),]

names(original_frn_not_current) <- names(esh_frn_file)
names(current_frn_mod) <- names(esh_frn_file)

#combined the current frns with the original frns
all_usac_frns <- rbind(current_frn_mod,original_frn_not_current)

#Intersection of all usac FRNs and ESH (so that we only look at line items that are c1 and go to districts in our universe)
commonId <- intersect(all_usac_frns$frn_complete,esh_frn_file$frn_complete)

#QA STEP D checking why some esh frns are removed
esh_not_frn_file <- esh_frn_file[!esh_frn_file$frn_complete %in% commonId,]
esh_not_frn_file <- esh_not_frn_file[esh_not_frn_file$frn_complete != 'NON-ERATE',]

all_usac_frns <- all_usac_frns[all_usac_frns$frn_complete %in% commonId,]
esh_frn_file <- esh_frn_file[esh_frn_file$frn_complete %in% commonId,]


esh_num_frn_complete <- length(unique(esh_frn_file$frn_complete))
usac_num_frn_complete <- length(unique(all_usac_frns$frn_complete))

ifelse(esh_num_frn_complete == usac_num_frn_complete,paste('Step C Passes QA. Both have',esh_num_frn_complete,'distinct FRN completes'), 'Step C Fails QA')

#*******************************************************************
#QA Step E. Check that the number of distinct FRN completes in the ESH allocation data matches the distinct number of FRN completes in the USAC current + USAC original allocation data
# Step F.Check that the number of distinct FRN completes in the ESH allocation data is equal to the number of all ESH FRN completes that were erate = True

cat("\014")

rm(list=ls())

current_allocations <- read.csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/all_recip.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
esh_allocations <- read.csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/fy2016_allocations.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
current_alloc_mod <- current_allocations[,c("BEN","Line.Item","Quantity")]
current_alloc_mod$Line.Item <- as.character(current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==13,paste(current_alloc_mod$Line.Item,'0',sep=''),current_alloc_mod$Line.Item)
current_alloc_mod$Line.Item <- ifelse(nchar(current_alloc_mod$Line.Item)==12,paste(current_alloc_mod$Line.Item,'00',sep=''),current_alloc_mod$Line.Item)


names(current_alloc_mod) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

#took out BENs from ESH where we de-allocated the line (i.e. made the num lines to allocate = 0)
esh_alloc_mod <- esh_allocations[esh_allocations$num_lines_to_allocate > 0,]
esh_alloc_mod$location <- 'ESH'


commonIDAlloc <- intersect(current_alloc_mod$frn_complete,esh_alloc_mod$frn_complete)

current_alloc_mod <- current_alloc_mod[which(current_alloc_mod$frn_complete %in% commonIDAlloc),]

original_alloc_usac <- esh_allocations[which(!esh_allocations$frn_complete %in% commonIDAlloc),]
original_alloc_usac <- original_alloc_usac[,c('recipient_ben','frn_complete','original_num_lines_to_allocate')]
names(original_alloc_usac) <- c("recipient_ben","frn_complete", "num_lines_to_allocate")

all_usac_alloc <- rbind(current_alloc_mod,original_alloc_usac)
all_usac_alloc$location <- 'USAC'

esh_num_frn_complete <-length(unique(esh_alloc_mod$frn_complete))
usac_num_frn_complete <-length(unique(all_usac_alloc$frn_complete))
esh_starting_num_frn_completes <- length(unique(esh_allocations$frn_complete))

ifelse(esh_num_frn_complete == usac_num_frn_complete,paste('Step E Passes QA. Both have',esh_num_frn_complete,'distinct FRN completes'), 'Step E Fails QA')
ifelse(esh_num_frn_complete == esh_starting_num_frn_completes,paste('Step F Passes QA. Both have',esh_num_frn_complete,'distinct FRN completes'), 'Step F Fails QA')
