## =========================================================================
##
## REFRESH STATE METRICS:
## UPGRADES
##
## 2015 SAMPLE: exclude_from_analysis == FALSE
## 2016 SAMPLE: exclude_from_ia_analysis == FALSE
##
## =========================================================================

upgrades <- function(dd.2015, ds.2015, dd.2016, ds.2016, dta, states.with.schools){
  
  ## overlap to districts that are clean in both years
  dd.2015.clean <- dd.2015[dd.2015$exclude_from_analysis == FALSE,]
  dd.2016.clean <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]
  overlapping.districts <- dd.2015.clean$esh_id[dd.2015.clean$esh_id %in% dd.2016.clean$esh_id]
  dd.2015.clean <- dd.2015.clean[dd.2015.clean$esh_id %in% overlapping.districts,]
  dd.2016.clean <- dd.2016.clean[dd.2016.clean$esh_id %in% overlapping.districts,]
  ## take out states.with.schools for upgrades
  dd.2015.clean <- dd.2015.clean[!dd.2015.clean$postal_cd %in% states.with.schools,]
  dd.2016.clean <- dd.2016.clean[!dd.2016.clean$postal_cd %in% states.with.schools,]
  
  ## merge the two datasets we're comparing
  ## just looking at IA now
  dd.clean.compare <- merge(dd.2015.clean[,c('esh_id', 'name', 'postal_cd', 'locale', 'district_size', 'num_schools',
                                             'num_campuses', 'num_students', 'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps',
                                             'ia_monthly_cost_total', 'bundled_and_dedicated_isp_sp', 'num_internet_upstream_lines', 'most_recent_ia_contract_end_date')],
                            dd.2016.clean[,c('esh_id', 'num_schools', 'num_campuses', 'num_students',
                                             'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps', 'ia_monthly_cost_total', 
                                             'non_fiber_internet_upstream_lines_w_dirty', 'fiber_internet_upstream_lines_w_dirty',
                                             'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date', 'num_internet_upstream_lines')], by='esh_id', all=T)
  names(dd.clean.compare) <- c('esh_id', 'district_name', 'postal_cd', 'locale', 'district_size', 'num_schools_2015', 'num_campuses_2015',
                              'num_students_2015', 'total_ia_bw_2015', 'ia_bandwidth_per_student_kbps_2015', 'total_ia_cost_2015',
                              'bundled_and_dedicated_isp_service_provider_2015', 'num_internet_upstream_lines_2015', 'most_recent_ia_contract_expiration_date_2015',
                              'num_schools_2016', 'num_campuses_2016', 'num_students_2016', 'total_ia_bw_2016', 'ia_bandwidth_per_student_kbps_2016',
                              'total_ia_cost_2016', 'non_fiber_ia_lines_2016', 'fiber_ia_lines_2016',
                              'bundled_and_dedicated_isp_service_provider_2016', 'most_recent_ia_contract_expiration_date_2016', 'num_internet_upstream_lines_2016')
  ## order by state
  dd.clean.compare <- dd.clean.compare[order(dd.clean.compare$postal_cd),]
  ## round BW
  dd.clean.compare$total_ia_bw_2015 <- round(dd.clean.compare$total_ia_bw_2015, 0)
  dd.clean.compare$total_ia_bw_2016 <- round(dd.clean.compare$total_ia_bw_2016, 0)
  dd.clean.compare$ia_bandwidth_per_student_kbps_2015 <- round(dd.clean.compare$ia_bandwidth_per_student_kbps_2015, 0)
  dd.clean.compare$ia_bandwidth_per_student_kbps_2016 <- round(dd.clean.compare$ia_bandwidth_per_student_kbps_2016, 0)
  ## calculate diffs for bandwidth and cost
  dd.clean.compare$diff.bw <- as.numeric(dd.clean.compare$total_ia_bw_2016) - as.numeric(dd.clean.compare$total_ia_bw_2015)
  ## calculate percentage change
  dd.clean.compare$perc.bw <- round((dd.clean.compare$diff.bw / as.numeric(dd.clean.compare$total_ia_bw_2015))*100, 0)
  dd.clean.compare$diff.cost <- as.numeric(dd.clean.compare$total_ia_cost_2016) - as.numeric(dd.clean.compare$total_ia_cost_2015)
  ## calculate percentage change
  dd.clean.compare$perc.cost <- round((dd.clean.compare$diff.cost / as.numeric(dd.clean.compare$total_ia_cost_2015))*100, 0)
  ## add in absolute values of differences
  dd.clean.compare$abs.diff.bw <- abs(dd.clean.compare$diff.bw)
  dd.clean.compare$abs.perc.bw <- abs(dd.clean.compare$perc.bw)
  ## subset to the relevant columns
  dd.clean.compare <- dd.clean.compare[,c('esh_id', 'postal_cd', 'district_name', 'locale', 'district_size', 'diff.bw', 'total_ia_bw_2015', 'total_ia_bw_2016',
                                          'bundled_and_dedicated_isp_service_provider_2015', 'bundled_and_dedicated_isp_service_provider_2016',
                                          'most_recent_ia_contract_expiration_date_2015', 'most_recent_ia_contract_expiration_date_2016',
                                          'num_schools_2015', 'num_schools_2016',
                                          'num_students_2015', 'num_students_2016',
                                          'ia_bandwidth_per_student_kbps_2015', 'ia_bandwidth_per_student_kbps_2016',
                                          'num_internet_upstream_lines_2015', 'num_internet_upstream_lines_2016',
                                          'abs.diff.bw', 'perc.bw', 'abs.perc.bw')]
  ## create a marker for when the percent difference != 0
  dd.clean.compare$diff.bw.per.student <- round(dd.clean.compare$ia_bandwidth_per_student_kbps_2016 - dd.clean.compare$ia_bandwidth_per_student_kbps_2015, 0)
  dd.clean.compare$no.change <- ifelse(dd.clean.compare$abs.perc.bw == 0, 1, 0)
  dd.clean.compare$round.diff <- round(dd.clean.compare$diff.bw, 0)
  dd.clean.compare$round.abs.diff <- round(dd.clean.compare$abs.diff.bw, 0)
  
  ## assign whether a change was an upgrade based on the following logic
  ## upgrade if:
  ## 1) the percentage change is 11% or greater
  ## 2) or if under 11%, if the actual change is in 50 mbps increments
  dd.clean.compare$upgrade <- ifelse(dd.clean.compare$perc.bw >= 11, 1,
                                             ifelse(dd.clean.compare$round.diff %% 50 == 0 & dd.clean.compare$round.diff > 0, 1, 0))
  
  ## aggregate upgrades by state
  upgrades <- aggregate(dd.clean.compare$upgrade, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(upgrades) <- c('postal_cd', 'num_upgrades_bw_increase')
  ## merge in dta
  dta <- merge(dta, upgrades, by='postal_cd', all.x=T)
  ## add national number
  dta$num_upgrades_bw_increase[dta$postal_cd == 'ALL'] <- sum(dta$num_upgrades_bw_increase, na.rm=T)
  
  ## aggregate overlapping districts
  dd.clean.compare$counter <- 1
  overlap <- aggregate(dd.clean.compare$counter, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(overlap) <- c('postal_cd', 'num_overlapping_districts')
  ## merge in dta
  dta <- merge(dta, overlap, by='postal_cd', all.x=T)
  ## add national number
  dta$num_overlapping_districts[dta$postal_cd == 'ALL'] <- sum(dta$num_overlapping_districts, na.rm=T)
  dd.clean.compare$counter <- NULL
  
  ## aggregate number of schools upgraded
  dd.clean.compare$counter.schools <- dd.clean.compare$upgrade * dd.clean.compare$num_schools_2016
  schools.upgraded <- aggregate(dd.clean.compare$counter.schools, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(schools.upgraded) <- c('postal_cd', 'num_schools_upgraded')
  ## merge in dta
  dta <- merge(dta, schools.upgraded, by='postal_cd', all.x=T)
  ## add national number
  dta$num_schools_upgraded[dta$postal_cd == 'ALL'] <- sum(dta$num_schools_upgraded, na.rm=T)
  dd.clean.compare$counter.schools <- NULL
  
  ## aggregate number of schools eligible
  dd.clean.compare$counter.schools <- dd.clean.compare$num_schools_2016
  schools.total <- aggregate(dd.clean.compare$counter.schools, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(schools.total) <- c('postal_cd', 'num_schools_eligible_upgrade')
  ## merge in dta
  dta <- merge(dta, schools.total, by='postal_cd', all.x=T)
  ## add national number
  dta$num_schools_eligible_upgrade[dta$postal_cd == 'ALL'] <- sum(dta$num_schools_eligible_upgrade, na.rm=T)
  dd.clean.compare$counter.schools <- NULL
  
  ## aggregate number of students upgraded
  dd.clean.compare$counter.students <- dd.clean.compare$upgrade * dd.clean.compare$num_students_2016
  students.upgraded <- aggregate(dd.clean.compare$counter.students, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(students.upgraded) <- c('postal_cd', 'num_students_upgraded')
  ## merge in dta
  dta <- merge(dta, students.upgraded, by='postal_cd', all.x=T)
  ## add national number
  dta$num_students_upgraded[dta$postal_cd == 'ALL'] <- sum(dta$num_students_upgraded, na.rm=T)
  dd.clean.compare$counter.students <- NULL
  
  ## aggregate number of students eligible
  dd.clean.compare$counter.students <- dd.clean.compare$num_students_2016
  students.total <- aggregate(dd.clean.compare$counter.students, by=list(dd.clean.compare$postal_cd), FUN=sum, na.rm=T)
  names(students.total) <- c('postal_cd', 'num_students_eligible_upgrade')
  ## merge in dta
  dta <- merge(dta, students.total, by='postal_cd', all.x=T)
  ## add national number
  dta$num_students_eligible_upgrade[dta$postal_cd == 'ALL'] <- sum(dta$num_students_eligible_upgrade, na.rm=T)
  dd.clean.compare$counter.students <- NULL
  
  ## change upgrade status and no change status to boolean
  dd.clean.compare$upgrade <- ifelse(dd.clean.compare$upgrade == 1, TRUE, FALSE)
  dd.clean.compare$no.change <- ifelse(dd.clean.compare$no.change == 1, TRUE, FALSE)
  ## also create a downgrade boolean
  dd.clean.compare$downgrade <- ifelse(dd.clean.compare$total_ia_bw_2015 > dd.clean.compare$total_ia_bw_2016 & dd.clean.compare$no.change == FALSE, TRUE, FALSE)
  ## sort dd.clean.compare by decreasing bw change
  dd.clean.compare <- dd.clean.compare[order(dd.clean.compare$diff.bw, decreasing=T),]
  
  
  ##================================================================================
  
  states.with.schools.dta <- data.frame(postal_cd=states.with.schools)
  
  ## just look at states with schools upgrades
  ds.2015.clean <- ds.2015[ds.2015$exclude_from_analysis == FALSE,]
  ds.2016.clean <- ds.2016[ds.2016$exclude_from_ia_analysis == FALSE,]
  
  ## merge the two datasets we're comparing
  ## just looking at IA now
  ds.2015.clean <- ds.2015.clean[,c('school_esh_ids', 'name', 'postal_cd', 'locale', 'district_size', 'num_schools',
                                    'num_campuses', 'num_students', 'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps',
                                    'ia_monthly_cost_total', 'bundled_and_dedicated_isp_sp', 'num_internet_upstream_lines', 'most_recent_ia_contract_end_date')]
  names(ds.2015.clean)[!names(ds.2015.clean) %in% c('esh_id', 'school_esh_ids', 'postal_cd')] <- paste(names(ds.2015.clean)[!names(ds.2015.clean) %in% c('esh_id', 'school_esh_ids', 'postal_cd')], "2015", sep='_')
  ds.2016.clean <- ds.2016.clean[,c('school_esh_ids', 'num_schools', 'num_campuses', 'num_students',
                   'ia_bw_mbps_total', 'ia_bandwidth_per_student_kbps', 'ia_monthly_cost_total', 
                   'non_fiber_internet_upstream_lines_w_dirty', 'fiber_internet_upstream_lines_w_dirty',
                   'bundled_and_dedicated_isp_sp', 'most_recent_ia_contract_end_date', 'num_internet_upstream_lines')]
  names(ds.2016.clean)[!names(ds.2016.clean) %in% c('school_esh_ids')] <- paste(names(ds.2016.clean)[!names(ds.2016.clean) %in% c('school_esh_ids')], "2016", sep='_')
  dd.clean.compare2 <- merge(ds.2015.clean, ds.2016.clean, by='school_esh_ids', all=T)
  
  ## order by state
  dd.clean.compare2 <- dd.clean.compare2[order(dd.clean.compare2$postal_cd),]
  ## round BW
  dd.clean.compare2$ia_bw_mbps_total_2015 <- round(dd.clean.compare2$ia_bw_mbps_total_2015, 0)
  dd.clean.compare2$ia_bw_mbps_total_2016 <- round(dd.clean.compare2$ia_bw_mbps_total_2016, 0)
  dd.clean.compare2$ia_bandwidth_per_student_kbps_2015 <- round(dd.clean.compare2$ia_bandwidth_per_student_kbps_2015, 0)
  dd.clean.compare2$ia_bandwidth_per_student_kbps_2016 <- round(dd.clean.compare2$ia_bandwidth_per_student_kbps_2016, 0)
  ## calculate diffs for bandwidth and cost
  dd.clean.compare2$diff.bw <- as.numeric(dd.clean.compare2$ia_bw_mbps_total_2016) - as.numeric(dd.clean.compare2$ia_bw_mbps_total_2015)
  ## calculate percentage change
  dd.clean.compare2$perc.bw <- round((dd.clean.compare2$diff.bw / as.numeric(dd.clean.compare2$ia_bw_mbps_total_2015))*100, 0)
  dd.clean.compare2$diff.cost <- as.numeric(dd.clean.compare2$ia_monthly_cost_total_2016) - as.numeric(dd.clean.compare2$ia_monthly_cost_total_2015)
  ## calculate percentage change
  dd.clean.compare2$perc.cost <- round((dd.clean.compare2$diff.cost / as.numeric(dd.clean.compare2$ia_monthly_cost_total_2015))*100, 0)
  ## add in absolute values of differences
  dd.clean.compare2$abs.diff.bw <- abs(dd.clean.compare2$diff.bw)
  dd.clean.compare2$abs.perc.bw <- abs(dd.clean.compare2$perc.bw)
  ## create a marker for when the percent difference != 0
  dd.clean.compare2$diff.bw.per.student <- round(dd.clean.compare2$ia_bandwidth_per_student_kbps_2016 - dd.clean.compare2$ia_bandwidth_per_student_kbps_2015, 0)
  dd.clean.compare2$no.change <- ifelse(dd.clean.compare2$abs.perc.bw == 0, 1, 0)
  dd.clean.compare2$round.diff <- round(dd.clean.compare2$diff.bw, 0)
  dd.clean.compare2$round.abs.diff <- round(dd.clean.compare2$abs.diff.bw, 0)
  
  ## assign whether a change was an upgrade based on the following logic
  ## upgrade if:
  ## 1) the percentage change is 11% or greater
  ## 2) or if under 11%, if the actual change is in 50 mbps increments
  dd.clean.compare2$upgrade <- ifelse(dd.clean.compare2$perc.bw >= 11, 1,
                                     ifelse(dd.clean.compare2$round.diff %% 50 == 0 & dd.clean.compare2$round.diff > 0, 1, 0))
  
  ## aggregate upgrades by state
  upgrades <- aggregate(dd.clean.compare2$upgrade, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(upgrades) <- c('postal_cd', 'num_upgrades_bw_increase')
  upgrades <- merge(upgrades, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  upgrades <- upgrades[order(upgrades$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_upgrades_bw_increase'] <-
    upgrades[upgrades$postal_cd %in% states.with.schools, 'num_upgrades_bw_increase']
  
  ## aggregate overlapping districts
  dd.clean.compare2$counter <- 1
  overlap <- aggregate(dd.clean.compare2$counter, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(overlap) <- c('postal_cd', 'num_overlapping_districts')
  overlap <- merge(overlap, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  overlap <- overlap[order(overlap$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_overlapping_districts'] <-
    overlap[overlap$postal_cd %in% states.with.schools, 'num_overlapping_districts']
  dd.clean.compare2$counter <- NULL
  
  ## aggregate number of schools upgraded
  dd.clean.compare2$counter.schools <- dd.clean.compare2$upgrade * dd.clean.compare2$num_schools_2016
  schools.upgraded <- aggregate(dd.clean.compare2$counter.schools, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(schools.upgraded) <- c('postal_cd', 'num_schools_upgraded')
  schools.upgraded <- merge(schools.upgraded, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  schools.upgraded <- schools.upgraded[order(schools.upgraded$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_schools_upgraded'] <-
    schools.upgraded[schools.upgraded$postal_cd %in% states.with.schools, 'num_schools_upgraded']
  dd.clean.compare2$counter.schools <- NULL
  
  ## aggregate number of schools eligible
  dd.clean.compare2$counter.schools <- dd.clean.compare2$num_schools_2016
  schools.total <- aggregate(dd.clean.compare2$counter.schools, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(schools.total) <- c('postal_cd', 'num_schools_eligible_upgrade')
  schools.total <- merge(schools.total, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  schools.total <- schools.total[order(schools.total$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_schools_eligible_upgrade'] <-
    schools.total[schools.total$postal_cd %in% states.with.schools, 'num_schools_eligible_upgrade']
  dd.clean.compare2$counter.schools <- NULL
  
  ## aggregate number of students upgraded
  dd.clean.compare2$counter.students <- dd.clean.compare2$upgrade * dd.clean.compare2$num_students_2016
  students.upgraded <- aggregate(dd.clean.compare2$counter.students, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(students.upgraded) <- c('postal_cd', 'num_students_upgraded')
  students.upgraded <- merge(students.upgraded, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  students.upgraded <- students.upgraded[order(students.upgraded$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_students_upgraded'] <-
    students.upgraded[students.upgraded$postal_cd %in% states.with.schools, 'num_students_upgraded']
  dd.clean.compare2$counter.students <- NULL
  
  ## aggregate number of students eligible
  dd.clean.compare2$counter.students <- dd.clean.compare2$num_students_2016
  students.total <- aggregate(dd.clean.compare2$counter.students, by=list(dd.clean.compare2$postal_cd), FUN=sum, na.rm=T)
  names(students.total) <- c('postal_cd', 'num_students_eligible_upgrade')
  students.total <- merge(students.total, states.with.schools.dta, all=T)
  ## merge in schools-level metrics for the states with schools
  ## order the datasets the same
  dta <- dta[order(dta$postal_cd),]
  students.total <- students.total[order(students.total$postal_cd),]
  dta[dta$postal_cd %in% states.with.schools, 'num_students_eligible_upgrade'] <-
    students.total[students.total$postal_cd %in% states.with.schools, 'num_students_eligible_upgrade']
  dd.clean.compare2$counter.students <- NULL
  
  ## change upgrade status and no change status to boolean
  dd.clean.compare2$upgrade <- ifelse(dd.clean.compare2$upgrade == 1, TRUE, FALSE)
  dd.clean.compare2$no.change <- ifelse(dd.clean.compare2$no.change == 1, TRUE, FALSE)
  ## also create a downgrade boolean
  dd.clean.compare2$downgrade <- ifelse(dd.clean.compare2$ia_bw_mbps_total_2015 > dd.clean.compare2$ia_bw_mbps_total_2016 & dd.clean.compare2$no.change == FALSE, TRUE, FALSE)
  ## sort dd.clean.compare2 by decreasing bw change
  dd.clean.compare2 <- dd.clean.compare2[order(dd.clean.compare2$diff.bw, decreasing=T),]
  

  assign("dta", dta, envir = .GlobalEnv) 
  assign("dd.clean.compare", dd.clean.compare, envir = .GlobalEnv)
  assign("dd.clean.compare.states.with.schools", dd.clean.compare2, envir = .GlobalEnv)
}
