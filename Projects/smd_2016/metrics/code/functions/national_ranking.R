## =========================================================================
##
## REFRESH STATE METRICS:
## NATIONAL RANKING
##
## calculate national ranking,
## weighted/unweighted with 2016 data
##
## =========================================================================

national.ranking <- function(dta, col, label){
  
  ## Ranking: based on percent of districts meeting goal, 2016
  
  ## first, temporarily take out the national stats
  national.dta <- dta[dta$postal_cd == 'ALL',]
  dta <- dta[dta$postal_cd != 'ALL',]
  
  ## unweighted
  dta <- dta[order(dta[,col], decreasing=T),]
  dta[,paste(label, "_rank_unweighted", sep='')] <- 1:nrow(dta)
  
  ## weighted, based on cleanliness of districts
  dta$weight <- (dta[,col]/100) * (dta$current16_districts_sample_perc/100)
  dta <- dta[order(dta$weight, decreasing=T),]
  dta[,paste(label, "_rank_weighted", sep='')] <- 1:nrow(dta)
  
  ## take out the weights
  dta$weight <- NULL
  
  ## add back in the national stats
  new.cols <- names(dta)[!names(dta) %in% names(national.dta)]
  for (j in 1:length(new.cols)){
    national.dta[,new.cols[j]] <- NA
  }
  dta <- rbind(dta, national.dta)
  
  return(dta)
}
