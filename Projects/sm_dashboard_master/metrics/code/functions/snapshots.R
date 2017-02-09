## =========================================================================
##
## REFRESH STATE METRICS:
## SNAPSHOTS
##
## Format the final data to inform state snapshots
##
## =========================================================================

snapshots <- function(dta, dtarural, dtaurban){
  
  ## first, override values for certain states
  ## AK & WY - current15_districts_mtg2014goal_perc
  dta$current15_districts_mtg2014goal_perc[dta$postal_cd == 'AK'] <- 42
  dta$current15_districts_mtg2014goal_perc[dta$postal_cd == 'WY'] <- 100
  
  ## WY -- current15_students_mtg2014goal_perc
  dta$current15_students_mtg2014goal[dta$postal_cd == 'WY'] <- dta$current15_students_sample[dta$postal_cd == 'WY']
  
  ## WY -- num_students_meeting_connectivity_goal_extrap_2015
  dta$num_students_meeting_connectivity_goal_extrap_2015[dta$postal_cd == 'WY'] <- dta$current15_students_pop[dta$postal_cd == 'WY']
  
  ## DE, HI, RI - c2_remaining_millions_current16
  dta$c2_remaining_millions_current16[dta$postal_cd == 'DE'] <- 9
  dta$c2_remaining_millions_current16[dta$postal_cd == 'HI'] <- 12
  dta$c2_remaining_millions_current16[dta$postal_cd == 'RI'] <- 9
  
  ## UT - current16_districts_mtg_affordability_perc
  dta$current16_districts_mtg_affordability_perc[dta$postal_cd == 'UT'] <- NA
  ## data is corrected now so we don't need to make this override
  #dta$current16_districts_mtg_affordability_perc[dta$postal_cd == 'WY'] <- 23
  
  ## CT, UT, & WY - current15_districts_mtg_affordability_perc
  dta$current15_districts_mtg_affordability_perc[dta$postal_cd == 'CT'] <- NA
  dta$current15_districts_mtg_affordability_perc[dta$postal_cd == 'UT'] <- NA
  dta$current15_districts_mtg_affordability_perc[dta$postal_cd == 'WY'] <- NA
  
  ## WY - num_upgrades_bw_increase
  dta$num_upgrades_bw_increase[dta$postal_cd == 'WY'] <- NA
  
  ## WY - num_upgrades_bw_increase
  dta$num_students_upgraded[dta$postal_cd == 'WY'] <- NA
  
  ## WY - current16_campuses_on_fiber_perc
  dta$current16_campuses_on_fiber_perc[dta$postal_cd == 'WY'] <- 88
  
  ## merge in rural and urban stats to dta
  names(dtarural)[names(dtarural) != "postal_cd"] <- paste(names(dtarural)[names(dtarural) != "postal_cd"], "_rural", sep='')
  names(dtaurban)[names(dtaurban) != "postal_cd"] <- paste(names(dtaurban)[names(dtaurban) != "postal_cd"], "_urban", sep='')
  
  merge.to.dta <- function(dta, dta.merge){
    ## merge in the percentages meeting goals for connectivity, fiber, affordability, and wifi
    dta <- merge(dta, dta.merge[,c('postal_cd', names(dta.merge)[grepl('_districts_sample', names(dta.merge))],
                                   names(dta.merge)[grepl('num_upgrades_bw_increase', names(dta.merge))],
                                   names(dta.merge)[grepl('num_overlapping_districts', names(dta.merge))],
                                   names(dta.merge)[grepl('num_overlapping_students', names(dta.merge))],
                                   names(dta.merge)[grepl('num_schools_upgraded', names(dta.merge))],
                                   names(dta.merge)[grepl('num_schools_eligible_upgrade', names(dta.merge))],
                                   names(dta.merge)[grepl('num_students_upgraded', names(dta.merge))],
                                   names(dta.merge)[grepl('num_students_eligible_upgrade', names(dta.merge))],
                                   names(dta.merge)[grepl('_districts_mtg2014goal_perc', names(dta.merge))],
                                   names(dta.merge)[grepl('_campuses_on_fiber_perc', names(dta.merge))],
                                   names(dta.merge)[grepl('current16_districts_pop', names(dta.merge))],
                                   names(dta.merge)[grepl('_districts_mtg_affordability_perc', names(dta.merge))],
                                   names(dta.merge)[grepl('_districts_with_wifi', names(dta.merge))],
                                   names(dta.merge)[grepl('_districts_answered_wifi', names(dta.merge))])],
                 by='postal_cd', all=T)
    return(dta)
  }
  
  dta <- merge.to.dta(dta, dtarural)
  dta <- merge.to.dta(dta, dtaurban)
  
  
  ## round out the columns -- for dta after calculating snapshots
  round.cols <- names(dta)[grepl("_perc", names(dta)) | grepl("_extrap", names(dta))]
  do.not.round <- c("current16_districts_mtg_affordability_perc", "current16_campuses_on_fiber_perc")
  round.cols <- round.cols[!round.cols %in% do.not.round]
  
  for (i in 1:length(round.cols)){
    for (j in 1:nrow(dta)){
      if (100 %in% round(dta[j, round.cols[i]], 0)){
        dta[j, round.cols[i]] <- round(dta[j, round.cols[i]], 1)
      } else{
        dta[j, round.cols[i]] <- round(dta[j, round.cols[i]], 0)
      }
    }
  }
  
  ## read in the template
  #template <- suppressWarnings(read.csv("../data/processed/snapshots/Snapshot_numbers_template.csv", as.is=T, header=T))
  
  #snapshot <- data.frame(matrix(NA, nrow=nrow(dta), ncol=ncol(template)))
  #names(snapshot) <- names(template)
  snapshot <- data.frame(matrix(NA, nrow=nrow(dta), ncol=1))
  snapshot$postal_code <- dta$postal_cd
  
  ## number of students now meeting the goal (extrapolated)
  snapshot$num_students_now_meeting_goal_extrap <- dta$num_students_meeting_connectivity_goal_extrap_2016 - dta$num_students_meeting_connectivity_goal_extrap_2015
  snapshot$num_students_now_meeting_goal_extrap[snapshot$postal_code == 'WY'] <- 0
  ## correct when there are negative numbers
  snapshot$num_students_now_meeting_goal_extrap <- ifelse(snapshot$num_students_now_meeting_goal_extrap < 0, 0,
                                                          snapshot$num_students_now_meeting_goal_extrap)
  
  ## percent students not meeting connectivity goal (extrapolated)
  snapshot$num_students_not_meeting_extrap <- format(dta$current16_students_pop - dta$num_students_meeting_connectivity_goal_extrap_2016, big.mark = ",", nsmall = 0, scientific = FALSE)
  snapshot$num_students_not_meeting_extrap[snapshot$postal_code == 'WY'] <- 0
  
  ## percent of districts meeting goals - 2016
  snapshot$percent_dist_meeting_goal_2016 <- paste(dta$current16_districts_mtg2014goal_perc, "%", sep='')
  
  ## number of students meeting connectivity goal (extrapolated) - 2016
  ## multiply percentage of students meeting to total population of students
  snapshot$num_students_meeting_goal_extrap_2016 <- format(dta$num_students_meeting_connectivity_goal_extrap_2016, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## percent of districts meeting goals - 2015
  snapshot$percent_dist_meeting_goal_2015 <- paste(dta$sots15_districts_mtg2014goal_perc, "%", sep='')
  
  ## number of overlapping districts
  snapshot$num_overlapping_districts <- format(dta$num_overlapping_districts, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of districts upgraded
  snapshot$num_dist_upgraded <- format(dta$num_upgrades_bw_increase, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of overlapping students
  snapshot$num_overlapping_students <- format(dta$num_students_eligible_upgrade, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of students upgraded
  snapshot$num_students_upgraded <- format(dta$num_students_upgraded, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## percent campuses on fiber
  snapshot$percent_campuses_on_fiber_2016 <- paste(dta$current16_campuses_on_fiber_perc, "%", sep='')
  snapshot$percent_campuses_on_fiber_2015 <- paste(dta$sots15_campuses_on_fiber_perc, "%", sep='')
  
  ## percent districts with sufficient wifi
  snapshot$percent_dist_sufficient_wifi <- paste(dta$current16_districts_with_wifi_perc, "%", sep='')
  
  ## amount C2 funds remaining
  snapshot$amount_C2_funds_remain <- paste("$", round(dta$c2_remaining_millions_current16, 0), sep='')
  
  ## percent districts meeting affordability goal
  snapshot$percent_dist_meeting_afford_2016 <- paste(dta$current16_districts_mtg_affordability_perc, "%", sep='')
  snapshot$percent_dist_meeting_afford_curr2015 <- paste(dta$current15_districts_mtg_affordability_perc, "%", sep='')
  
  ## percent students not meeting connectivity goal (extrapolated)
  snapshot$num_students_not_meeting_extrap <- format(dta$current16_students_pop - dta$num_students_meeting_connectivity_goal_extrap_2016, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## percent districts not meeting affordability (2016)
  snapshot$percent_dist_notmeeting_afford_2016 <- paste(round(100 - dta$current16_districts_mtg_affordability_perc, 0), "%", sep='')
  
  ## number of campuses need fiber
  snapshot$num_campuses_needs_fiber <- format(round((1 - dta$current16_campuses_on_fiber_perc/100)*dta$current16_campuses_pop, 0),
                                              big.mark = ",", nsmall = 0, scientific = FALSE)
  #snapshot$num_campuses_needs_fiber[snapshot$postal_code == 'WY'] <- 45
  
  ## total schools in state
  snapshot$total_schools_in_state.1 <- format(dta$current16_schools_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of districts in the sample
  snapshot$num_dist_in_sample <- format(dta$current16_districts_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## total districts in the state
  snapshot$total_dist_in_state <- format(dta$current16_districts_pop, big.mark = ",", nsmall = 0, scientific = FALSE)

  ## number of schools in the sample
  snapshot$num_schools_in_sample <- format(dta$current16_schools_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## total number of schools
  snapshot$total_schools_in_state <- format(dta$current16_schools_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of students in the sample
  snapshot$num_students_in_sample <- format(dta$current16_students_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## total number of students in the state
  snapshot$total_students_in_state <- format(dta$current16_students_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## number of students meeting connectivity goal (extrapolated) - 2016
  ## multiply percentage of students meeting to total population of students
  snapshot$num_students_meeting_goal_extrap_2015 <- format(dta$num_students_meeting_connectivity_goal_extrap_2015, big.mark = ",", nsmall = 0, scientific = FALSE)
  
  ## median cost per mbps
  snapshot$median_cost_per_mbps_2015 <- dta$current15_median_cost_per_mbps_all
  snapshot$median_cost_per_mbps_2016 <- dta$current16_median_cost_per_mbps_all
  
  ## median cost per mbps
  snapshot$median_cost_per_mbps_2015 <- dta$current15_median_cost_per_mbps_all
  snapshot$median_cost_per_mbps_2016 <- dta$current16_median_cost_per_mbps_all
  
  ## mean cost per mbps
  snapshot$weighted_avg_cost_per_mbps_2015 <- dta$current15_mean_cost_per_mbps
  snapshot$weighted_avg_cost_per_mbps_2016 <- dta$current16_mean_cost_per_mbps
  
  ## round the leftover columns
  round.cols <- do.not.round
  for (i in 1:length(round.cols)){
    for (j in 1:nrow(dta)){
      if (100 %in% round(dta[j, round.cols[i]], 0)){
        dta[j, round.cols[i]] <- round(dta[j, round.cols[i]], 1)
      } else{
        dta[j, round.cols[i]] <- round(dta[j, round.cols[i]], 0)
      }
    }
  }
  
  ## round two columns: percent_campuses_on_fiber_2016, percent_dist_meeting_afford_2016
  round.cols <- c("percent_campuses_on_fiber_2016", "percent_dist_meeting_afford_2016")
  for (i in 1:length(round.cols)){
    snapshot[,names(snapshot) == round.cols[i]] <- suppressWarnings(as.numeric(gsub("%", "", snapshot[,names(snapshot) == round.cols[i]])))
    for (j in 1:nrow(snapshot)){
      if (100 %in% round(snapshot[j, round.cols[i]], 0)){
        snapshot[j, round.cols[i]] <- round(snapshot[j, round.cols[i]], 1)
      } else{
        snapshot[j, round.cols[i]] <- round(snapshot[j, round.cols[i]], 0)
      }
    }
    snapshot[,names(snapshot) == round.cols[i]] <- paste(snapshot[,names(snapshot) == round.cols[i]], "%", sep='')
  }
  
  ## drop the first column
  snapshot <- snapshot[,-1]
  
  ## take out DC
  dta <- dta[dta$postal_cd != 'DC',]
  snapshot <- snapshot[snapshot$postal_code != 'DC',]
  
  assign("dta", dta, envir = .GlobalEnv)
  assign("snapshot", snapshot, envir = .GlobalEnv)
}
