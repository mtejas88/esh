## =========================================================================
##
## REFRESH STATE METRICS:
## ENGINEERING SUBSET
##
## Format the final data for the engineering team output
##
## =========================================================================

eng.subset <- function(dta, c2.current, dd.clean.compare, sots.2015.ranks){
  
  subset.cols <- c('postal_cd',
                   'state_name',
                   'current16_districts_pop',
                   'current16_schools_pop',
                   'current16_students_pop',
                   'num_upgrades_bw_increase',
                   'num_overlapping_districts',
                   'sots15_districts_mtg2014goal',
                   'current16_districts_mtg2014goal',
                   'sots15_districts_mtg2014goal_perc',
                   'current16_districts_mtg2014goal_perc',
                   'sots15_students_mtg2014goal',
                   'current16_students_mtg2014goal',
                   'sots15_students_mtg2014goal_perc',
                   'current16_students_mtg2014goal_perc',
                   'num_students_meeting_connectivity_goal_extrap_2016',
                   'connectivity_rank_unweighted',
                   'connectivity_rank_weighted',
                   'sots15_campuses_on_fiber',
                   'current16_campuses_on_fiber',
                   'sots15_campuses_on_fiber_perc',
                   'current16_campuses_on_fiber_perc',
                   'num_campuses_on_fiber_extrap',
                   'fiber_rank_unweighted',
                   'fiber_rank_weighted',
                   'sots15_districts_mtg_affordability',
                   'current16_districts_mtg_affordability',
                   'sots15_districts_mtg_affordability_perc',
                   'current16_districts_mtg_affordability_perc',
                   'affordability_rank_unweighted',
                   'affordability_rank_weighted',
                   'c2_remaining_millions_current16',
                   'wifi_rank_unweighted',
                   'wifi_rank_weighted')
  
  dta.sub <- dta[,names(dta) %in% subset.cols]
  ## also add in "Percent of school districts accessing their C2 budget for Wifi
  dta.sub <- merge(dta.sub, c2.current[,c('postal_cd', 'percentage_received_c2_16')], by='postal_cd', all.x=T)
  names(dta.sub)[names(dta.sub) == 'percentage_received_c2_16'] <- 'current16_districts_receiving_c2_perc'
  dta.sub$current16_districts_receiving_c2_perc <- round(dta.sub$current16_districts_receiving_c2_perc, 0)
  
  ## and median increase in school district bandwidth in 2016
  ## aggregate for each state
  upgrades <- dd.clean.compare[dd.clean.compare$upgrade == TRUE,]
  increase.agg <- aggregate(upgrades$diff.bw, by=list(upgrades$postal_cd), FUN=median, na.rm=T)
  names(increase.agg) <- c('postal_cd', 'median_district_total_bw_increase')
  dta.sub <- merge(dta.sub, increase.agg, by='postal_cd', all.x=T)
  ## also do it for national
  dta.sub$median_district_total_bw_increase[dta.sub$postal_cd == 'ALL'] <- median(upgrades$diff.bw, na.rm=T)
  
  ## most improved bandwidth percent (difference between connectivity goal 2015 and 2016)
  dta.sub$bandwidth_diff_perc <- dta.sub$current16_districts_mtg2014goal_perc - dta.sub$sots15_districts_mtg2014goal_perc
  
  ## most upgraded districts percent
  dta.sub$upgrades_perc <- round((dta.sub$num_upgrades_bw_increase / dta.sub$num_overlapping_districts)*100, 0)
  
  ## most new fiber connections percent
  dta.sub$fiber_connections_diff_perc <- dta.sub$current16_campuses_on_fiber_perc - dta.sub$sots15_campuses_on_fiber_perc
  
  ## extrapolated 2015 number of students meeting goal (multiply by the 2016 total number of students)
  #dta.sub$num_students_meeting_connectivity_goal_extrap_2015 <- dta.sub$sots15_students_mtg2014goal_perc * dta.sub$current16_students_pop
  
  ## number of students still left behind in connectivity
  #dta.sub$num_students_left_behind_2016 <- dta.sub$current16_students_pop - dta.sub$num_students_meeting_connectivity_goal_extrap_2016
  
  ## change "N/A" to NA
  sots.2015.ranks$sots15_affordability_rank[sots.2015.ranks$sots15_affordability_rank == "N/A"] <- NA
  ## merge in SotS rankings
  dta.sub <- merge(dta.sub, sots.2015.ranks, by.x='postal_cd', by.y='State', all.x=T)
  
  assign("dta.sub", dta.sub, envir = .GlobalEnv)
}
