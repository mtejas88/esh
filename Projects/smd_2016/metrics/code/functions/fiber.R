## =========================================================================
##
## REFRESH STATE METRICS:
## FIBER
##
## 2015 SAMPLE: exclude_from_analysis == FALSE
## 2016 SAMPLE: exclude_from_ia_analysis == FALSE
##
## hist: percent of schools on fiber
## targets: sourced, 2016
## ranking: unweighted/weighted, campuses 2016
##
## =========================================================================

fiber <- function(sots.2015, dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools){
  
  ## METRIC ACROSS TIME
  
  ## save a version of dd.2016 all
  dd.2016.all <- dd.2016
  ds.2016.all <- ds.2016
  ## subset to districts "fit for analysis"
  sots.districts.2015 <- sots.districts.2015
  dd.2015 <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
  ds.2015 <- ds.2015[ds.2015$exclude_from_analysis == FALSE,]
  #dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  ## create subsets for the new fiber metric -- just for 2016
  ## group A: dirty for both ia analysis and fiber analysis
  dd.2016.A <- dd.2016[dd.2016$exclude_from_ia_analysis == TRUE & dd.2016$exclude_from_current_fiber_analysis == TRUE,]
  ## group B: dirty for ia analysis and clean for fiber analysis
  dd.2016.B <- dd.2016[dd.2016$exclude_from_ia_analysis == TRUE & dd.2016$exclude_from_current_fiber_analysis == FALSE,]
  ## group C: clean for both ia analysis and fiber analysis
  dd.2016.C <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE & dd.2016$exclude_from_current_fiber_analysis == FALSE,]
  
  ## create subsets for the new fiber metric -- just for 2016 schools
  ## group A: dirty for both ia analysis and fiber analysis
  ds.2016.A <- ds.2016[ds.2016$exclude_from_ia_analysis == TRUE & ds.2016$exclude_from_current_fiber_analysis == TRUE,]
  ## group B: dirty for ia analysis and clean for fiber analysis
  ds.2016.B <- ds.2016[ds.2016$exclude_from_ia_analysis == TRUE & ds.2016$exclude_from_current_fiber_analysis == FALSE,]
  ## group C: clean for both ia analysis and fiber analysis
  ds.2016.C <- ds.2016[ds.2016$exclude_from_ia_analysis == FALSE & ds.2016$exclude_from_current_fiber_analysis == FALSE,]
  
  ## 1) Campuses on Fiber (Count): "_campuses_on_fiber"
  ##-----------------------------------------------------------
  ## sots 2015: 
  sots.2015[,'sots15_campuses_on_fiber_perc'] <- sots.2015$X..of.schools..campuses..that.have.fiber.connections..or.equivalent.
  
  ## 2015 current:
  ## aggregate across the districts level
  dd.2015$counter <- dd.2015$current_known_scalable_campuses + dd.2015$current_assumed_scalable_campuses
  campuses.on.fiber.2015 <- aggregate(dd.2015$counter, by=list(dd.2015$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2015) <- c('postal_cd', 'current15_campuses_on_fiber')
  
  ## 2015 current: -- schools
  ## aggregate across the districts level
  ds.2015$counter <- ds.2015$current_known_scalable_campuses + ds.2015$current_assumed_scalable_campuses
  campuses.on.fiber.2015.sch <- aggregate(ds.2015$counter, by=list(ds.2015$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2015.sch) <- c('postal_cd', 'current15_campuses_on_fiber')
  campuses.on.fiber.2015.sch <- merge(campuses.on.fiber.2015.sch, states.with.schools.dta, all=T)
  
  ## 2016 current:
  ## New Fiber Metric:
  ## num_scalable_campuses == [#scalable(B & C) + (%scalable C)*(#campuses A)]
  dd.2016.B$counter <- dd.2016.B$current_known_scalable_campuses + dd.2016.B$current_assumed_scalable_campuses
  campuses.on.fiber.2016.B <- aggregate(dd.2016.B$counter, by=list(dd.2016.B$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2016.B) <- c('postal_cd', 'current16_campuses_on_fiber.B')
  dd.2016.C$counter <- dd.2016.C$current_known_scalable_campuses + dd.2016.C$current_assumed_scalable_campuses
  campuses.on.fiber.2016.C <- aggregate(dd.2016.C$counter, by=list(dd.2016.C$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2016.C) <- c('postal_cd', 'current16_campuses_on_fiber.C')
  ## find percent scalable C * #campuses in A for each state
  dd.2016.C$counter.all <- dd.2016.C$num_campuses
  all.campuses.2016.C <- aggregate(dd.2016.C$counter.all, by=list(dd.2016.C$postal_cd), FUN=sum, na.rm=T)
  names(all.campuses.2016.C) <- c("postal_cd", "current16_campuses_all.C")
  ## merge
  campuses.on.fiber.2016.C <- merge(campuses.on.fiber.2016.C, all.campuses.2016.C, by='postal_cd', all=T)
  ## calculate percentage scalable
  campuses.on.fiber.2016.C$percentage.scalable.C <- campuses.on.fiber.2016.C$current16_campuses_on_fiber.C / campuses.on.fiber.2016.C$current16_campuses_all.C
  ## calculate number of campuses in A
  dd.2016.A$counter.all <- dd.2016.A$num_campuses
  all.campuses.2016.A <- aggregate(dd.2016.A$counter.all, by=list(dd.2016.A$postal_cd), FUN=sum, na.rm=T)
  names(all.campuses.2016.A) <- c("postal_cd", "current16_campuses_all.A")
  ## merge
  all.campuses.2016.A <- merge(all.campuses.2016.A, campuses.on.fiber.2016.C, by='postal_cd', all=T)
  all.campuses.2016.A$extrapolated.campuses.on.fiber.2016.A <- all.campuses.2016.A$current16_campuses_all.A * all.campuses.2016.A$percentage.scalable.C
  campuses.on.fiber.2016 <- merge(campuses.on.fiber.2016.B, campuses.on.fiber.2016.C, by='postal_cd', all=T)
  campuses.on.fiber.2016 <- merge(campuses.on.fiber.2016, all.campuses.2016.A[,c('postal_cd', 'extrapolated.campuses.on.fiber.2016.A')], by='postal_cd', all=T)
  campuses.on.fiber.2016$current16_campuses_on_fiber <- rowSums(campuses.on.fiber.2016[,c('current16_campuses_on_fiber.B', 'current16_campuses_on_fiber.C',
                                                        'extrapolated.campuses.on.fiber.2016.A')], na.rm=T)
  
  ## 2016 current -- schools:
  ## New Fiber Metric:
  ## num_unscalable_campuses == [#scalable(B & C) + (%scalable C)*(#campuses A)]
  ds.2016.B$counter <- ds.2016.B$current_known_scalable_campuses + ds.2016.B$current_assumed_scalable_campuses
  campuses.on.fiber.2016.B <- aggregate(ds.2016.B$counter, by=list(ds.2016.B$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2016.B) <- c('postal_cd', 'current16_campuses_on_fiber.B')
  ds.2016.C$counter <- ds.2016.C$current_known_scalable_campuses + ds.2016.C$current_assumed_scalable_campuses
  campuses.on.fiber.2016.C <- aggregate(ds.2016.C$counter, by=list(ds.2016.C$postal_cd), FUN=sum, na.rm=T)
  names(campuses.on.fiber.2016.C) <- c('postal_cd', 'current16_campuses_on_fiber.C')
  ## find percent scalable C * #campuses in A for each state
  ds.2016.C$counter.all <- ds.2016.C$num_campuses
  all.campuses.2016.C <- aggregate(ds.2016.C$counter.all, by=list(ds.2016.C$postal_cd), FUN=sum, na.rm=T)
  names(all.campuses.2016.C) <- c("postal_cd", "current16_campuses_all.C")
  ## merge
  campuses.on.fiber.2016.C <- merge(campuses.on.fiber.2016.C, all.campuses.2016.C, by='postal_cd', all=T)
  ## calculate percentage scalable
  campuses.on.fiber.2016.C$percentage.scalable.C <- campuses.on.fiber.2016.C$current16_campuses_on_fiber.C / campuses.on.fiber.2016.C$current16_campuses_all.C
  ## calculate number of campuses in A -- none for schools-level
  if (nrow(ds.2016.A) > 0){
    ds.2016.A$counter.all <- ds.2016.A$num_campuses
    all.campuses.2016.A <- aggregate(ds.2016.A$counter.all, by=list(ds.2016.A$postal_cd), FUN=sum, na.rm=T)
    names(all.campuses.2016.A) <- c("postal_cd", "current16_campuses_all.A")
    ## merge
    all.campuses.2016.A <- merge(all.campuses.2016.A, campuses.on.fiber.2016.C, by='postal_cd', all=T)
    all.campuses.2016.A$extrapolated.campuses.on.fiber.2016.A <- all.campuses.2016.A$current16_campuses_all.A * all.campuses.2016.A$percentage.scalable.C
    campuses.on.fiber.2016.sch <- merge(campuses.on.fiber.2016.B, campuses.on.fiber.2016.C, by='postal_cd', all=T)
    campuses.on.fiber.2016.sch <- merge(campuses.on.fiber.2016.sch, all.campuses.2016.A[,c('postal_cd', 'extrapolated.campuses.on.fiber.2016.A')], by='postal_cd', all=T)
    campuses.on.fiber.2016.sch$current16_campuses_on_fiber <- rowSums(campuses.on.fiber.2016.sch[,c('current16_campuses_on_fiber.B', 'current16_campuses_on_fiber.C',
                                                                                                    'extrapolated.campuses.on.fiber.2016.A')], na.rm=T)
    campuses.on.fiber.2016.sch <- merge(campuses.on.fiber.2016.sch, states.with.schools.dta, all=T)
  } else{
    all.campuses.2016.A <- NULL
    ## merge
    campuses.on.fiber.2016.sch <- merge(campuses.on.fiber.2016.B, campuses.on.fiber.2016.C, by='postal_cd', all=T)
    campuses.on.fiber.2016.sch$current16_campuses_on_fiber <- rowSums(campuses.on.fiber.2016.sch[,c('current16_campuses_on_fiber.B', 'current16_campuses_on_fiber.C')], na.rm=T)
    campuses.on.fiber.2016.sch <- merge(campuses.on.fiber.2016.sch, states.with.schools.dta, all=T)
  }
  
  
  ## merge in stats to dta
  dta <- merge(dta, sots.2015[,c('postal_cd', 'sots15_campuses_on_fiber_perc')], by='postal_cd', all=T)
  dta <- merge(dta, campuses.on.fiber.2015[,c('postal_cd', 'current15_campuses_on_fiber')], by='postal_cd', all.x=T)
  dta <- merge(dta, campuses.on.fiber.2016[,c('postal_cd', 'current16_campuses_on_fiber')], by='postal_cd', all.x=T)
  ## add in national level population
  cols <- c('current15_campuses_on_fiber', 'current16_campuses_on_fiber')
  for (j in 1:length(cols)){
    dta[dta$postal_cd == 'ALL', names(dta) == cols[j]] <- sum(dta[,names(dta) == cols[j]], na.rm=T)
  }
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  campuses.on.fiber.2016.sch <- campuses.on.fiber.2016.sch[order(campuses.on.fiber.2016.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current16_campuses_on_fiber'] <-
    campuses.on.fiber.2016.sch[campuses.on.fiber.2016.sch$postal_cd %in% states.with.schools, 'current16_campuses_on_fiber']
  campuses.on.fiber.2015.sch <- campuses.on.fiber.2015.sch[order(campuses.on.fiber.2015.sch$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'current15_campuses_on_fiber'] <-
    campuses.on.fiber.2015.sch[campuses.on.fiber.2015.sch$postal_cd %in% states.with.schools, 'current15_campuses_on_fiber']

  
  ## 2) Campuses on Fiber (%): 
  ##---------------------------------------------------------------------------------------------------------------
  ## for each dataset, aggregate through dta and calculate the percentage of the samples
  datasets <- c('current15', 'current16')
  for (j in 1:length(datasets)){
    new.col.name <- paste(datasets[j], "campuses_on_fiber_perc", sep='_')
    ## don't round the percentage yet, so can calculate the ranking first
    if (datasets[j] == 'current15'){
      dta[,new.col.name] <- (dta[,paste(datasets[j], "campuses_on_fiber", sep='_')] / dta[,paste(datasets[j], "campuses_sample", sep='_')]) * 100
    } else{
      dta[,new.col.name] <- (dta[,paste(datasets[j], "campuses_on_fiber", sep='_')] / dta[,paste(datasets[j], "campuses_pop", sep='_')]) * 100
    }
  }
  ## hard code SotS % with fiber -- 88%
  dta$sots15_campuses_on_fiber_perc[dta$postal_cd == 'ALL'] <- 88
  
  ##************************************************************************************************************************************
  ## TARGETS
  ## first, aggregate the number of targets and potential targets at the state level
  ## define function to append the 4 types of target counts
  append.targets <- function(dta, col, campus.flag, states.with.schools){
    if (campus.flag == 1){
      dd.2016.all$counter <- dd.2016.all[,col] * (dd.2016.all$current_known_scalable_campuses + dd.2016.all$current_assumed_scalable_campuses)
      targets <- aggregate(dd.2016.all$counter, by=list(dd.2016.all$postal_cd), FUN=sum)
      col.name <- paste("num_campuses", col, sep='_')
    } else{
      targets <- aggregate(dd.2016.all[,col], by=list(dd.2016.all$postal_cd), FUN=sum)
      col.name <- paste("num", col, sep="_")
    }
    names(targets) <- c('postal_cd', col.name)
    ## merge in dta
    dta <- merge(dta, targets, by='postal_cd', all.x=T)
    ## add national number
    dta[dta$postal_cd == 'ALL', col.name] <- sum(dta[!dta$postal_cd %in% states.with.schools, col.name], na.rm=T)
    return(dta)
  }
  ## make counters for the 4 types:
  ## Targets, Clean Targets, Potential Targets, Clean Potential Targets
  dd.2016.all$fiber_targets <- ifelse(dd.2016.all$fiber_target_status == "Target", 1, 0)
  dd.2016.all$fiber_targets_clean <- ifelse(dd.2016.all$fiber_target_status == "Target" & dd.2016.all$exclude_from_ia_analysis == FALSE, 1, 0)
  dd.2016.all$fiber_po_targets <- ifelse(dd.2016.all$fiber_target_status == "Potential Target", 1, 0)
  dd.2016.all$fiber_po_targets_clean <- ifelse(dd.2016.all$fiber_target_status == "Potential Target" & dd.2016.all$exclude_from_ia_analysis == FALSE, 1, 0)
  
  ## call function for each
  dta <- append.targets(dta, "fiber_targets", 0, states.with.schools)
  dta <- append.targets(dta, "fiber_targets_clean", 0, states.with.schools)
  dta <- append.targets(dta, "fiber_po_targets", 0, states.with.schools)
  dta <- append.targets(dta, "fiber_po_targets_clean", 0, states.with.schools)

  dta <- append.targets(dta, "fiber_targets", 1, states.with.schools)
  dta <- append.targets(dta, "fiber_targets_clean", 1, states.with.schools)
  dta <- append.targets(dta, "fiber_po_targets", 1, states.with.schools)
  dta <- append.targets(dta, "fiber_po_targets_clean", 1, states.with.schools)
  
  
  ## then, create target subset to be displayed in the tool
  ## create an indicator for no data district
  dd.2016.all$no_data <- ifelse(dd.2016.all$lines_w_dirty == 0, TRUE, FALSE)
  ## create number of circuits field
  dd.2016.all$num_circuits <- dd.2016.all$non_fiber_lines + dd.2016.all$fiber_wan_lines + dd.2016.all$fiber_internet_upstream_lines
  ## create total number of unknown campuses field
  dd.2016.all$total_unknown_campuses <- dd.2016.all$current_assumed_scalable_campuses + dd.2016.all$current_assumed_unscalable_campuses
  fiber.targets <- dd.2016.all[dd.2016.all$fiber_target_status == 'Target' | dd.2016.all$fiber_target_status == 'Potential Target',]
  fiber.targets <- fiber.targets[,c('esh_id', 'postal_cd', 'name', 'locale', 'district_size',
                                    'num_students', 'num_campuses', 'num_circuits',
                                    'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
                                    'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total',
                                    'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                    'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses', 'total_unknown_campuses',
                                    'fiber_target_status', 'no_data', names(dd.2016.all)[grepl('exclude', names(dd.2016.all))])]
  
  names(fiber.targets)[names(fiber.targets) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2016'
  names(fiber.targets)[names(fiber.targets) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2016'
  ## merge in 2015 data
  names(dd.2015)[names(dd.2015) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2015'
  names(dd.2015)[names(dd.2015) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2015'
  fiber.targets <- merge(fiber.targets, dd.2015[,c('esh_id', 'bundled_and_dedicated_isp_sp_2015',
                                                                 'most_recent_ia_contract_end_date_2015')], by='esh_id', all.x=T)
  ## round out variables
  fiber.targets$ia_bandwidth_per_student_kbps <- round(fiber.targets$ia_bandwidth_per_student_kbps, 0)
  fiber.targets$ia_bw_mbps_total <- round(fiber.targets$ia_bw_mbps_total, 0)
  ## order the dataset
  fiber.targets <- fiber.targets[order(fiber.targets$current_assumed_unscalable_campuses, decreasing=T),]
  fiber.targets <- fiber.targets[,c('esh_id', 'postal_cd', 'name', 'locale',
                                                  'district_size', 'num_students', 'num_campuses', 'num_circuits',
                                                  'bundled_and_dedicated_isp_sp_2015', 'bundled_and_dedicated_isp_sp_2016',
                                                  'most_recent_ia_contract_end_date_2015', 'most_recent_ia_contract_end_date_2016',
                                                  'ia_bandwidth_per_student_kbps', 'ia_bw_mbps_total',
                                                  'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                                  'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses', 'total_unknown_campuses',
                                                  'fiber_target_status', 'no_data', names(fiber.targets)[grepl('exclude', names(fiber.targets))])]
  ## add in IRT links
  fiber.targets$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", fiber.targets$esh_id, "'>",
                                        "http://irt.educationsuperhighway.org/districts/", fiber.targets$esh_id, "</a>", sep='')
  
  ## also record average number of campuses with assumed or known unscalable
  fiber.targets$sum.unscalable <- fiber.targets$current_assumed_unscalable_campuses + fiber.targets$current_known_unscalable_campuses
  agg.states.mean <- aggregate(fiber.targets$sum.unscalable, by=list(fiber.targets$postal_cd), FUN=mean, na.rm=T)
  names(agg.states.mean) <- c('postal_cd', 'mean_num_campuses_unscalable_targets')
  dta <- merge(dta, agg.states.mean, by='postal_cd', all.x=T)
  dta$mean_num_campuses_unscalable_targets[dta$postal_cd == 'ALL'] <- mean(fiber.targets$sum.unscalable, na.rm=T)
  fiber.targets$sum.unscalable <- NULL
  dta$mean_num_campuses_unscalable_targets <- round(dta$mean_num_campuses_unscalable_targets, 2)
  
  ## CLICK-THROUGH DATA -- those not meeting goals in 2016
  ## create data subset to be displayed in the tool
  ## add in target status indicator
  ## combine schools level and district level for this click-through
  dd.2016 <- dd.2016[!dd.2016$postal_cd %in% states.with.schools,]
  dd.2016 <- rbind(dd.2016, ds.2016)
  fiber.click.through <- dd.2016[,c('postal_cd', 'esh_id', 'name', 'num_campuses',
                                    'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date',
                                    'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                    'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses',
                                    names(dd.2016)[grepl('exclude', names(dd.2016))], names(dd.2016)[grepl('flag', names(dd.2016))],
                                    names(dd.2016)[grepl('tag', names(dd.2016))])]
  names(fiber.click.through)[names(fiber.click.through) == 'bundled_and_dedicated_isp_sp'] <- 'bundled_and_dedicated_isp_sp_2016'
  names(fiber.click.through)[names(fiber.click.through) == 'most_recent_ia_contract_end_date'] <- 'most_recent_ia_contract_end_date_2016'
  ## merge in 2015 data
  fiber.click.through <- merge(fiber.click.through, dd.2015[,c('esh_id', 'bundled_and_dedicated_isp_sp_2015',
                                                   'most_recent_ia_contract_end_date_2015')], by='esh_id', all.x=T)
  #sots.names <- names(fiber.click.through)[grepl('sots', names(fiber.click.through))]
  #fiber.click.through <- fiber.click.through[,!names(fiber.click.through) %in% sots.names]
  fiber.click.through$target <- ifelse(fiber.click.through$esh_id %in% fiber.targets$esh_id, TRUE, FALSE)
  ## order the dataset
  fiber.click.through <- fiber.click.through[order(fiber.click.through$current_assumed_unscalable_campuses, decreasing=T),]
  fiber.click.through <- fiber.click.through[,c('postal_cd', 'esh_id', 'name', 'num_campuses',
                                                'bundled_and_dedicated_isp_sp_2015', 'bundled_and_dedicated_isp_sp_2016',
                                                'most_recent_ia_contract_end_date_2015', 'most_recent_ia_contract_end_date_2016',
                                                'current_known_scalable_campuses', 'current_assumed_scalable_campuses',
                                                'current_assumed_unscalable_campuses', 'current_known_unscalable_campuses',
                                                names(dd.2016)[grepl('exclude', names(dd.2016))], names(dd.2016)[grepl('flag', names(dd.2016))],
                                                names(dd.2016)[grepl('tag', names(dd.2016))])]
  ## add in IRT links
  fiber.click.through$irt_link <- paste("<a href='http://irt.educationsuperhighway.org/districts/", fiber.click.through$esh_id, "'>",
                                                "http://irt.educationsuperhighway.org/districts/", fiber.click.through$esh_id, "</a>", sep='')
  
  
  ##************************************************************************************************************************************
  ## NUMBER OF CAMPUSES ON FIBER (EXTRAPOLATED)
  
  ## multiply percentage of students meeting to total population of students
  #dta$num_campuses_on_fiber_extrap <- round((dta$current16_campuses_on_fiber_perc/100), 2)*dta$current16_campuses_pop
  dta$num_campuses_on_fiber_extrap <- (dta$current16_campuses_on_fiber_perc/100)*dta$current16_campuses_pop
  
  
  ##************************************************************************************************************************************
  ## NATIONAL RANKING
  
  dta <- national.ranking(dta, "current16_campuses_on_fiber_perc", "fiber")
  
  
  assign("dta", dta, envir = .GlobalEnv) 
  assign("fiber.targets", fiber.targets, envir = .GlobalEnv)
  assign("fiber.click.through", fiber.click.through, envir=.GlobalEnv)
}
