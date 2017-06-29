## =========================================================================
##
## REFRESH STATE METRICS:
## POPULATION AND SAMPLING
##
## =========================================================================

population_and_samples <- function(sots.2015, sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools){
  
  ## subset to clean 2015 and 2016
  dd.2015.cl <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
  dd.2016.cl <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
  ## find the districts that were clean in 2015 and dirty in 2016
  dd.2015.leftover <- dd.2015.cl[!dd.2015.cl$esh_id %in% dd.2016.cl$esh_id,]
  ## add in the status of missing dd.2015 districts to dd.2016
  dd.2015.leftover <- dd.2015.leftover[,c('esh_id', 'postal_cd', 'ia_bandwidth_per_student_kbps', 'num_schools', 'num_students', 'num_campuses')]
  dd.2016.with.2015.leftover <- dd.2016.cl[,names(dd.2016.cl) %in% names(dd.2015.leftover)]
  ## combine the districts
  dd.2016.with.2015.leftover <- rbind(dd.2016.with.2015.leftover, dd.2015.leftover)
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  
  ## define the variables we want to capture the population and samples of
  vars <- c('districts', 'schools', 'students', 'campuses')
  
  for (i in 1:length(vars)){
    
    ## 1) Population (Count): "_districts_pop", "_schools_pop", "_students_pop", "campuses_pop"
    ##-------------------------------------------------------------------------------------------      
    ## 2015 current:
    ## aggregate over 2015 deluxe districts for each state
    if (vars[i] == 'districts'){
      dd.2015$counter <- 1
    }
    if (vars[i] == 'schools'){
      dd.2015$counter <- dd.2015$num_schools
    }
    if (vars[i] == 'students'){
      dd.2015$counter <- dd.2015$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2015$counter <- dd.2015$num_campuses
    }
    pop.2015 <- aggregate(dd.2015$counter, by=list(dd.2015$postal_cd), FUN=sum)
    names(pop.2015) <- c('postal_cd', paste('current15_', vars[i], '_pop', sep=''))
    
    ## 2015 current -- schools:
    ## aggregate over 2015 deluxe districts for each state
    if (vars[i] == 'districts'){
      ds.2015$counter <- 1
    }
    if (vars[i] == 'schools'){
      ds.2015$counter <- ds.2015$num_schools
    }
    if (vars[i] == 'students'){
      ds.2015$counter <- ds.2015$num_students
    }
    if (vars[i] == 'campuses'){
      ds.2015$counter <- ds.2015$num_campuses
    }
    pop.2015.sch <- aggregate(ds.2015$counter, by=list(ds.2015$postal_cd), FUN=sum)
    names(pop.2015.sch) <- c('postal_cd', paste('current15_', vars[i], '_pop', sep=''))
    pop.2015.sch <- merge(pop.2015.sch, states.with.schools.dta, all=T)

    
    ## 2016 current:
    ## aggregate over 2016 deluxe districts for each state
    if (vars[i] == 'districts'){
      dd.2016$counter <- 1
    }
    if (vars[i] == 'schools'){
      dd.2016$counter <- dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter <- dd.2016$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2016$counter <- dd.2016$num_campuses
    }
    pop.2016 <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum)
    names(pop.2016) <- c('postal_cd', paste('current16_', vars[i], '_pop', sep=''))
    
    ## 2016 current -- schools:
    ## aggregate over 2016 deluxe districts for each state
    if (vars[i] == 'districts'){
      ds.2016$counter <- 1
    }
    if (vars[i] == 'schools'){
      ds.2016$counter <- ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter <- ds.2016$num_students
    }
    if (vars[i] == 'campuses'){
      ds.2016$counter <- ds.2016$num_campuses
    }
    pop.2016.sch <- aggregate(ds.2016$counter, by=list(ds.2016$postal_cd), FUN=sum)
    names(pop.2016.sch) <- c('postal_cd', paste('current16_', vars[i], '_pop', sep=''))
    pop.2016.sch <- merge(pop.2016.sch, states.with.schools.dta, all=T)
    
    
    ## merge in stats to dta
    dta <- merge(dta, pop.2015[,c('postal_cd', paste('current15_', vars[i], '_pop', sep=''))], by='postal_cd', all.x=T)
    dta <- merge(dta, pop.2016[,c('postal_cd', paste('current16_', vars[i], '_pop', sep=''))], by='postal_cd', all.x=T)
    dta[, paste("sots15_", vars[i], "_pop", sep='')] <- dta[,paste('current15_', vars[i], '_pop', sep='')]
    ## add in national level population
    cols <- c(paste("sots15_", vars[i], "_pop", sep=''), paste("current15_", vars[i], "_pop", sep=''), paste("current16_", vars[i], "_pop", sep=''))
    for (j in 1:length(cols)){
      dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
    }
    ## merge in schools-level metrics for the states with schools
    ## order the datasets the same
    dta <- dta[order(dta$postal_cd),]
    pop.2016.sch <- pop.2016.sch[order(pop.2016.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_pop', sep='')] <-
      pop.2016.sch[pop.2016.sch$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_pop', sep='')]
    pop.2015.sch <- pop.2015.sch[order(pop.2015.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current15_', vars[i], '_pop', sep='')] <-
      pop.2015.sch[pop.2015.sch$postal_cd %in% states.with.schools, paste('current15_', vars[i], '_pop', sep='')]
    
    
    
    ## 2) Samples (Count): "_districts_sample", "_schools_sample", "_students_sample", "_campuses_sample"
    ##-------------------------------------------------------------------------------------------------------   
    ## sots 2015:
    if (vars[i] == "campuses"){
      sots.2015[,paste("sots15_", vars[i], "_sample", sep='')] <- NA
      dta <- merge(dta, sots.2015[,c('postal_cd', paste("sots15_", vars[i], "_sample", sep=''))], by='postal_cd', all=T)
    } else{
      ## aggregate over 2015 deluxe districts for each state
      if (vars[i] == 'districts'){
        sots.districts.2015$counter <- 1
      }
      if (vars[i] == 'schools'){
        sots.districts.2015$counter <- sots.districts.2015$num_schools
      }
      if (vars[i] == 'students'){
        sots.districts.2015$counter <- sots.districts.2015$num_students
      }
      sots.pop.2015 <- aggregate(sots.districts.2015$counter, by=list(sots.districts.2015$postal_cd), FUN=sum)
      names(sots.pop.2015) <- c('postal_cd', paste('sots15_', vars[i], '_sample', sep=''))
      ## add in national level
      sots.pop.2015 <- rbind(sots.pop.2015, c(NA, NA))
      sots.pop.2015$postal_cd[nrow(sots.pop.2015)] <- "ALL"
      sots.pop.2015[nrow(sots.pop.2015),2] <- sum(sots.pop.2015$counter, na.rm=T)
      
      ## merge in stats to dta
      dta <- merge(dta, sots.pop.2015[,c('postal_cd', paste("sots15_", vars[i], "_sample", sep=''))], by='postal_cd', all.x=T)
      ## add in national level population
      cols <- c(paste("sots15_", vars[i], "_sample", sep=''))
      for (j in 1:length(cols)){
        dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[!dta$postal_cd %in% states.with.schools, names(dta) == cols[j]], na.rm=T)
      }
    }
    
    ## 2015 current:
    ## aggregate over 2015 deluxe districts, exclude_from_analysis == false, for each state
    dd.2015$counter_samp <- ifelse(dd.2015$exclude_from_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      dd.2015$counter_samp <- dd.2015$counter_samp * dd.2015$num_schools
    }
    if (vars[i] == 'students'){
      dd.2015$counter_samp <- dd.2015$counter_samp * dd.2015$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2015$counter_samp <- dd.2015$counter_samp * dd.2015$num_campuses
    }
    samp.2015 <- aggregate(dd.2015$counter_samp, by=list(dd.2015$postal_cd), FUN=sum)
    names(samp.2015) <- c('postal_cd', paste('current15_', vars[i], '_sample', sep=''))
    
    ## 2015 current: schools
    ## aggregate over 2015 deluxe districts, exclude_from_analysis == false, for each state
    ds.2015$counter_samp <- ifelse(ds.2015$exclude_from_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      ds.2015$counter_samp <- ds.2015$counter_samp * ds.2015$num_schools
    }
    if (vars[i] == 'students'){
      ds.2015$counter_samp <- ds.2015$counter_samp * ds.2015$num_students
    }
    if (vars[i] == 'campuses'){
      ds.2015$counter_samp <- ds.2015$counter_samp * ds.2015$num_campuses
    }
    samp.2015.sch <- aggregate(ds.2015$counter_samp, by=list(ds.2015$postal_cd), FUN=sum)
    names(samp.2015.sch) <- c('postal_cd', paste('current15_', vars[i], '_sample', sep=''))
    samp.2015.sch <- merge(samp.2015.sch, states.with.schools.dta, all=T)
    
    
    ## 2016 current: IA
    ## aggregate over 2016 deluxe districts, exclude_from_analysis == false, for each state
    dd.2016$counter_samp <- ifelse(dd.2016$exclude_from_ia_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_campuses
    }
    samp.2016 <- aggregate(dd.2016$counter_samp, by=list(dd.2016$postal_cd), FUN=sum)
    names(samp.2016) <- c('postal_cd', paste('current16_', vars[i], '_sample', sep=''))
    
    ## 2016 current: WAN
    ## aggregate over 2016 deluxe districts, exclude_from_analysis == false, for each state
    dd.2016$counter_samp <- ifelse(dd.2016$exclude_from_wan_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2016$counter_samp <- dd.2016$counter_samp * dd.2016$num_campuses
    }
    samp.2016.wan <- aggregate(dd.2016$counter_samp, by=list(dd.2016$postal_cd), FUN=sum)
    names(samp.2016.wan) <- c('postal_cd', paste('current16_', vars[i], '_sample_wan', sep=''))
    
    ## 2016 current: IA -- schools
    ## aggregate over 2016 deluxe districts, exclude_from_analysis == false, for each state
    ds.2016$counter_samp <- ifelse(ds.2016$exclude_from_ia_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_students
    }
    if (vars[i] == 'campuses'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_campuses
    }
    samp.2016.sch <- aggregate(ds.2016$counter_samp, by=list(ds.2016$postal_cd), FUN=sum)
    names(samp.2016.sch) <- c('postal_cd', paste('current16_', vars[i], '_sample', sep=''))
    samp.2016.sch <- merge(samp.2016.sch, states.with.schools.dta, all=T)
    
    ## 2016 current: WAN -- schools
    ## aggregate over 2016 deluxe districts, exclude_from_analysis == false, for each state
    ds.2016$counter_samp <- ifelse(ds.2016$exclude_from_wan_analysis == FALSE, 1, 0)
    if (vars[i] == 'schools'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_schools
    }
    if (vars[i] == 'students'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_students
    }
    if (vars[i] == 'campuses'){
      ds.2016$counter_samp <- ds.2016$counter_samp * ds.2016$num_campuses
    }
    samp.2016.wan.sch <- aggregate(ds.2016$counter_samp, by=list(ds.2016$postal_cd), FUN=sum)
    names(samp.2016.wan.sch) <- c('postal_cd', paste('current16_', vars[i], '_sample_wan', sep=''))
    samp.2016.wan.sch <- merge(samp.2016.wan.sch, states.with.schools.dta, all=T)
    
    ## 2016 current with 2015 leftover clean:
    ## aggregate over 2016 deluxe districts for each state
    if (vars[i] == 'districts'){
      dd.2016.with.2015.leftover$counter <- 1
    }
    if (vars[i] == 'schools'){
      dd.2016.with.2015.leftover$counter <- dd.2016.with.2015.leftover$num_schools
    }
    if (vars[i] == 'students'){
      dd.2016.with.2015.leftover$counter <- dd.2016.with.2015.leftover$num_students
    }
    if (vars[i] == 'campuses'){
      dd.2016.with.2015.leftover$counter <- dd.2016.with.2015.leftover$num_campuses
    }
    samp.2016.with.2015 <- aggregate(dd.2016.with.2015.leftover$counter, by=list(dd.2016.with.2015.leftover$postal_cd), FUN=sum)
    names(samp.2016.with.2015) <- c('postal_cd', paste('current16_with_current15_', vars[i], '_sample', sep=''))
    
    ## merge in stats to dta
    dta <- merge(dta, samp.2015[,c('postal_cd', paste('current15_', vars[i], '_sample', sep=''))], by='postal_cd', all.x=T)
    dta <- merge(dta, samp.2016[,c('postal_cd', paste('current16_', vars[i], '_sample', sep=''))], by='postal_cd', all.x=T)
    dta <- merge(dta, samp.2016.wan[,c('postal_cd', paste('current16_', vars[i], '_sample_wan', sep=''))], by='postal_cd', all.x=T)
    dta <- merge(dta, samp.2016.with.2015[,c('postal_cd', paste('current16_with_current15_', vars[i], '_sample', sep=''))], by='postal_cd', all.x=T)
    ## add in national level population
    cols <- c(paste('current15_', vars[i], '_sample', sep=''), paste('current16_', vars[i], '_sample', sep=''),
              paste('current16_', vars[i], '_sample_wan', sep=''), paste('current16_with_current15_', vars[i], '_sample', sep=''))
    for (j in 1:length(cols)){
      dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
    }
    ## merge in schools-level metrics for the states with schools
    ## order the datasets the same
    dta <- dta[order(dta$postal_cd),]
    samp.2016.sch <- samp.2016.sch[order(samp.2016.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_sample', sep='')] <-
      samp.2016.sch[samp.2016.sch$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_sample', sep='')]
    samp.2016.wan.sch <- samp.2016.wan.sch[order(samp.2016.wan.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_sample_wan', sep='')] <-
      samp.2016.wan.sch[samp.2016.wan.sch$postal_cd %in% states.with.schools, paste('current16_', vars[i], '_sample_wan', sep='')]
    samp.2015.sch <- samp.2015.sch[order(samp.2015.sch$postal_cd),]
    dta[dta$postal_cd %in% states.with.schools, paste('current15_', vars[i], '_sample', sep='')] <-
      samp.2015.sch[samp.2015.sch$postal_cd %in% states.with.schools, paste('current15_', vars[i], '_sample', sep='')]
    
    
    ## 3) Samples (%): "_districts_sample_perc", "_schools_sample_perc", "_students_sample_perc", "_campuses_sample_perc"
    ##----------------------------------------------------------------------------------------------------------------------
    ## for each dataset, aggregate through dta and calculate the percentage of the samples
    datasets <- c('sots15', 'current15', 'current16')
    for (j in 1:length(datasets)){
      new.col.name <- paste(datasets[j], vars[i], "sample_perc", sep='_')
      dta[,new.col.name] <- (dta[,paste(datasets[j], vars[i], "sample", sep='_')] / dta[,paste(datasets[j], vars[i], "pop", sep='_')]) * 100
    }
  }
  
  ## also find number of non-filer districts
  ## 2016
  dd.2016$counter <- ifelse(dd.2016$lines_w_dirty == 0, 1, 0)
  agg <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
  names(agg) <- c('postal_cd', 'current16_num_non_filers')
  dta <- merge(dta, agg, by='postal_cd', all.x=T)
  dta$current16_num_non_filers[dta$postal_cd == 'ALL'] <- sum(dta$current16_num_non_filers, na.rm=T)
  
  ## 2015
  dd.2015$counter <- ifelse(dd.2015$lines_w_dirty == 0, 1, 0)
  agg <- aggregate(dd.2015$counter, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
  names(agg) <- c('postal_cd', 'current15_num_non_filers')
  dta <- merge(dta, agg, by='postal_cd', all.x=T)
  dta$current15_num_non_filers[dta$postal_cd == 'ALL'] <- sum(dta$current15_num_non_filers, na.rm=T)
  
  
  ##************************************************************************************************************************************
  ## CLICK-THROUGH DATA
  ## subset to click-through district info
  current15.click.through.districts <- dd.2015[,c("esh_id", "postal_cd", "name", "locale", "district_size", "district_type",
                                                     "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip", 
                                                  "lines_w_dirty", "exclude_from_analysis")]
  current15.click.through.districts$no_data <- ifelse(current15.click.through.districts$lines_w_dirty == 0, TRUE, FALSE)
  current15.click.through.districts$lines_w_dirty <- NULL
  ## add in IRT links
  current15.click.through.districts$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", current15.click.through.districts$esh_id, "'>",
                                  "http://irt.educationsuperhighway.org/districts/", current15.click.through.districts$esh_id, "</a>", sep='')

  ## subset to click-through district info
  ## combine schools level and district level for this click-through
  dd.2016 <- dd.2016[!dd.2016$postal_cd %in% states.with.schools,]
  dd.2016 <- rbind(dd.2016, ds.2016)
  current16.click.through.districts <- dd.2016[,c("esh_id", "postal_cd", "name", "locale", "district_size", "district_type",
                                                     "num_schools", "num_campuses", "num_students", "frl_percent", "address", "city", "zip", "lines_w_dirty",
                                                  names(dd.2016)[grepl("exclude", names(dd.2016))])]
  current16.click.through.districts$no_data <- ifelse(current16.click.through.districts$lines_w_dirty == 0, TRUE, FALSE)
  current16.click.through.districts$lines_w_dirty <- NULL
  ## add in IRT links
  current16.click.through.districts$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", current16.click.through.districts$esh_id, "'>",
                                                         "http://irt.educationsuperhighway.org/districts/", current16.click.through.districts$esh_id, "</a>", sep='')
  
  
  assign("dta", dta, envir = .GlobalEnv)
  assign("dd.2016.with.2015.leftover", dd.2016.with.2015.leftover, envir=.GlobalEnv)
  assign("current15.click.through.districts", current15.click.through.districts, envir=.GlobalEnv)
  assign("current16.click.through.districts", current16.click.through.districts, envir=.GlobalEnv)
}
