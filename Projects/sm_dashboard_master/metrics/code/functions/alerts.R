## =========================================================================
##
## REFRESH STATE METRICS:
## ALERTS
##
## Signals whether the timeline from sots 2015, current 2015, and current 2016 
## is not what we expect for the major stats.
## 
## This check looks for whether Current 2015 is within SOTS 2015 by 10% AND
## whether there is a sizable increase for Current 2016 from Current 2015.
##
## =========================================================================

alerts <- function(dta){
  
  ## define function to calculate alerts -- based on 10% magnitude change
  magnitude.alerts <- function(title, column, dta){
    dta[,paste(title, "alert_2015", sep="_")] <- ifelse(abs(dta[,paste("current15", column, sep="_")] - dta[,paste("sots15", column, sep="_")])/
                                                          dta[,paste("sots15", column, sep="_")] > 0.10, 1, 0)
    dta[,paste(title, "alert_2016", sep="_")] <- ifelse(abs(dta[,paste("current16", column, sep="_")] - dta[,paste("current15", column, sep="_")])/
                                                          dta[,paste("current15", column, sep="_")] <= 0.10, 1, 0)
    return(dta)
  }
  
  ## define function to calculate alerts -- based on overall decrease between years
  sign.alerts <- function(title, column, dta){
    dta[,paste(title, "alert_2015", sep="_")] <- ifelse(dta[,paste("current15", column, sep="_")] < dta[,paste("sots15", column, sep="_")], 1, 0)
    dta[,paste(title, "alert_2016", sep="_")] <- ifelse(dta[,paste("current16", column, sep="_")] < dta[,paste("current15", column, sep="_")], 1, 0)
    return(dta)
  }
  
  dta <- magnitude.alerts("connectivity", "districts_mtg2014goal_perc", dta)
  dta <- sign.alerts("connectivity_decrease", "districts_mtg2014goal_perc", dta)
  dta <- magnitude.alerts("fiber", "campuses_on_fiber_perc", dta)
  dta <- sign.alerts("fiber_decrease", "campuses_on_fiber_perc", dta)
  dta <- magnitude.alerts("affordability", "districts_mtg_3permbps_perc", dta)
  dta <- sign.alerts("affordability_decrease", "districts_mtg_3permbps_perc", dta)
  #dta <- magnitude.alerts("wifi", "", dta)
  #dta <- sign.alerts("wifi", "", dta)
  
  return(dta)
}
