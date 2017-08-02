## Number of More Districts Connected between 2016 and 2017 (Extrapolated)
## Old (New) Methodology: If a state has the following:
##              A) State % clean is less than 70%.
##              B) State has dirty Mega's in 2017 that were clean in 2016. -- this is relaxed to all states
##              C) Total Students meeting is less than zero.
## Then apply the following methodology:
##    For the districts that are dirty in 2017 but were clean AND meeting goals in 2016, bring over the total BW and use it to calculate BW goals.
## Step #1: define the states that qualify for the revised methodology.
#state_2017$percent_clean <- round(state_2017$districts_clean_ia_sample / state_2017$districts_population, 2)
## (~21 states)
#states_to_adjust <- state_2017$postal_cd[which(state_2017$percent_clean < .70 | state_2017$megas_dirty_2017_clean_2016 > 0 & state_2017$postal_cd != 'ALL')]
#states_to_adjust <- state_2017$postal_cd[which(state_2017$percent_clean < .70 | state_2017$postal_cd %in% c('TN', 'MS', 'NV', 'NY', 'MD')
#                                               & state_2017$postal_cd != "ALL")]
## Step #2: for the states selected, narrow down to the districts that are dirty in 2017 but clean and meeting goals in 2016
## create 2016 subset (clean and meeting BW goals)
#dd_2016_sub <- dd_2016[which(dd_2016$exclude_from_ia_analysis == FALSE & dd_2016$meeting_2014_goal_no_oversub == TRUE & dd_2016$postal_cd %in% states_to_adjust),]
#districts_to_adjust <- dd_2017$esh_id[which(dd_2017$postal_cd %in% states_to_adjust & dd_2017$exclude_from_ia_analysis == TRUE)]
## subset to the districts we care about (~1,300 districts)
#dd_2016_sub <- dd_2016_sub[which(dd_2016_sub$esh_id %in% districts_to_adjust),]
#names(dd_2016_sub)[names(dd_2016_sub) == "ia_bw_mbps_total"] <- "ia_bw_mbps_total_2016"
## bring over the 2016 total bw for these districts
#dd_2017 <- merge(dd_2017, dd_2016_sub[,c('esh_id', 'ia_bw_mbps_total_2016')], by='esh_id', all.x=T)
## recalculate whether the district is now meeting goals (100 kbps/student)
#dd_2017$ia_bw_mbps_total_2016 <- dd_2017$ia_bw_mbps_total_2016 * 1000
#dd_2017$ia_bw_mbps_total_2016 <- dd_2017$ia_bw_mbps_total_2016 / dd_2017$num_students
#dd_2017$new_connectivity_metric <- ifelse(dd_2017$ia_bw_mbps_total_2016 >= 100, TRUE, FALSE)
## adjust the clealiness indicator
#dd_2017$exclude <- ifelse(is.na(dd_2017$new_connectivity_metric), dd_2017$exclude_from_ia_analysis, FALSE)
#dd_2017$clean <- ifelse(dd_2017$exclude == FALSE, 1, 0)
#dd_2017$new_connectivity_metric <- ifelse(is.na(dd_2017$new_connectivity_metric), dd_2017$meeting_2014_goal_no_oversub, dd_2017$new_connectivity_metric)
#dd_2017$new_connectivity_metric <- ifelse(dd_2017$new_connectivity_metric == TRUE, 1, 0)
## for each state, aggregate the new connectivity metric (districts)
#state_agg <- aggregate(dd_2017$new_connectivity_metric * dd_2017$clean, by=list(dd_2017$postal_cd), FUN=sum, na.rm=T)
#names(state_agg) <- c('postal_cd', 'adjusted_meeting_bw_goals')
#state_2017 <- merge(state_2017, state_agg, by='postal_cd', all.x=T)
## for each state, aggregate the new clean sample (districts)
#state_agg <- aggregate(dd_2017$clean, by=list(dd_2017$postal_cd), FUN=sum, na.rm=T)
#names(state_agg) <- c('postal_cd', 'adjusted_districts_clean')
#state_2017 <- merge(state_2017, state_agg, by='postal_cd', all.x=T)
## for each state, aggregate the new connectivity metric (students)
#state_agg <- aggregate(dd_2017$new_connectivity_metric * dd_2017$clean * dd_2017$num_students, by=list(dd_2017$postal_cd), FUN=sum, na.rm=T)
#names(state_agg) <- c('postal_cd', 'adjusted_meeting_bw_goals_students')
#state_2017 <- merge(state_2017, state_agg, by='postal_cd', all.x=T)
## for each state, aggregate the new clean sample (students)
#state_agg <- aggregate(dd_2017$clean * dd_2017$num_students, by=list(dd_2017$postal_cd), FUN=sum, na.rm=T)
#names(state_agg) <- c('postal_cd', 'adjusted_students_clean')
#state_2017 <- merge(state_2017, state_agg, by='postal_cd', all.x=T)
## Step #3: calculate the extrapolation
## districts
#state_2017$districts_meeting_2014_bw_goal_2017_extrap_new_meth <- round((state_2017$adjusted_meeting_bw_goals / state_2017$adjusted_districts_clean)
#                                                                          * state_2017$districts_population, 0)
## students
#state_2017$students_meeting_2014_bw_goal_2017_extrap_new_meth <- round((state_2017$adjusted_meeting_bw_goals_students / state_2017$adjusted_students_clean)
#                                                                        * state_2017$students_population, 0)