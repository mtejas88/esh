## =========================================================================
##
## REFRESH STATE METRICS:
## WIFI
##
## 2016 SAMPLE: all
##
## number of schools that have adequate wifi
## targets: stub, 2016 -- ask justine about query
## ranking: unweighted/weighted, 2016
##
## =========================================================================

wifi <- function(sots.2015, dd.2016, ds.2016, dta, c2.sots, c2.current, states.with.schools){
  
  ## METRIC ACROSS TIME
  
  ## subset to districts "fit for analysis"
  dd.2016 <- dd.2016[!is.na(dd.2016$needs_wifi),]
  ds.2016 <- ds.2016[!is.na(ds.2016$needs_wifi),]
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  vars <- c("districts", "schools", "students")
  
  for (i in 1:length(vars)){
    
    ## 1) Districts who Have WIFI (Count): "_districts_with_wifi", _schools_with_wifi", "_students_with_wifi"
    ##---------------------------------------------------------------------------------------------------------------------------------------------
    ## 2016 current:
    ## aggregate over 2016 deluxe districts for each state
    dd.2016$counter <- ifelse(dd.2016$needs_wifi == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_students
    }
    has.wifi <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
    names(has.wifi) <- c('postal_cd', paste('current16', vars[i], 'with_wifi', sep='_'))
    
    ## 2016 current: Districts who did not answer NULL to wifi
    ## aggregate over 2016 deluxe districts for each state
    dd.2016$counter <- 1
    if (vars[i] == 'schools'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter <- dd.2016$counter * dd.2016$num_students
    }
    total.answered <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
    names(total.answered) <- c('postal_cd', paste('current16', vars[i], 'answered_wifi', sep='_'))
    
    ## 2016 current - schools:
    ## aggregate over 2016 deluxe districts for each state
    ds.2016$counter <- ifelse(ds.2016$needs_wifi == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_students
    }
    has.wifi.sch <- aggregate(ds.2016$counter, by=list(ds.2016$postal_cd), FUN=sum, na.rm=T)
    names(has.wifi.sch) <- c('postal_cd', paste('current16', vars[i], 'with_wifi', sep='_'))
    has.wifi.sch <- merge(has.wifi.sch, states.with.schools.dta, all=T)
    
    ## 2016 current - schools: Districts who did not answer NULL to wifi
    ## aggregate over 2016 deluxe districts for each state
    ds.2016$counter <- 1
    if (vars[i] == 'schools'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter <- ds.2016$counter * ds.2016$num_students
    }
    total.answered.sch <- aggregate(ds.2016$counter, by=list(ds.2016$postal_cd), FUN=sum, na.rm=T)
    names(total.answered.sch) <- c('postal_cd', paste('current16', vars[i], 'answered_wifi', sep='_'))
    total.answered.sch <- merge(total.answered.sch, states.with.schools.dta, all=T)
    
    
    ## merge in stats to dta
    dta <- merge(dta, has.wifi[,c('postal_cd', paste('current16', vars[i], 'with_wifi', sep='_'))], by='postal_cd', all.x=T)
    dta <- merge(dta, total.answered[,c('postal_cd', paste('current16', vars[i], 'answered_wifi', sep='_'))], by='postal_cd', all.x=T)
    ## add in national level population
    cols <- c(paste('current16', vars[i], 'with_wifi', sep='_'), paste('current16', vars[i], 'answered_wifi', sep='_'))
    for (j in 1:length(cols)){
      dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
    }
    ## merge in schools-level metrics for the states with schools
    ## order the datasets the same
    dta <- dta[order(dta$postal_cd),]
    has.wifi.sch <- has.wifi.sch[order(has.wifi.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16', vars[i], 'with_wifi', sep='_')] <-
      has.wifi.sch[has.wifi.sch$postal_cd %in% states.with.schools, paste('current16', vars[i], 'with_wifi', sep='_')]
    total.answered.sch <- total.answered.sch[order(total.answered.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16', vars[i], 'answered_wifi', sep='_')] <-
      total.answered.sch[total.answered.sch$postal_cd %in% states.with.schools, paste('current16', vars[i], 'answered_wifi', sep='_')]
    
    
    ## 2) Districts with Wifi (%): "_districts_with_wifi_perc", _schools_with_wifi_perc", "_students_with_wifi_perc"
    ##--------------------------------------------------------------------------------------------------------------------------------
    ## for each dataset, aggregate through dta and calculate the percentage of the samples
    datasets <- c('current16')
    
    for (j in 1:length(datasets)){
      new.col.name <- paste(datasets[j], vars[i], "with_wifi_perc", sep='_')
      ## don't round the percentage yet, so can calculate the ranking first
      dta[,new.col.name] <- (dta[,paste(datasets[j], vars[i], 'with_wifi', sep='_')] / dta[,paste(datasets[j], vars[i], "answered_wifi", sep='_')]) * 100
    }
  }

  ##************************************************************************************************************************************
  ## C2 REMAINING
  
  ## merge in C2 data into dta
  names(c2.sots) <- c('postal_cd', 'c2_remaining_millions_sots')
  dta <- merge(dta, c2.sots, by='postal_cd', all.x=T)
  ## add in national stat
  dta$c2_remaining_millions_sots[dta$postal_cd == 'ALL'] <- sum(dta$c2_remaining_millions_sots, na.rm=T)
  
  c2.current <- c2.current[,c('postal_cd', 'c2_postdiscount_remaining_millions_15', 'c2_postdiscount_remaining_millions_16')]
  names(c2.current) <- c('postal_cd', 'c2_remaining_millions_current15', 'c2_remaining_millions_current16')
  dta <- merge(dta, c2.current, by='postal_cd', all.x=T)
  dta$c2_remaining_millions_current15[dta$postal_cd == 'ALL'] <- sum(dta$c2_remaining_millions_current15[!dta$postal_cd %in% states.with.schools], na.rm=T)
  dta$c2_remaining_millions_current16[dta$postal_cd == 'ALL'] <- sum(dta$c2_remaining_millions_current16[!dta$postal_cd %in% states.with.schools], na.rm=T)
  
  ## round the numbers
  dta[,names(dta)[grepl("c2", names(dta))]] <- round(dta[,names(dta)[grepl("c2", names(dta))]], 2)
  
  
  ##************************************************************************************************************************************
  ## NATIONAL RANKING
  
  dta <- national.ranking(dta, "current16_districts_with_wifi_perc", "wifi")
  
  
  assign("dta", dta, envir = .GlobalEnv) 
}
