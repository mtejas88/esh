## =========================================================================
##
## REFRESH STATE METRICS:
## ADJUST SCHOOL-LEVEL METRICS
##
## hard code the SotS metrics for the three states
##
## =========================================================================

adjust.school.level.metrics <- function(dta, states.with.schools, dd.clean.compare, i){
  
  ## replace SotS 2015 stats with ones published
  dta[dta$postal_cd %in% states.with.schools, grepl("sots15", names(dta))] <- NA
  if (i == 3){
    ## order: DE, HI, RI
    dta$sots15_districts_pop[dta$postal_cd %in% states.with.schools] <- c(196, 256, NA)
    dta$sots15_districts_sample[dta$postal_cd %in% states.with.schools] <- c(126, 249, NA)
    dta$sots15_districts_sample_perc[dta$postal_cd %in% states.with.schools] <- (dta$sots15_districts_sample[dta$postal_cd %in% states.with.schools] /
                                                                                   dta$sots15_districts_pop[dta$postal_cd %in% states.with.schools]) * 100
    dta$sots15_districts_mtg2014goal_perc[dta$postal_cd %in% states.with.schools] <- c(52, 100, NA)
    dta$sots15_campuses_on_fiber_perc[dta$postal_cd %in% states.with.schools] <- c(100, 100, 98)
    dta$sots15_districts_mtg_affordability_perc[dta$postal_cd %in% states.with.schools] <- c(2, 2, NA)
  }
  
  ## make sure the stats for the states at the school level analysis are NA for Wifi and C2
  dta[dta$postal_cd %in% states.with.schools, grepl("c2", names(dta))] <- NA
  
  return(dta)
}