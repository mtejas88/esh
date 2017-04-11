## =========================================
##
## FUNCTION: DEFINE AFFORDABILITY RANKING
##
## =========================================

affordability_ranking <- function(dta){
  
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
  
  ## examine the rest of the districts
  dta.afford <- dta[which(dta$ia_monthly_cost_total >= 700),]
  dta.afford <- dta.afford[,c('esh_id', 'target_bandwidth', 'ia_bw_mbps_total', 'ia_monthly_cost_total')]
  ## add in free internet
  dta.afford <- rbind(dta.afford, free.internet)
  
  ## calculate difference between target bw and total bw the district is currently receiving
  dta.afford$diff.bw <- dta.afford$target_bandwidth - dta.afford$ia_bw_mbps_total
  dta.afford$diff.bw.perc <- round(dta.afford$diff.bw / dta.afford$target_bandwidth, 2)
  
  ## we could assign groupings based on breaking the distribution into 5 groups
  ## <-1, -1 to -.5, -.5 to 0, 0 to .5, .5 to 1
  dta.afford$group <- ifelse(dta.afford$diff.bw.perc < -1 | dta.afford$ia_monthly_cost_total == 0, 5,
                             ifelse(dta.afford$diff.bw.perc < -0.5, 4,
                                    ifelse(dta.afford$diff.bw.perc < 0, 3,
                                           ifelse(dta.afford$diff.bw.perc < 0.5, 2, 1))))
  return(dta.afford)
}

