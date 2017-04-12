## =========================================
##
## FUNCTION: DEFINE AFFORDABILITY RANKING
##
## =========================================

affordability_ranking <- function(dta, cost){
  
  ## subset to clean districts
  dta <- dta[dta$exclude_from_ia_analysis == FALSE,]
  
  ## apply logic for affordability metric
  ## function for solving bandwidth budget 'knapsack' problem
  bw_knapsack <- function(ia_budget){
    ia_bw <- 0
    while (ia_budget > 0) {
      ## do something
      if (length(which(cost$cost_per_circuit <= ia_budget)) == 0) {
        break
      } else {
        ## maximum circuit cost that a district can afford within the budget
        index <- max(which(cost$cost_per_circuit <= ia_budget))
        ## add bandwidth
        ia_bw <- ia_bw + cost$circuit_size_mbps[index]
        ## subtract from budget
        ia_budget <- ia_budget - cost$cost_per_circuit[index]
      }
    }
    return(ia_bw)
  }
  
  ## Function to apply Knapsack / SotS Affordability Goal 
  three_datasets_for_real <- function(input){
    ## create target_bandwidth variable
    input$target_bandwidth <- sapply(input$ia_monthly_cost_total, function(x){bw_knapsack(x)})
    
    ## are districts meeting $3 per Mbps Goal?
    input$affordability_goal_sots <- ifelse(input$ia_monthly_cost_per_mbps <= 3, 1, 0)
    
    ## are districts meeting the new Affordability Goal?
    input$affordability_goal_knapsack <- ifelse(input$ia_bw_mbps_total >= input$target_bandwidth, 1, 0)
    
    ## for districts spending less than $700,
    ## the standard is whether they are paying less than or equal to $14 per Mbps
    small <- which(input$ia_monthly_cost_total < 700) 
    input[small,]$affordability_goal_knapsack <- ifelse(input[small,]$ia_monthly_cost_per_mbps <= 14, 1, 0)
    
    ## give free credit
    free_ia <- which(input$exclude_from_ia_analysis == FALSE &
                       input$exclude_from_ia_cost_analysis == FALSE &
                       input$ia_monthly_cost_total == 0 &
                       input$ia_bw_mbps_total > 0)
    input$affordability_goal_knapsack[free_ia] <- 1
    
    restricted_cost <- which(input$exclude_from_ia_analysis == FALSE &
                               input$exclude_from_ia_cost_analysis == TRUE &
                               input$ia_monthly_cost_total == 0)
    input$affordability_goal_knapsack[restricted_cost] <- NA
    
    output <- input
    return(output)
  }
  
  dta <- three_datasets_for_real(dta)
  ## subset the dataset
  dta <- dta[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'ia_monthly_cost_total', 'ia_monthly_cost_per_mbps')]
  ## calculate difference between target bw and total bw the district is currently receiving
  dta$diff.bw <- dta$target_bandwidth - dta$ia_bw_mbps_total
  dta$diff.bw.perc <- dta$diff.bw / dta$target_bandwidth
  ## calculate the same for cost_per_mbps
  dta$cost.per.mbps.normalized <- dta$ia_monthly_cost_per_mbps / 14
  
  ## credit $0 budget (free internet) with 5 stars
  sub.0 <- dta[which(dta$ia_monthly_cost_total == 0),]
  sub.0$group <- 5
  
  ## apply logic based on knapsack BW to districts with >= $700 budget
  ## we can assign groupings based on breaking the distribution into 5 groups
  ## < -1, *****
  ## -1 to -0.4999999, ****
  ## -0.5 to -0.0000001, ***
  ## 0 to .4999999, **
  ## 0.5 to 1, *
  sub.g.700 <- dta[which(dta$ia_monthly_cost_total >= 700),]
  sub.g.700$group <- ifelse(sub.g.700$diff.bw.perc < -1, 5,
                      ifelse(sub.g.700$diff.bw.perc < -0.5, 4,
                             ifelse(sub.g.700$diff.bw.perc < 0, 3,
                                    ifelse(sub.g.700$diff.bw.perc < 0.5, 2, 1))))
  
  ## for the districts spending less than $700 total, look at their cost_per_mbps
  ## if the cost_per_mbps is strictly greater than $14, then they're *
  ## otherwise dimension out buckets by dividing out cost_per_mbps by $14
  ## cost.per.mbps.normalized <= 0.25, *****
  ## cost.per.mbps.normalized <= 0.50, ****
  ## cost.per.mbps.normalized <= 0.75, ***
  ## cost.per.mbps.normalized <= 1.00, **
  sub.l.700 <- dta[which(dta$ia_monthly_cost_total < 700 & dta$ia_monthly_cost_total != 0),]
  sub.l.700$group <- ifelse(sub.l.700$ia_monthly_cost_per_mbps > 14, 1,
                            ifelse(sub.l.700$cost.per.mbps.normalized <= 0.25, 5,
                                   ifelse(sub.l.700$cost.per.mbps.normalized <= 0.50, 4,
                                          ifelse(sub.l.700$cost.per.mbps.normalized <= 0.75, 3, 2))))
  ## combine all three datasets 
  dta <- rbind(sub.0, sub.g.700, sub.l.700)
  
  return(dta)
}
