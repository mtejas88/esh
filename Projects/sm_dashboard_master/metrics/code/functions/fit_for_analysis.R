## =========================================================================
##
## FIT FOR ANALYSIS STATUS TABLE
##
## Generate the fit for analysis status update for the rounds of states
##
## =========================================================================

fit.for.analysis <- function(dd.2016, dta){
  
  ## create data table
  dta.status <- data.frame(postal_cd=dta$postal_cd[dta$postal_cd != 'ALL'])
  dd.2016$include_ia_analysis <- ifelse(dd.2016$exclude_from_ia_analysis == FALSE, 1, 0)
  dd.2016$include_ia_cost_analysis <- ifelse(dd.2016$exclude_from_ia_cost_analysis == FALSE, 1, 0)
  dd.2016$include_wan_analysis <- ifelse(dd.2016$exclude_from_wan_analysis == FALSE, 1, 0)
  dd.2016$include_wan_cost_analysis <- ifelse(dd.2016$exclude_from_wan_cost_analysis == FALSE, 1, 0)
  
  ## total number of districts
  dd.2016$counter <- 1
  total_districts <- aggregate(dd.2016$counter, by=list(dd.2016$postal_cd), FUN=sum)
  names(total_districts) <- c('postal_cd', 'total_districts')
  ## aggregate the multiple subsets (samples)
  include_ia_analysis <- aggregate(dd.2016$include_ia_analysis, by=list(dd.2016$postal_cd), FUN=sum)
  names(include_ia_analysis) <- c('postal_cd', 'fit_for_ia')
  include_ia_cost_analysis <- aggregate(dd.2016$include_ia_cost_analysis, by=list(dd.2016$postal_cd), FUN=sum)
  names(include_ia_cost_analysis) <- c('postal_cd', 'fit_for_ia_cost')
  include_wan_analysis <- aggregate(dd.2016$include_wan_analysis, by=list(dd.2016$postal_cd), FUN=sum)
  names(include_wan_analysis) <- c('postal_cd', 'fit_for_wan')
  include_wan_cost_analysis <- aggregate(dd.2016$include_wan_cost_analysis, by=list(dd.2016$postal_cd), FUN=sum)
  names(include_wan_cost_analysis) <- c('postal_cd', 'fit_for_wan_cost')
  
  ## merge results
  dta.status <- merge(dta.status, total_districts, by='postal_cd', all.x=T)
  dta.status <- merge(dta.status, include_ia_analysis, by='postal_cd', all.x=T)
  dta.status$fit_for_ia_perc <- round((dta.status$fit_for_ia / dta.status$total_districts)*100, 0)
  dta.status <- merge(dta.status, include_ia_cost_analysis, by='postal_cd', all.x=T)
  dta.status$fit_for_ia_cost_perc <- round((dta.status$fit_for_ia_cost / dta.status$total_districts)*100, 0)
  dta.status <- merge(dta.status, include_wan_analysis, by='postal_cd', all.x=T)
  dta.status$fit_for_wan_perc <- round((dta.status$fit_for_wan / dta.status$total_districts)*100, 0)
  dta.status <- merge(dta.status, include_wan_cost_analysis, by='postal_cd', all.x=T)
  dta.status$fit_for_wan_cost_perc <- round((dta.status$fit_for_wan_cost / dta.status$total_districts)*100, 0)
  ## mean fit for analysis percentage
  #dta.status$mean_fit_for_analysis_perc <- rowMeans(dta.status[c("fit_for_ia_perc", "fit_for_ia_cost_perc", "fit_for_wan_perc", "fit_for_wan_cost_perc")], na.rm=T)
  
  ## add in the indicator for states in round 1
  dta.status$round <- ifelse(dta.status$postal_cd %in% c('FL', 'IN', 'KS', 'KY', 'LA', 'MO', 'MT', 'ND', 'NH', 'SD', 'TN', 'VT', 'WV'), 1, 
                               ifelse(dta.status$postal_cd %in% c('AL', 'CT', 'DE', 'ME', 'PA', 'WA'), 2, 
                                      ifelse(dta.status$postal_cd %in% c('CA', 'GA', 'IA', 'ID', 'MI', 'MS', 'NC', 'NJ', 'NV', 'OH', 'SC', 'UT', 'WI'), 3, 
                                             ifelse(dta.status$postal_cd %in% c('AK', 'HI', 'MN', 'NE'), 4, 
                                                    ifelse(dta.status$postal_cd %in% c('AR', 'AZ', 'CO', 'IL', 'MA', 'MD', 'NM', 'NY', 'OK', 'OR', 'RI', 'TX', 'VA', 'WY'), 5, 0)))))
  
  ## sort by decreasing cleanliness and round engaged
  dta.status <- dta.status[order(rev(dta.status$round), dta.status$fit_for_ia_perc, decreasing=T),]
  
  assign("dta.status", dta.status, envir = .GlobalEnv)
}
