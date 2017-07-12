## =========================================================================
##
## REFRESH STATE METRICS:
## AFFORDABILITY
##
## 2015 SAMPLE: exclude_from_analysis == FALSE
## 2016 SAMPLE: exclude_from_ia_analysis == FALSE
##
## hist: meeting affordability goal
## targets: # of districts getting a better deal, 2016
## ranking: unweighted/weighted, districts 2016
##
## =========================================================================

affordability <- function(sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools){
  
  ## METRIC ACROSS TIME
  
  ## A) Signify which districts are meeting/not meeting goal
  
  ## read in cost reference data
  cost <- read.csv("../data/raw/cost_lookup.csv", as.is=T, header=T)
  cost$cost_per_circuit <- cost$circuit_size_mbps * cost$cost_per_mbps
  
  ## subset to districts "fit for analysis"
  sots.districts.2015 <- sots.districts.2015
  dd.2015 <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
  ds.2015 <- ds.2015[ds.2015$exclude_from_analysis == FALSE,]
  dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
  ds.2016 <- ds.2016[ds.2016$exclude_from_ia_analysis == FALSE,]
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  ## take out NA values for ia_monthly_cost_total
  dd.2016.sub <- dd.2016[!is.na(dd.2016$ia_monthly_cost_total),]
  ds.2016.sub <- ds.2016[!is.na(ds.2016$ia_monthly_cost_total),]
  dd.2015.sub <- dd.2015[!is.na(dd.2015$ia_monthly_cost_total),]
  ds.2015.sub <- ds.2015[!is.na(ds.2015$ia_monthly_cost_total),]
  ## also take out 0 values for ia_monthly_cost_total
  #dd.2016.sub <- dd.2016[dd.2016$ia_monthly_cost_total != 0,]
  #dd.2015.sub <- dd.2015[dd.2015$ia_monthly_cost_total != 0,]
  
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
    ## convert ia_monthly_cost_per_mbps to numeric
    #input$ia_monthly_cost_per_mbps <- as.numeric(input$ia_monthly_cost_per_mbps, na.rm = TRUE)
    
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
  
  #sots.districts.2015 <- three_datasets_for_real(sots.districts.2015)
  dd.2015.sub <- three_datasets_for_real(dd.2015.sub)
  ds.2015.sub <- three_datasets_for_real(ds.2015.sub)
  dd.2016.sub <- three_datasets_for_real(dd.2016.sub)
  ds.2016.sub <- three_datasets_for_real(ds.2016.sub)
  
  ## merge in columns that were added (since we removed the districts with NA's in ia_monthly_cost_total)
  #dd.2015 <- merge(dd.2015, dd.2015.sub[,c('esh_id', names(dd.2015.sub)[!names(dd.2015.sub) %in% names(dd.2015)])], by='esh_id', all.x=T)
  #dd.2016 <- merge(dd.2016, dd.2016.sub[,c('esh_id', names(dd.2016.sub)[!names(dd.2016.sub) %in% names(dd.2016)])], by='esh_id', all.x=T)
  dd.2015 <- dd.2015.sub
  ds.2015 <- ds.2015.sub
  dd.2016 <- dd.2016.sub
  ds.2016 <- ds.2016.sub
  
  
  ##------------------------------------------------------------------------------------------------------------------------------------------
  ## B) Aggregate the metric at the variable level
  
  vars <- c("districts", "schools", "students")
  
  for (i in 1:length(vars)){
    
    ## 1) Districts Meeting Affordability Goal (Count): "_districts_mtg_affordability", _schools_mtg_affordability", "_students_mtg_affordability"
    ##---------------------------------------------------------------------------------------------------------------------------------------------
    ## sots 2015:
    ## aggregate over 2015 deluxe districts for each state
    sots.districts.2015$counter <- ifelse(sots.districts.2015$Meeting.Afford.Goal. == 'Yes', 1, 0)
    if (vars[i] == 'schools'){
      sots.districts.2015$counter <- sots.districts.2015$counter * sots.districts.2015$num_schools
    }
    if (vars[i] == 'students'){
      sots.districts.2015$counter <- sots.districts.2015$counter * sots.districts.2015$num_students
    }
    mtg.goal.sots.2015 <- aggregate(sots.districts.2015$counter, by=list(sots.districts.2015$postal_cd), FUN=sum, na.rm=T)
    names(mtg.goal.sots.2015) <- c('postal_cd', paste('sots15', vars[i], 'mtg_affordability', sep='_'))
    
    ## 2015 current:
    ## aggregate over 2015 deluxe districts for each state
    #dd.2015$counter <- ifelse(dd.2015$meeting_3_per_mbps_affordability_target == TRUE, 1, 0)
    dd.2015$counter <- dd.2015$affordability_goal_knapsack
    if (vars[i] == 'schools'){
      dd.2015$counter <- dd.2015$counter * dd.2015$num_schools
    }
    if (vars[i] == 'students'){
      dd.2015$counter <- dd.2015$counter * dd.2015$num_students
    }
    mtg.goal.2015 <- aggregate(dd.2015$counter, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
    names(mtg.goal.2015) <- c('postal_cd', paste('current15', vars[i], 'mtg_affordability', sep='_'))
    
    ## 2015 current - schools:
    ## aggregate over 2015 deluxe schools for each state
    ds.2015$counter <- ds.2015$affordability_goal_knapsack
    if (vars[i] == 'schools'){
      ds.2015$counter <- ds.2015$counter * ds.2015$num_schools
    }
    if (vars[i] == 'students'){
      ds.2015$counter <- ds.2015$counter * ds.2015$num_students
    }
    mtg.goal.2015.sch <- aggregate(ds.2015$counter, by=list(ds.2015$postal_cd), FUN=sum, na.rm=T)
    names(mtg.goal.2015.sch) <- c('postal_cd', paste('current15', vars[i], 'mtg_affordability', sep='_'))
    mtg.goal.2015.sch <- merge(mtg.goal.2015.sch, states.with.schools.dta, all=T)
    
    ## 2016 current:
    ## aggregate over 2016 deluxe districts for each state
    #dd.2016$counter <- ifelse(dd.2016$meeting_3_per_mbps_affordability_target == TRUE, 1, 0)
    dd.2016$counter <- dd.2016$affordability_goal_knapsack
    if (vars[i] == 'schools'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_students
    }
    mtg.goal.2016 <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
    names(mtg.goal.2016) <- c('postal_cd', paste('current16', vars[i], 'mtg_affordability', sep='_'))
    
    ## 2016 current - schools:
    ## aggregate over 2016 deluxe schools for each state
    ds.2016$counter <- ds.2016$affordability_goal_knapsack
    if (vars[i] == 'schools'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_students
    }
    mtg.goal.2016.sch <- aggregate(ds.2016$counter, by=list(ds.2016$postal_cd), FUN=sum, na.rm=T)
    names(mtg.goal.2016.sch) <- c('postal_cd', paste('current16', vars[i], 'mtg_affordability', sep='_'))
    mtg.goal.2016.sch <- merge(mtg.goal.2016.sch, states.with.schools.dta, all=T)
    
    ## merge in stats to dta
    dta <- merge(dta, mtg.goal.sots.2015[,c('postal_cd', paste('sots15', vars[i], 'mtg_affordability', sep='_'))], by='postal_cd', all=T)
    dta <- merge(dta, mtg.goal.2015[,c('postal_cd', paste('current15', vars[i], 'mtg_affordability', sep='_'))], by='postal_cd', all.x=T)
    dta <- merge(dta, mtg.goal.2016[,c('postal_cd', paste('current16', vars[i], 'mtg_affordability', sep='_'))], by='postal_cd', all.x=T)
    ## add in national level population
    cols <- c(paste('sots15', vars[i], 'mtg_affordability', sep='_'), paste('current15', vars[i], 'mtg_affordability', sep='_'), paste('current16', vars[i], 'mtg_affordability', sep='_'))
    for (j in 1:length(cols)){
      dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
    }
    ## merge in schools-level metrics for the states with schools
    ## order the datasets the same
    dta <- dta[order(dta$postal_cd),]
    mtg.goal.2016.sch <- mtg.goal.2016.sch[order(mtg.goal.2016.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16', vars[i], 'mtg_affordability', sep='_')] <-
      mtg.goal.2016.sch[mtg.goal.2016.sch$postal_cd %in% states.with.schools, paste('current16', vars[i], 'mtg_affordability', sep='_')]
    mtg.goal.2015.sch <- mtg.goal.2015.sch[order(mtg.goal.2015.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current15', vars[i], 'mtg_affordability', sep='_')] <-
      mtg.goal.2015.sch[mtg.goal.2015.sch$postal_cd %in% states.with.schools, paste('current15', vars[i], 'mtg_affordability', sep='_')]
    
    
    ## 2) Districts Meeting Affordability Goal (%): "_districts_mtg_affordability_perc", _schools_mtg_affordability_perc", "_students_mtg_affordability_perc"
    ##--------------------------------------------------------------------------------------------------------------------------------
    ## for each dataset, aggregate through dta and calculate the percentage of the samples
    datasets <- c('sots15', 'current15', 'current16')
    for (j in 1:length(datasets)){
      new.col.name <- paste(datasets[j], vars[i], "mtg_affordability_perc", sep='_')
      ## don't round the percentage yet, so can calculate the ranking first
      dta[,new.col.name] <- (dta[,paste(datasets[j], vars[i], 'mtg_affordability', sep='_')] / dta[,paste(datasets[j], vars[i], "sample", sep='_')]) * 100
    }
  }
  
  
  ## 3) Weighted Average Cost/Mbps
  ##----------------------------------------------------------------------------------------------------
  ## sots 2015:
  ## aggregate over 2015 deluxe districts for each state
  total.cost.sots.2015 <- aggregate(sots.districts.2015$total_monthly_cost.recalc, by=list(sots.districts.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.cost.sots.2015) <- c('postal_cd', 'sots15_total_cost')
  
  ## 2015 current:
  ## aggregate over 2015 deluxe districts for each state
  total.cost.current.2015 <- aggregate(dd.2015$ia_monthly_cost_total, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.cost.current.2015) <- c('postal_cd', 'current15_total_cost')
  
  ## 2015 current: -- schools
  ## aggregate over 2015 deluxe districts for each state
  total.cost.current.2015.sch <- aggregate(ds.2015$ia_monthly_cost_total, by=list(ds.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.cost.current.2015.sch) <- c('postal_cd', 'current15_total_cost')
  total.cost.current.2015.sch <- merge(total.cost.current.2015.sch, states.with.schools.dta, all=T)
  
  ## 2016 current:
  dd.2016.cost <- dd.2016[dd.2016$exclude_from_ia_cost_analysis == FALSE,]
  ## aggregate over 2016 deluxe districts for each state
  total.cost.current.2016 <- aggregate(dd.2016.cost$ia_monthly_cost_total, by=list(dd.2016.cost$postal_cd), FUN=sum, na.rm=T)
  names(total.cost.current.2016) <- c('postal_cd', 'current16_total_cost')
  
  ## 2016 current: -- schools
  ds.2016.cost <- ds.2016[ds.2016$exclude_from_ia_cost_analysis == FALSE,]
  ## aggregate over 2016 deluxe districts for each state
  total.cost.current.2016.sch <- aggregate(ds.2016.cost$ia_monthly_cost_total, by=list(ds.2016.cost$postal_cd), FUN=sum, na.rm=T)
  names(total.cost.current.2016.sch) <- c('postal_cd', 'current16_total_cost')
  total.cost.current.2016.sch <- merge(total.cost.current.2016.sch, states.with.schools.dta, all=T)
  
  ## merge in stats to dta
  dta <- merge(dta, total.cost.sots.2015, by='postal_cd', all=T)
  dta <- merge(dta, total.cost.current.2015, by='postal_cd', all.x=T)
  dta <- merge(dta, total.cost.current.2016, by='postal_cd', all.x=T)
  
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  total.cost.current.2016.sch <- total.cost.current.2016.sch[order(total.cost.current.2016.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current16_total_cost'] <-
    total.cost.current.2016.sch[total.cost.current.2016.sch$postal_cd %in% states.with.schools, 'current16_total_cost']
  total.cost.current.2015.sch <- total.cost.current.2015.sch[order(total.cost.current.2015.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current15_total_cost'] <-
    total.cost.current.2015.sch[total.cost.current.2015.sch$postal_cd %in% states.with.schools, 'current15_total_cost']
  
  ## calculate cost per mbps
  ## for each dataset, aggregate through dta and calculate the bw/student
  datasets <- c('sots15', 'current15', 'current16')
  for (j in 1:length(datasets)){
    new.col.name <- paste(datasets[j], "mean_cost_per_mbps", sep='_')
    ## have to divide the total bw by 1,000 since we converted it to kbps in the connectivity function
    dta[,new.col.name] <- round(dta[,paste(datasets[j], "total_cost", sep='_')] / (dta[,paste(datasets[j], "total_bw", sep='_')] / 1000), 2)
  }
  
  ## add national number
  dta$current15_mean_cost_per_mbps[dta$postal_cd == 'ALL'] <- round(sum(dd.2015$ia_monthly_cost_total[dd.2015$postal_cd != 'AK'], na.rm=T) / (sum(dta$current15_total_bw[dta$postal_cd != 'AK'], na.rm=T)/1000), 2)
  dta$current16_mean_cost_per_mbps[dta$postal_cd == 'ALL'] <- round(sum(dd.2016.cost$ia_monthly_cost_total[dd.2016$postal_cd != 'AK'], na.rm=T) / (sum(dta$current16_total_bw[dta$postal_cd != 'AK'], na.rm=T)/1000), 2)
  
  
  ## 4) Median Cost/Mbps, all districts
  ##----------------------------------------------------------------------------------------------------
  current15.median.cost.per.mbps <- aggregate(dd.2015$ia_monthly_cost_per_mbps, by=list(dd.2015$postal_cd), FUN=median, na.rm=T)
  names(current15.median.cost.per.mbps) <- c('postal_cd', 'current15_median_cost_per_mbps_all')
  current15.median.cost.per.mbps$current15_median_cost_per_mbps_all <- round(current15.median.cost.per.mbps$current15_median_cost_per_mbps_all, 2)
  ## merge into dta
  dta <- merge(dta, current15.median.cost.per.mbps, by='postal_cd', all.x=T)
  ## add national number
  dta$current15_median_cost_per_mbps_all[dta$postal_cd == 'ALL'] <- round(median(dd.2015$ia_monthly_cost_per_mbps[dd.2015$postal_cd != 'AK'], na.rm=T), 2)
  
  current16.median.cost.per.mbps <- aggregate(dd.2016.cost$ia_monthly_cost_per_mbps, by=list(dd.2016.cost$postal_cd), FUN=median, na.rm=T)
  names(current16.median.cost.per.mbps) <- c('postal_cd', 'current16_median_cost_per_mbps_all')
  current16.median.cost.per.mbps$current16_median_cost_per_mbps_all <- round(current16.median.cost.per.mbps$current16_median_cost_per_mbps_all, 2)
  ## merge into dta
  dta <- merge(dta, current16.median.cost.per.mbps, by='postal_cd', all.x=T)
  ## add national number
  dta$current16_median_cost_per_mbps_all[dta$postal_cd == 'ALL'] <- round(median(dd.2016.cost$ia_monthly_cost_per_mbps[dd.2016.cost$postal_cd != 'AK'], na.rm=T), 2)
  
  ##************************************************************************************************************************************
  ## CLICK-THROUGH DATA
  ## combine schools level and district level for this click-through
  dd.2016 <- dd.2016[!dd.2016$postal_cd %in% states.with.schools,]
  dd.2016 <- rbind(dd.2016, ds.2016)
  ## create data subset to be displayed in the tool -- those not meeting goals
  affordability.click.through <- dd.2016[, c('postal_cd', 'esh_id', 'name', 'locale', 'district_size',
                                             'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date', 'num_internet_upstream_lines',
                                             'num_students', 'ia_monthly_cost_per_mbps', 'ia_bw_mbps_total',
                                             'ia_monthly_cost_total', 'target_bandwidth', 'affordability_goal_knapsack')]
  names(affordability.click.through)[names(affordability.click.through) %in% c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total',
                                                                             'target_bandwidth', 'affordability_goal_knapsack')] <- 
    paste(names(affordability.click.through)[names(affordability.click.through) %in% c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total', 
                                                                                     'target_bandwidth', 'affordability_goal_knapsack')], '_2016', sep='')
  affordability.click.through$meeting_affordability_goal_knapsack_2016 <- ifelse(affordability.click.through$affordability_goal_knapsack_2016 == 1, TRUE, FALSE)
  affordability.click.through$affordability_goal_knapsack_2016 <- NULL
  
  ## merge in 2015 data too
  affordability.click.through <- merge(affordability.click.through, dd.2015[,c('esh_id', 'ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total',
                                                                               'target_bandwidth', 'affordability_goal_knapsack')], by='esh_id', all.x=T)
  names(affordability.click.through)[names(affordability.click.through) %in% c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total',
                                                                             'target_bandwidth', 'affordability_goal_knapsack')] <- 
    paste(names(affordability.click.through)[names(affordability.click.through) %in% c('ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total',
                                                                                     'target_bandwidth', 'affordability_goal_knapsack')], '_2015', sep='')
  affordability.click.through$meeting_affordability_goal_knapsack_2015 <- ifelse(affordability.click.through$affordability_goal_knapsack_2015 == 1, TRUE, FALSE)
  affordability.click.through$affordability_goal_knapsack_2015 <- NULL
  
  ## round out variables
  affordability.click.through[,names(affordability.click.through)[grepl("ia_monthly_cost_per_mbps", names(affordability.click.through))]] <-
    round(affordability.click.through[,names(affordability.click.through)[grepl("ia_monthly_cost_per_mbps", names(affordability.click.through))]], 2)
  affordability.click.through[,names(affordability.click.through)[grepl("ia_bw_mbps_total", names(affordability.click.through))]] <-
    round(affordability.click.through[,names(affordability.click.through)[grepl("ia_bw_mbps_total", names(affordability.click.through))]], 0)
  affordability.click.through[,names(affordability.click.through)[grepl("ia_monthly_cost_total", names(affordability.click.through))]] <-
    round(affordability.click.through[,names(affordability.click.through)[grepl("ia_monthly_cost_total", names(affordability.click.through))]], 2)
  ## re-order columns
  affordability.click.through <- affordability.click.through[,c(names(affordability.click.through)[1:9], names(affordability.click.through)[15:17],
                                                                  names(affordability.click.through)[10:14])]
  
  ## order the dataset
  affordability.click.through <- affordability.click.through[order(affordability.click.through$ia_monthly_cost_per_mbps_2016, decreasing=T),]
  ## add in IRT links
  affordability.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", affordability.click.through$esh_id, "'>",
                                               "http://irt.educationsuperhighway.org/districts/", affordability.click.through$esh_id, "</a>", sep='')
  
  ##************************************************************************************************************************************
  ## NUMBER OF STUDENTS MEETING AFFORDABILITY GOAL (EXTRAPOLATED)
  
  ## multiply percentage of students meeting to total population of students
  dta$num_students_meeting_affordability_extrap <- (dta$current16_students_mtg_affordability_perc/100)*dta$current16_students_pop
  
  ##************************************************************************************************************************************
  ## NATIONAL RANKING
  
  dta <- national.ranking(dta, "current16_districts_mtg_affordability_perc", "affordability")
  
  assign("dta", dta, envir = .GlobalEnv) 
  assign("affordability.click.through", affordability.click.through, envir=.GlobalEnv)
}
