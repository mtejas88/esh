## =========================================
##
## FUNCTION: DEFINE BANDWIDTH RANKING
##
## =========================================

bandwidth_ranking <- function(dta){
  
  ## subset to clean districts
  dta <- dta[which(dta$exclude_from_ia_analysis == FALSE),]
  
  ## assign groupings:
  ## < 100K/student = *
  ## [100, 200)/student = **
  ## [200, 500)/student = ***
  ## [500, 1000)/student = ****
  ## >= 1000/student = *****
  dta$group <- ifelse(dta$ia_bandwidth_per_student_kbps < 100, 1,
                          ifelse(dta$ia_bandwidth_per_student_kbps >= 100 & dta$ia_bandwidth_per_student_kbps < 200, 2,
                                 ifelse(dta$ia_bandwidth_per_student_kbps >= 200 & dta$ia_bandwidth_per_student_kbps < 500, 3,
                                        ifelse(dta$ia_bandwidth_per_student_kbps >= 500 & dta$ia_bandwidth_per_student_kbps < 1000, 4,
                                               ifelse(dta$ia_bandwidth_per_student_kbps >= 1000, 5, NA)))))
  
  ## add in grouping for concurrency factor for Megas and Larges (do it both ways)
  dta$ia_bandwidth_per_student_kbps_concurrency <- dta$ia_bandwidth_per_student_kbps * dta$ia_oversub_ratio
  ## grouping with concurrency
  dta$group_concurrency <- ifelse(dta$ia_bandwidth_per_student_kbps < 100, 1,
                                      ifelse(dta$ia_bandwidth_per_student_kbps_concurrency >= 100 & dta$ia_bandwidth_per_student_kbps_concurrency < 200, 2,
                                             ifelse(dta$ia_bandwidth_per_student_kbps_concurrency >= 200 & dta$ia_bandwidth_per_student_kbps_concurrency < 500, 3,
                                                    ifelse(dta$ia_bandwidth_per_student_kbps_concurrency >= 500 & dta$ia_bandwidth_per_student_kbps_concurrency < 1000, 4,
                                                           ifelse(dta$ia_bandwidth_per_student_kbps_concurrency >= 1000, 5, NA)))))
  return(dta)
}

