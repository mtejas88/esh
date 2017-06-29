## =========================================================================
##
## REFRESH STATE METRICS:
## CONNECTIVITY
## 
## 2015 SAMPLE: exclude_from_analysis == FALSE
## 2016 SAMPLE: exclude_from_ia_analysis == FALSE
##
## looks at both 2014 and 2018 goals
##
## hist: percent of districts meeting goals, schools, students
## targets: stub, 2016
## ranking: unweighted/weighted, districts 2016
##
## =========================================================================

connectivity <- function(sots.districts.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, dd.clean.compare, dd.2016.with.2015.leftover, states.with.schools){
  
  ## METRIC ACROSS TIME
  
  ## save a version of dd.2016 all
  dd.2016.all <- dd.2016
  ## subset to districts "fit for analysis"
  sots.districts.2015 <- sots.districts.2015
  dd.2015 <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
  ds.2015 <- ds.2015[ds.2015$exclude_from_analysis == FALSE,]
  dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
  ds.2016 <- ds.2016[ds.2016$exclude_from_ia_analysis == FALSE,]
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  vars <- c("districts", "schools", "students")
  
  ## add both goals:
  ## 2014 -- 100 kbps/student
  ## 2018 -- 1000 kbps/student
  labels <- c("mtg2014goal", "mtg2018goal")
  goals <- c(100, 1000)
  
  for (i in 1:length(vars)){
    for (k in 1:length(goals)){
      
      ## 1) Meeting Goal (Count): "_districts_mtg2014goal", _schools_mtg2014goal", "_students_mtg2014goal"
      ##----------------------------------------------------------------------------------------------------
      ## sots 2015:
      ## aggregate over 2015 deluxe districts for each state
      sots.districts.2015$counter <- ifelse(sots.districts.2015$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        sots.districts.2015$counter <- sots.districts.2015$counter * sots.districts.2015$num_schools
      }
      if (vars[i] == 'students'){
        sots.districts.2015$counter <- sots.districts.2015$counter * sots.districts.2015$num_students
      }
      mtg.goal.sots.2015 <- aggregate(sots.districts.2015$counter, by=list(sots.districts.2015$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.sots.2015) <- c('postal_cd', paste('sots15', vars[i], labels[k], sep='_'))
      
      
      ## 2015 current:
      ## aggregate over 2015 deluxe districts for each state
      dd.2015$counter <- ifelse(dd.2015$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        dd.2015$counter <- dd.2015$counter * dd.2015$num_schools
      }
      if (vars[i] == 'students'){
        dd.2015$counter <- dd.2015$counter * dd.2015$num_students
      }
      mtg.goal.2015 <- aggregate(dd.2015$counter, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.2015) <- c('postal_cd', paste('current15', vars[i], labels[k], sep='_'))
      
      ## 2015 current -- schools:
      ## aggregate over 2015 deluxe schools for the three states
      ds.2015$counter <- ifelse(ds.2015$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        ds.2015$counter <- ds.2015$counter * ds.2015$num_schools
      }
      if (vars[i] == 'students'){
        ds.2015$counter <- ds.2015$counter * ds.2015$num_students
      }
      mtg.goal.2015.sch <- aggregate(ds.2015$counter, by=list(ds.2015$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.2015.sch) <- c('postal_cd', paste('current15', vars[i], labels[k], sep='_'))
      mtg.goal.2015.sch <- merge(mtg.goal.2015.sch, states.with.schools.dta, all=T)

      
      ## 2016 current:
      ## aggregate over 2016 deluxe districts for each state
      dd.2016$counter <- ifelse(dd.2016$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        dd.2016$counter <- dd.2016$counter * dd.2016$num_schools
      }
      if (vars[i] == 'students'){
        dd.2016$counter <- dd.2016$counter * dd.2016$num_students
      }
      mtg.goal.2016 <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.2016) <- c('postal_cd', paste('current16', vars[i], labels[k], sep='_'))
      
      
      ## 2016 current -- schools:
      ## aggregate over 2016 deluxe schools for the three states
      ds.2016$counter <- ifelse(ds.2016$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        ds.2016$counter <- ds.2016$counter * ds.2016$num_schools
      }
      if (vars[i] == 'students'){
        ds.2016$counter <- ds.2016$counter * ds.2016$num_students
      }
      mtg.goal.2016.sch <- aggregate(ds.2016$counter, by=list(ds.2016$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.2016.sch) <- c('postal_cd', paste('current16', vars[i], labels[k], sep='_'))
      mtg.goal.2016.sch <- merge(mtg.goal.2016.sch, states.with.schools.dta, all=T)
      
      
      ## 2016 current, edited with the districts that were clean in 2015:
      ## aggregate over 2016 deluxe districts for each state
      dd.2016.with.2015.leftover$counter <- ifelse(dd.2016.with.2015.leftover$ia_bandwidth_per_student_kbps >= goals[k], 1, 0)
      if (vars[i] == 'schools'){
        dd.2016.with.2015.leftover$counter <- dd.2016.with.2015.leftover$counter * dd.2016.with.2015.leftover$num_schools
      }
      if (vars[i] == 'students'){
        dd.2016.with.2015.leftover$counter <- dd.2016.with.2015.leftover$counter * dd.2016.with.2015.leftover$num_students
      }
      mtg.goal.2016.with.2015 <- aggregate(dd.2016.with.2015.leftover$counter, by=list(dd.2016.with.2015.leftover$postal_cd), FUN=sum, na.rm=T)
      names(mtg.goal.2016.with.2015) <- c('postal_cd', paste('current16_with_current15', vars[i], labels[k], sep='_'))
      
      
      ## merge in stats to dta
      dta <- merge(dta, mtg.goal.sots.2015[,c('postal_cd', paste('sots15', vars[i], labels[k], sep='_'))], by='postal_cd', all=T)
      dta <- merge(dta, mtg.goal.2015[,c('postal_cd', paste('current15', vars[i], labels[k], sep='_'))], by='postal_cd', all.x=T)
      dta <- merge(dta, mtg.goal.2016[,c('postal_cd', paste('current16', vars[i], labels[k], sep='_'))], by='postal_cd', all.x=T)
      dta <- merge(dta, mtg.goal.2016.with.2015[,c('postal_cd', paste('current16_with_current15', vars[i], labels[k], sep='_'))], by='postal_cd', all.x=T)
      ## add in national level population
      cols <- c(paste('sots15', vars[i], labels[k], sep='_'), paste('current15', vars[i], labels[k], sep='_'),
                paste('current16', vars[i], labels[k], sep='_'), paste('current16_with_current15', vars[i], labels[k], sep='_'))
      for (j in 1:length(cols)){
        dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
      }
      ## merge in schools-level metrics for the states with schools
      ## order the datasets the same
      dta <- dta[order(dta$postal_cd),]
      mtg.goal.2016.sch <- mtg.goal.2016.sch[order(mtg.goal.2016.sch$postal_cd),]
      dta[dta$postal_cd %in% states.with.schools, paste('current16', vars[i], labels[k], sep='_')] <-
        mtg.goal.2016.sch[mtg.goal.2016.sch$postal_cd %in% states.with.schools, paste('current16', vars[i], labels[k], sep='_')]
      mtg.goal.2015.sch <- mtg.goal.2015.sch[order(mtg.goal.2015.sch$postal_cd),]
      dta[dta$postal_cd %in% states.with.schools, paste('current15', vars[i], labels[k], sep='_')] <-
        mtg.goal.2015.sch[mtg.goal.2015.sch$postal_cd %in% states.with.schools, paste('current15', vars[i], labels[k], sep='_')]
      
      
      ## 2) Meeting Goal (%): "_districts_mtg2014goal_perc", _schools_mtg2014goal_perc", "_students_mtg2014goal_perc"
      ##----------------------------------------------------------------------------------------------------------------   
      ## for each dataset, aggregate through dta and calculate the percentage of the samples
      datasets <- c('sots15', 'current15', 'current16', 'current16_with_current15')
      for (j in 1:length(datasets)){
        new.col.name <- paste(datasets[j], vars[i], labels[k], "perc", sep='_')
        ## don't round the percentage yet, so can calculate the ranking first
        dta[,new.col.name] <- (dta[,paste(datasets[j], vars[i], labels[k], sep='_')] / dta[,paste(datasets[j], vars[i], "sample", sep='_')]) * 100 
      }
    }
  }
    
  ## 3) Mean BW/student
  ##----------------------------------------------------------------------------------------------------
  ## sots 2015:
  ## aggregate over 2015 deluxe districts for each state
  total.bw.sots.2015 <- aggregate(sots.districts.2015$total_bw_mbps, by=list(sots.districts.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.bw.sots.2015) <- c('postal_cd', 'sots15_total_bw')
  ## make bw in kbps
  total.bw.sots.2015$sots15_total_bw <- total.bw.sots.2015$sots15_total_bw*1000
  
  ## 2015 current:
  ## aggregate over 2015 deluxe districts for each state
  total.bw.current.2015 <- aggregate(dd.2015$ia_bw_mbps_total, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.bw.current.2015) <- c('postal_cd', 'current15_total_bw')
  ## make bw in kbps
  total.bw.current.2015$current15_total_bw <- total.bw.current.2015$current15_total_bw*1000
  
  ## 2015 current: -- schools
  ## aggregate over 2015 deluxe districts for each state
  total.bw.current.2015.sch <- aggregate(ds.2015$ia_bw_mbps_total, by=list(ds.2015$postal_cd), FUN=sum, na.rm=T)
  names(total.bw.current.2015.sch) <- c('postal_cd', 'current15_total_bw')
  ## make bw in kbps
  total.bw.current.2015.sch$current15_total_bw <- total.bw.current.2015.sch$current15_total_bw*1000
  total.bw.current.2015.sch <- merge(total.bw.current.2015.sch, states.with.schools.dta, all=T)
  
  ## 2016 current:
  ## aggregate over 2016 deluxe districts for each state
  total.bw.current.2016 <- aggregate(dd.2016$ia_bw_mbps_total, by=list(dd.2016$postal_cd), FUN=sum, na.rm=T)
  names(total.bw.current.2016) <- c('postal_cd', 'current16_total_bw')
  ## make bw in kbps
  total.bw.current.2016$current16_total_bw <- total.bw.current.2016$current16_total_bw*1000
  
  ## 2016 current: -- schools
  ## aggregate over 2016 deluxe districts for each state
  total.bw.current.2016.sch <- aggregate(ds.2016$ia_bw_mbps_total, by=list(ds.2016$postal_cd), FUN=sum, na.rm=T)
  names(total.bw.current.2016.sch) <- c('postal_cd', 'current16_total_bw')
  ## make bw in kbps
  total.bw.current.2016.sch$current16_total_bw <- total.bw.current.2016.sch$current16_total_bw*1000
  total.bw.current.2016.sch <- merge(total.bw.current.2016.sch, states.with.schools.dta, all=T)
  
  ## merge in stats to dta
  dta <- merge(dta, total.bw.sots.2015, by='postal_cd', all=T)
  dta <- merge(dta, total.bw.current.2015, by='postal_cd', all.x=T)
  dta <- merge(dta, total.bw.current.2016, by='postal_cd', all.x=T)
  
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  total.bw.current.2016.sch <- total.bw.current.2016.sch[order(total.bw.current.2016.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current16_total_bw'] <-
    total.bw.current.2016.sch[total.bw.current.2016.sch$postal_cd %in% states.with.schools, 'current16_total_bw']
  total.bw.current.2015.sch <- total.bw.current.2015.sch[order(total.bw.current.2015.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current15_total_bw'] <-
    total.bw.current.2015.sch[total.bw.current.2015.sch$postal_cd %in% states.with.schools, 'current15_total_bw']
  
  
  ## calculate BW per student
  ## for each dataset, aggregate through dta and calculate the bw/student
  datasets <- c('sots15', 'current15', 'current16')
  for (j in 1:length(datasets)){
    new.col.name <- paste(datasets[j], "mean_bw_per_student", sep='_')
    dta[,new.col.name] <- round(dta[,paste(datasets[j], "total_bw", sep='_')] / dta[,paste(datasets[j], "students_sample", sep='_')], 1)
  }
  
  
  ## 4) Weighted Average BW/student
  ##----------------------------------------------------------------------------------------------------
  ## sots 2015:
  ## aggregate over 2015 deluxe districts for each state
  total.bw.sots.2015 <- aggregate(sots.districts.2015$ia_bandwidth_per_student_kbps, by=list(sots.districts.2015$postal_cd), FUN=median, na.rm=T)
  names(total.bw.sots.2015) <- c('postal_cd', 'sots15_median_bw_per_student')
  
  ## 2015 current:
  ## aggregate over 2015 deluxe districts for each state
  total.bw.current.2015 <- aggregate(dd.2015$ia_bandwidth_per_student_kbps, by=list(dd.2015$postal_cd), FUN=median, na.rm=T)
  names(total.bw.current.2015) <- c('postal_cd', 'current15_median_bw_per_student')
  
  ## 2015 current: -- schools
  ## aggregate over 2015 deluxe districts for each state
  total.bw.current.2015.sch <- aggregate(ds.2015$ia_bandwidth_per_student_kbps, by=list(ds.2015$postal_cd), FUN=median, na.rm=T)
  names(total.bw.current.2015.sch) <- c('postal_cd', 'current15_median_bw_per_student')
  total.bw.current.2015.sch <- merge(total.bw.current.2015.sch, states.with.schools.dta, all=T)
  
  ## 2016 current:
  ## aggregate over 2016 deluxe districts for each state
  total.bw.current.2016 <- aggregate(dd.2016$ia_bandwidth_per_student_kbps, by=list(dd.2016$postal_cd), FUN=median, na.rm=T)
  names(total.bw.current.2016) <- c('postal_cd', 'current16_median_bw_per_student')
  
  ## 2016 current: -- schools
  ## aggregate over 2016 deluxe districts for each state
  total.bw.current.2016.sch <- aggregate(ds.2016$ia_bandwidth_per_student_kbps, by=list(ds.2016$postal_cd), FUN=median, na.rm=T)
  names(total.bw.current.2016.sch) <- c('postal_cd', 'current16_median_bw_per_student')
  total.bw.current.2016.sch <- merge(total.bw.current.2016.sch, states.with.schools.dta, all=T)
  
  ## merge in stats to dta
  dta <- merge(dta, total.bw.sots.2015, by='postal_cd', all=T)
  dta <- merge(dta, total.bw.current.2015, by='postal_cd', all.x=T)
  dta <- merge(dta, total.bw.current.2016, by='postal_cd', all.x=T)
  
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  total.bw.current.2016.sch <- total.bw.current.2016.sch[order(total.bw.current.2016.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current16_median_bw_per_student'] <-
    total.bw.current.2016.sch[total.bw.current.2016.sch$postal_cd %in% states.with.schools, 'current16_median_bw_per_student']
  total.bw.current.2015.sch <- total.bw.current.2015.sch[order(total.bw.current.2015.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current15_median_bw_per_student'] <-
    total.bw.current.2015.sch[total.bw.current.2015.sch$postal_cd %in% states.with.schools, 'current15_median_bw_per_student']
  
    
  ##************************************************************************************************************************************
  ## NUMBER OF STUDENTS MEETING GOAL (EXTRAPOLATED)
  
  ## number of students meeting connectivity goal (extrapolated)
  ## multiply percentage of students meeting to total population of students
  dta$num_students_meeting_connectivity_goal_extrap_2015 <- (dta$current15_students_mtg2014goal_perc/100) * dta$current15_students_pop
  dta$num_students_meeting_connectivity_goal_extrap_2016 <- (dta$current16_students_mtg2014goal_perc/100) * dta$current16_students_pop
  
  ##************************************************************************************************************************************
  ## NATIONAL RANKING
  
  dta <- national.ranking(dta, paste("current16_districts", labels[1], "perc", sep='_'), "connectivity")
  
  ##************************************************************************************************************************************
  ## TARGETS
  ## first, aggregate the number of targets and potential targets at the state level
  ## define function to append the 4 types of target counts
  append.targets <- function(dta, col){
    targets <- aggregate(dd.2016.all[,col], by=list(dd.2016.all$postal_cd), FUN=sum, na.rm=T)
    col.name <- paste("num", col, sep="_")
    names(targets) <- c('postal_cd', col.name)
    ## merge in dta
    dta <- merge(dta, targets, by='postal_cd', all.x=T)
    ## add national number
    dta[dta$postal_cd == 'ALL', col.name] <- sum(dta[,col.name], na.rm=T)
    return(dta)
  }
  ## make counters for the 4 types:
  ## Targets, Clean Targets, Potential Targets, Clean Potential Targets
  dd.2016.all$conn_targets <- ifelse(dd.2016.all$bw_target_status == "Target", 1, 0)
  dd.2016.all$conn_targets_clean <- ifelse(dd.2016.all$bw_target_status == "Target" & dd.2016.all$exclude_from_ia_analysis == FALSE, 1, 0)
  dd.2016.all$conn_po_targets <- ifelse(dd.2016.all$bw_target_status == "Potential Target", 1, 0)
  dd.2016.all$conn_po_targets_clean <- ifelse(dd.2016.all$bw_target_status == "Potential Target" & dd.2016.all$exclude_from_ia_analysis == FALSE, 1, 0)
  
  ## call function for each
  dta <- append.targets(dta, "conn_targets")
  dta <- append.targets(dta, "conn_targets_clean")
  dta <- append.targets(dta, "conn_po_targets")
  dta <- append.targets(dta, "conn_po_targets_clean")
  
  
  ## then, create target subset to be displayed in the tool
  connectivity.targets <- dd.2016.all[dd.2016.all$bw_target_status == 'Target' | dd.2016.all$bw_target_status == 'Potential Target',]
  connectivity.targets <- connectivity.targets[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                                  'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
                                                  'num_students', 'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total', 'bw_target_status',
                                                  names(dd.2016.all)[grepl('exclude', names(dd.2016.all))])]
  names(connectivity.targets)[names(connectivity.targets) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2016'
  names(connectivity.targets)[names(connectivity.targets) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2016'
  ## merge in 2015 data
  names(dd.2015)[names(dd.2015) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2015'
  names(dd.2015)[names(dd.2015) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2015'
  connectivity.targets <- merge(connectivity.targets, dd.2015[,c('esh_id', 'bundled_and_dedicated_isp_sp_2015',
                                                                 'most_recent_ia_contract_end_date_2015')], by='esh_id', all.x=T)
  ## order the dataset
  connectivity.targets <- connectivity.targets[order(connectivity.targets$bw_target_status, decreasing=T),]
  connectivity.targets <- connectivity.targets[,c('esh_id', 'postal_cd', 'name', 'locale',
                                                  'district_size', 'num_schools', 'num_students',
                                                  'bundled_and_dedicated_isp_sp_2015', 'bundled_and_dedicated_isp_sp_2016',
                                                  'most_recent_ia_contract_end_date_2015', 'most_recent_ia_contract_end_date_2016',
                                                  'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total', 'ia_monthly_cost_total',
                                                  'bw_target_status', names(connectivity.targets)[grepl('exclude', names(connectivity.targets))])]
  ## round out variables
  connectivity.targets$ia_bw_mbps_total <- round(connectivity.targets$ia_bw_mbps_total, 0)
  connectivity.targets$ia_bandwidth_per_student_kbps <- round(connectivity.targets$ia_bandwidth_per_student_kbps, 0)
  connectivity.targets$ia_monthly_cost_total <- round(connectivity.targets$ia_monthly_cost_total, 2)
  ## add in IRT links
  connectivity.targets$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", connectivity.targets$esh_id, "'>",
                                          "http://irt.educationsuperhighway.org/districts/", connectivity.targets$esh_id, "</a>", sep='')
  
  
  ## CLICK-THROUGH DATA
  ## combine schools level and district level for this click-through
  dd.2016 <- dd.2016[!dd.2016$postal_cd %in% states.with.schools,]
  dd.2016 <- rbind(dd.2016, ds.2016)
  ## create data subset to be displayed in the tool
  connectivity.click.through <- dd.2016[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools',
                                           'num_students', 'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total',
                                           'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date')]
  names(connectivity.click.through)[names(connectivity.click.through) == 'ia_bandwidth_per_student_kbps'] <- 'ia_bandwidth_per_student_kbps_2016'
  names(connectivity.click.through)[names(connectivity.click.through) == 'ia_bw_mbps_total'] <- 'ia_bw_mbps_total_2016'
  names(connectivity.click.through)[names(connectivity.click.through) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2016'
  names(connectivity.click.through)[names(connectivity.click.through) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2016'
  names(dd.2015)[names(dd.2015) == 'ia_bandwidth_per_student_kbps'] <- 'ia_bandwidth_per_student_kbps_2015'
  names(dd.2015)[names(dd.2015) == 'ia_bw_mbps_total'] <- 'ia_bw_mbps_total_2015'
  connectivity.click.through <- merge(connectivity.click.through, dd.2015[,c('esh_id','ia_bandwidth_per_student_kbps_2015', 'ia_bw_mbps_total_2015',
                                                                             'bundled_and_dedicated_isp_sp_2015', 'most_recent_ia_contract_end_date_2015')], by='esh_id', all.x=T)
  connectivity.click.through$ia_bandwidth_per_student_kbps_2016 <- round(connectivity.click.through$ia_bandwidth_per_student_kbps_2016, 1)
  connectivity.click.through$meeting_goals_2015 <- ifelse(is.na(connectivity.click.through$ia_bandwidth_per_student_kbps_2015), NA,
                                                          ifelse(connectivity.click.through$ia_bandwidth_per_student_kbps_2015 > 100, TRUE, FALSE))
  connectivity.click.through$meeting_goals_2016 <- ifelse(connectivity.click.through$ia_bandwidth_per_student_kbps_2016 > 100, TRUE, FALSE)
  connectivity.click.through$target <- ifelse(connectivity.click.through$esh_id %in% connectivity.targets$esh_id, TRUE, FALSE)
  connectivity.click.through <- connectivity.click.through[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size', 'num_schools', 'num_students',
                                                              'bundled_and_dedicated_isp_sp_2015', 'bundled_and_dedicated_isp_sp_2016',
                                                              'most_recent_ia_contract_end_date_2015', 'most_recent_ia_contract_end_date_2016',
                                                              'ia_bandwidth_per_student_kbps_2015', 'ia_bandwidth_per_student_kbps_2016',
                                                              'ia_bw_mbps_total_2015', 'ia_bw_mbps_total_2016', 'meeting_goals_2015',
                                                              'meeting_goals_2016', 'target')]
  ## merge in 2016 clean status
  connectivity.click.through <- merge(connectivity.click.through, dd.2016[,c('esh_id', names(dd.2016)[grepl('exclude', names(dd.2016))])], by='esh_id', all.x=T)
  ## take out duplicates created after merge
  connectivity.click.through <- connectivity.click.through[!duplicated(connectivity.click.through),]
  ## round out variables
  connectivity.click.through$ia_bandwidth_per_student_kbps_2015 <- round(connectivity.click.through$ia_bandwidth_per_student_kbps_2015, 0)
  connectivity.click.through$ia_bandwidth_per_student_kbps_2016 <- round(connectivity.click.through$ia_bandwidth_per_student_kbps_2016, 0)
  connectivity.click.through$ia_bw_mbps_total_2015 <- round(connectivity.click.through$ia_bw_mbps_total_2015, 0)
  ## add in IRT links
  connectivity.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", connectivity.click.through$esh_id, "'>",
                                         "http://irt.educationsuperhighway.org/districts/", connectivity.click.through$esh_id, "</a>", sep='')
  ## order the dataset by not meeting goals in 2015 to meeting goals in 2016
  connectivity.click.through <- connectivity.click.through[order(connectivity.click.through$meeting_goals_2015, rev(connectivity.click.through$meeting_goals_2016), decreasing=F),]
  
  
  ## MERGE IN MEETING GOAL STATUS TO UPGRADES
  dd.clean.compare <- merge(dd.clean.compare, connectivity.click.through[,c('esh_id', 'meeting_goals_2015', 'meeting_goals_2016')], by='esh_id', all.x=T)
  ## create a counter for the districts that were not meeting goals in 2015 and are meeting goals in 2016 after upgrading
  dd.clean.compare$counter <- ifelse(dd.clean.compare$meeting_goals_2015 == FALSE & dd.clean.compare$meeting_goals_2016 == TRUE & dd.clean.compare$upgrade == TRUE, 1, 0)
  meeting.goal.upgrade <- aggregate(dd.clean.compare$counter, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(meeting.goal.upgrade) <- c('postal_cd', 'districts_now_meeting_goals')
  ## merge in dta
  dta <- merge(dta, meeting.goal.upgrade, by='postal_cd', all.x=T)
  ## add in national stat
  dta$districts_now_meeting_goals[dta$postal_cd == 'ALL'] <- sum(dta$districts_now_meeting_goals, na.rm=T)
  
  ## calculate students now meeting goals
  dd.clean.compare$counter.students <- dd.clean.compare$counter * dd.clean.compare$num_students_2016
  meeting.goal.upgrade.students <- aggregate(dd.clean.compare$counter.students, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(meeting.goal.upgrade.students) <- c('postal_cd', 'students_now_meeting_goals')
  ## merge in dta
  dta <- merge(dta, meeting.goal.upgrade.students, by='postal_cd', all.x=T)
  ## add in national stat
  dta$students_now_meeting_goals[dta$postal_cd == 'ALL'] <- sum(dta$students_now_meeting_goals, na.rm=T)
  
  dd.clean.compare$counter <- NULL
  dd.clean.compare$counter.students <- NULL
  ## sort dd.clean.compare by decreasing bw change
  dd.clean.compare <- dd.clean.compare[order(dd.clean.compare$diff.bw, decreasing=T),]
  ## add in IRT links
  dd.clean.compare$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", dd.clean.compare$esh_id, "'>",
                                     "http://irt.educationsuperhighway.org/districts/", dd.clean.compare$esh_id, "</a>", sep='')
  
  assign("dta", dta, envir = .GlobalEnv) 
  assign("connectivity.targets", connectivity.targets, envir = .GlobalEnv)
  assign("connectivity.click.through", connectivity.click.through, envir=.GlobalEnv)
  assign("dd.clean.compare", dd.clean.compare, envir = .GlobalEnv)
}
  