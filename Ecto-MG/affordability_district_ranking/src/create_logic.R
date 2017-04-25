## =========================================
##
## EXAMINE DATA: Affordability
## Look into cutoff points for bucketing 
##
## =========================================

## Clearing memory
rm(list=ls())

## source functions
source("src/affordability_ranking.R")

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)

## cost reference data
cost <- read.csv("../../General_Resources/datasets/cost_lookup.csv", as.is=T, header=T)
cost$cost_per_circuit <- cost$circuit_size_mbps * cost$cost_per_mbps

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## subset to clean districts
dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]

## apply logic for affordability metric
## function for solving bandwidth budget 'knapsack' problem
#bw_knapsack <- function(ia_budget){
#  ia_bw <- 0
#  while (ia_budget > 0) {
#    ## do something
#    if (length(which(cost$cost_per_circuit <= ia_budget)) == 0) {
#      break
#    } else {
#      ## maximum circuit cost that a district can afford within the budget
#      index <- max(which(cost$cost_per_circuit <= ia_budget))
#      ## add bandwidth
#      ia_bw <- ia_bw + cost$circuit_size_mbps[index]
#      ## subtract from budget
#      ia_budget <- ia_budget - cost$cost_per_circuit[index]
#    }
#  }
#  return(ia_bw)
#}

## Function to apply Knapsack / SotS Affordability Goal 
#three_datasets_for_real <- function(input){
#  ## create target_bandwidth variable
#  input$target_bandwidth <- sapply(input$ia_monthly_cost_total, function(x){bw_knapsack(x)})
#  
#  ## are districts meeting $3 per Mbps Goal?
#  input$affordability_goal_sots <- ifelse(input$ia_monthly_cost_per_mbps <= 3, 1, 0)
#  
#  ## are districts meeting the new Affordability Goal?
#  input$affordability_goal_knapsack <- ifelse(input$ia_bw_mbps_total >= input$target_bandwidth, 1, 0)
#  
#  ## for districts spending less than $700,
#  ## the standard is whether they are paying less than or equal to $14 per Mbps
#  small <- which(input$ia_monthly_cost_total < 700) 
#  input[small,]$affordability_goal_knapsack <- ifelse(input[small,]$ia_monthly_cost_per_mbps <= 14, 1, 0)
#  
#  ## give free credit
#  free_ia <- which(input$exclude_from_ia_analysis == FALSE &
#                     input$exclude_from_ia_cost_analysis == FALSE &
#                     input$ia_monthly_cost_total == 0 &
#                     input$ia_bw_mbps_total > 0)
#  input$affordability_goal_knapsack[free_ia] <- 1
#  
#  restricted_cost <- which(input$exclude_from_ia_analysis == FALSE &
#                             input$exclude_from_ia_cost_analysis == TRUE &
#                             input$ia_monthly_cost_total == 0)
#  input$affordability_goal_knapsack[restricted_cost] <- NA
#  
#  output <- input
#  return(output)
#}

#dd.2016 <- three_datasets_for_real(dd.2016)

## look at the distribution of target BW
#target.bw <- as.data.frame(table(dd.2016$target_bandwidth))

## Special Cases: separate out districts that are receiving free internet and are paying too little to afford the cheapest circuit
## take out the districts that are getting free internet (since their target BW will be 0)
#free.internet <- dd.2016[which(dd.2016$ia_monthly_cost_total == 0),]
#free.internet <- free.internet[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'ia_monthly_cost_total')]

## take out the districts that are paying less than $700 total (can't afford the cheapest circuit price)
#less.700 <- dd.2016[which(dd.2016$ia_monthly_cost_total < 700 & dd.2016$ia_monthly_cost_total != 0),]
#less.700 <- less.700[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'ia_monthly_cost_total')]

## examine the rest of the districts
#dta.afford <- dd.2016[which(dd.2016$ia_monthly_cost_total >= 700),]
#dta.afford <- dta.afford[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'ia_monthly_cost_total')]
## add in free internet
#dta.afford <- rbind(dta.afford, free.internet)

## calculate difference between target bw and total bw the district is currently receiving
#dta.afford$diff.bw <- dta.afford$target_bandwidth - dta.afford$ia_bw_mbps_total
#dta.afford$diff.bw.perc <- dta.afford$diff.bw / dta.afford$target_bandwidth

## look at the distribution of percentages
#target.bw.perc <- as.data.frame(table(dta.afford$diff.bw.perc))

dd.2016.grouped <- affordability_ranking(dd.2016, cost)

## plot the distribution (taking out outliers)
sub.hist <- dd.2016.grouped[which(dd.2016.grouped$diff.bw.perc > -1),]
pdf("figures/distribution_diff_target_actual_bw.pdf", height=5, width=6)
hist(sub.hist$diff.bw.perc, xlim=c(-1,1),
     col=rgb(0,0,0,0.6), border=F, breaks=seq(-1,1,by=0.10),
     main="Difference Between Target BW\nand Actual BW (Percentage)", xlab="", ylab="")
abline(v=0, lwd=2, col=rgb(1,0,0,0.6))
dev.off()

## we could assign groupings based on breaking the distribution into 5 groups
## <-1, -1 to -.5, -.5 to 0, 0 to .5, .5 to 1
#dta.afford$group <- ifelse(dta.afford$diff.bw.perc < -1 | dta.afford$ia_monthly_cost_total == 0, 5,
#                           ifelse(dta.afford$diff.bw.perc < -0.5, 4,
#                                  ifelse(dta.afford$diff.bw.perc < 0, 3,
#                                         ifelse(dta.afford$diff.bw.perc < 0.5, 2, 1))))
## add in the districts with less than $700

## calculate the same for cost_per_mbps
#dd.2016$cost.per.mbps.normalized <- dd.2016$ia_monthly_cost_per_mbps / 14
sub.l.700 <- dd.2016.grouped[which(dd.2016.grouped$ia_monthly_cost_total < 700),]
sub.l.700.l.14 <- sub.l.700[which(sub.l.700$ia_monthly_cost_per_mbps < 14),]

## plot the distribution
pdf("figures/distribution_cost_per_mbps_normalized.pdf", height=5, width=6)
hist(sub.l.700.l.14$cost.per.mbps.normalized, xlim=c(0,1),
     col=rgb(0,0,0,0.6), border=F, breaks=seq(0,1,by=0.10),
     main="Cost per mbps / $14", xlab="", ylab="")
abline(v=.25, lwd=2, col=rgb(1,0,0,0.6))
abline(v=.50, lwd=2, col=rgb(1,0,0,0.6))
abline(v=.75, lwd=2, col=rgb(1,0,0,0.6))
dev.off()

## aggregate mean difference of each grouping
dta.groups.mean <- aggregate(dd.2016.grouped$diff.bw, by=list(dd.2016.grouped$group), FUN=mean, na.rm=T)
names(dta.groups.mean) <- c('group', 'mean')
## aggregate median difference of each grouping
dta.groups.median <- aggregate(dd.2016.grouped$diff.bw, by=list(dd.2016.grouped$group), FUN=median, na.rm=T)
names(dta.groups.median) <- c('group', 'median')
## merge
dta.groups <- merge(dta.groups.mean, dta.groups.median, by="group", all=T)

## subset to each group
for (i in 1:5){
  sub <- dd.2016.grouped[dd.2016.grouped$group == i,]
  sub <- merge(sub, dd.2016[,c('esh_id', 'name', 'postal_cd')], by='esh_id', all.x=T)
  sub <- sub[order(sub$diff.bw.perc, decreasing=F),]
  write.csv(sub, paste("data/interim/affordability_group_", i, ".csv", sep=''))
  assign(paste("sub", i, sep="."), sub)
}

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(dd.2016.grouped, "data/interim/affordability_grouping.csv", row.names=F)
