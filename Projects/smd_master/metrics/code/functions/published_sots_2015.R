## =========================================================================
##
## REFRESH STATE METRICS:
## PUBLISHED
##
## merge in official published SotS metrics
##
## =========================================================================

published.sots.2015 <- function(dta, sots.2015){
  
  ## subset to the relevant columns in SotS Published
  ## column #s: 4, 5, 15, 17, 44
  published.sots <- sots.2015[,c('postal_cd', 'pct_districts_meeting_100kbps',
                                 'X..of.schools..campuses..that.have.fiber.connections..or.equivalent.',
                                 'X..of.school.districts.that.are.meeting.the..3.mbps.IA.affordability.target',
                                 'X.M.in.Erate.funds.are.available.to.support.WiFi.networks.in.state')]
  names(published.sots) <- c('postal_cd', 'sots15_official_published_connectivity_perc', 'sots15_official_published_fiber_perc',
                             'sots15_official_published_affordability_perc', 'sots15_official_published_c2')
  ## also record the official national numbers
  
  ## merge
  dta <- merge(dta, published.sots, by='postal_cd', all.x=T)
  
  ## record the published percentages where they are NA in dta
  ## connectivity -- also correct WY
  dta$sots15_districts_mtg2014goal_perc <- ifelse(is.na(dta$sots15_districts_mtg2014goal_perc) | dta$postal_cd == 'WY', dta$sots15_official_published_connectivity_perc,
                                                  dta$sots15_districts_mtg2014goal_perc)
  ## fiber
  dta$sots15_campuses_on_fiber_perc <- ifelse(is.na(dta$sots15_campuses_on_fiber_perc), dta$sots15_official_published_fiber_perc,
                                                  dta$sots15_campuses_on_fiber_perc)
  ## affordability
  dta$sots15_districts_mtg_affordability_perc <- ifelse(is.na(dta$sots15_districts_mtg_affordability_perc), dta$sots15_official_published_affordability_perc,
                                              dta$sots15_districts_mtg_affordability_perc)
  
  assign("dta", dta, envir = .GlobalEnv)
}
