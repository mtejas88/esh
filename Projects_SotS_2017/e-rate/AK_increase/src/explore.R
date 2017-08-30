## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

perc_IA <- read.csv("data/perc_IA.csv", as.is=T, header=T, stringsAsFactors=F)
total_sr <- read.csv("data/total_sr.csv", as.is=T, header=T, stringsAsFactors=F)
wtd_avg_bw <- read.csv("data/wtd_avg_bw.csv", as.is=T, header=T, stringsAsFactors=F)
one_mbps <- read.csv("data/one_mbps.csv", as.is=T, header=T, stringsAsFactors=F)
wan <- read.csv("data/wan.csv", as.is=T, header=T, stringsAsFactors=F)

#clean up t/f columns
perc_IA$postal_cd_ak <- perc_IA$postal_cd_ak == 't'
total_sr$postal_cd_ak <- total_sr$postal_cd_ak == 't'
wtd_avg_bw$postal_cd_ak <- wtd_avg_bw$postal_cd_ak == 't'
one_mbps$postal_cd_ak <- one_mbps$postal_cd_ak == 't'

#4. Find extrap $ IA in AK (Step 0 * Step 3)
extrap.ia.ak <- perc_IA[perc_IA$postal_cd_ak == T & 
                          perc_IA$purpose_adj == 'Internet', 'perc_monthly_cost'] * 
                total_sr[total_sr$postal_cd_ak == T, 'total_costs']

#6. Find extrap $ IA not in AK (Step 5 * Step 1)
extrap.ia.not.ak <- perc_IA[perc_IA$postal_cd_ak == F & 
                          perc_IA$purpose_adj == 'Internet', 'perc_monthly_cost'] * 
                    total_sr[total_sr$postal_cd_ak == F, 'total_costs']

#11. Find wtd avg bw/student in AK
change.cost.not.ak <- (one_mbps[one_mbps$postal_cd_ak == F, 'total_cost'] - extrap.ia.not.ak) /
                        extrap.ia.not.ak
change.bw.not.ak <- ((one_mbps[one_mbps$postal_cd_ak == F, 'wtd_avg_bw_student_no_concurrency'] - 
                      wtd_avg_bw[wtd_avg_bw$postal_cd_ak == F, 'wtd_avg'])) / wtd_avg_bw[wtd_avg_bw$postal_cd_ak == F, 'wtd_avg']


#12. Find change in BW in AK (7, 10)
change.bw.ak <- ((one_mbps[one_mbps$postal_cd_ak == T, 'wtd_avg_bw_student_no_concurrency'] - 
                        wtd_avg_bw[wtd_avg_bw$postal_cd_ak == T, 'wtd_avg'])) / wtd_avg_bw[wtd_avg_bw$postal_cd_ak == T, 'wtd_avg']

#13. Find 1 Mbps cost in AK (4, 11, 12)
change.cost.ak <- (change.cost.not.ak / change.bw.not.ak) * change.bw.ak
one_mbps.ak <- change.cost.ak * extrap.ia.ak + extrap.ia.ak

one_mbps[one_mbps$postal_cd_ak == T,'total_cost'] <- one_mbps.ak
one_mbps

extrap.ia.cost <- extrap.ia.not.ak + extrap.ia.ak
one_mbps_ia_cost <- sum(one_mbps$total_cost)
wan_cost <- wan$total_cost

one_mbps_ia_wan <- one_mbps_ia_cost + wan_cost

#Methodology 
#0. Find % clean SR $ that are IA in AK
#1. Find % clean SR $ that are IA not in AK
#2. Find total $ in SR
#3. Find total $ in SR in AK
#4. Find extrap $ IA in AK (0 * 3)
#5. Find total $ in SR not in AK (2 - 3)
#6. Find extrap $ IA not in AK (5 * 1)
#7. Find wtd avg bw/student in AK in 0
#8. Find wtd avg bw/student not in AK in 1
#9. Find 1 Mbps cost, bw/student not in AK
#10. Find 1 Mbps bw/student in AK
#11. Find change in cost, change in BW not in AK (6,8,9)
#12. Find change in BW in AK (7, 10)
#13. Find 1 Mbps cost in AK (4, 11, 12)
#14. Find WAN for everyone
