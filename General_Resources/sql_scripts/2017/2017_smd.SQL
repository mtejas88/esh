SELECT dd_2017.postal_cd,

-------------------------------------
--State Aggregation
-------------------------------------

/* POPULATIONS */
count(dd_2017.esh_id) as districts_population,
sum(dd_2017.num_schools) as schools_population,
sum(dd_2017.num_students) as students_population,
sum(dd_2017.num_campuses) as campuses_population,
sum(CASE WHEN dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large' THEN 1 ELSE 0 END) as mega_large_population,


/* SAMPLES */
-- IA
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- Upgrades (Not Meeting 2016) 
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_2016_not_meeting_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_2016_not_meeting_sample,
-- WIFI
sum(CASE WHEN (dd_2017.needs_wifi = 't' OR dd_2017.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,
--Mega Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2017.district_size = 'Mega' THEN 1 ELSE 0 END) as megas_dirty_2017_clean_2016,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND (dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large') THEN 1 ELSE 0 END) as mega_large_clean_ia_sample,

/* UPGRADES */
-- Upgraded
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_students ELSE 0 END) as students_upgraded,
-- Upgraded and Now Meeting Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_upgraded_meeting_goals,

/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,

/* AFFORDABILITY */
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_affordability,
-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,
-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,

/* FIBER */
-- Total Scalable Campuses
sum(dd_2017.current_known_scalable_campuses + dd_2017.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Total Unscalable Campuses (Rural and Small Town)
sum(CASE WHEN dd_2017.locale = 'Rural' OR dd_2017.locale = 'Town' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE 0 END) as unscalable_campuses_rural_small_town,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE NULL END)::numeric, 0) as mean_unscalable_campuses_targets,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,

/* WIFI */
-- Needs Wifi
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_students ELSE 0 END) as students_with_wifi,
-- Postdiscount C2 Funding (Across Years: 2015, 2016, 2017) (changed from Prediscount)
sum(dd_2017.c2_prediscount_budget_15) as c2_budget_2015,
sum(dd_2017.c2_postdiscount_remaining_15) as c2_remaining_2015,
sum(dd_2017.c2_postdiscount_remaining_16) as c2_remaining_2016,
sum(dd_2017.c2_postdiscount_remaining_17) as c2_remaining_2017,
-- Number of Districts that haven't used C2 funds
sum(CASE WHEN dd_2017.c2_prediscount_remaining_17 > 0 THEN 1 ELSE 0 END) as num_districts_c2_remaining

FROM public.fy2017_districts_deluxe_matr as dd_2017
left join public.fy2016_districts_deluxe_matr as dd_2016 on dd_2016.esh_id = dd_2017.esh_id
-- take out non-US states at the end (GU, PR, VI, DC)
-- also take out states at the school-level (RI, HI, DE)
-- also take out OR so can regenerate with charters
WHERE dd_2017.postal_cd NOT IN ('GU', 'PR', 'VI', 'DC', 'AE', 'AP', 'AS', 'MP', 'RI', 'HI', 'DE', 'OR')
AND dd_2017.district_type = 'Traditional'
AND dd_2017.include_in_universe_of_districts = 't'
GROUP BY dd_2017.postal_cd

UNION

-------------------------------------
--State Aggregation (Just Oregon)
-------------------------------------

/* POPULATIONS */
SELECT dd_2017.postal_cd, 
count(dd_2017.esh_id) as districts_population,
sum(dd_2017.num_schools) as schools_population,
sum(dd_2017.num_students) as students_population,
sum(dd_2017.num_campuses) as campuses_population,
sum(CASE WHEN dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large' THEN 1 ELSE 0 END) as mega_large_population,


/* SAMPLES */
-- IA
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- Upgrades (Not Meeting 2016) 
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_2016_not_meeting_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_2016_not_meeting_sample,
-- WIFI
sum(CASE WHEN (dd_2017.needs_wifi = 't' OR dd_2017.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,
--Mega Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2017.district_size = 'Mega' THEN 1 ELSE 0 END) as megas_dirty_2017_clean_2016,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND (dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large') THEN 1 ELSE 0 END) as mega_large_clean_ia_sample,

/* UPGRADES */
-- Upgraded
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_students ELSE 0 END) as students_upgraded,
-- Upgraded and Now Meeting Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_upgraded_meeting_goals,

/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,

/* AFFORDABILITY */
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_affordability,
-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,
-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,

/* FIBER */
-- Total Scalable Campuses
sum(dd_2017.current_known_scalable_campuses + dd_2017.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Total Unscalable Campuses (Rural and Small Town)
sum(CASE WHEN dd_2017.locale = 'Rural' OR dd_2017.locale = 'Town' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE 0 END) as unscalable_campuses_rural_small_town,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE NULL END)::numeric, 0) as mean_unscalable_campuses_targets,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,

/* WIFI */
-- Needs Wifi
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_students ELSE 0 END) as students_with_wifi,
-- Postdiscount C2 Funding (Across Years: 2015, 2016, 2017) (changed from Prediscount)
sum(dd_2017.c2_prediscount_budget_15) as c2_budget_2015,
sum(dd_2017.c2_postdiscount_remaining_15) as c2_remaining_2015,
sum(dd_2017.c2_postdiscount_remaining_16) as c2_remaining_2016,
sum(dd_2017.c2_postdiscount_remaining_17) as c2_remaining_2017,
-- Number of Districts that haven't used C2 funds
sum(CASE WHEN dd_2017.c2_prediscount_remaining_17 > 0 THEN 1 ELSE 0 END) as num_districts_c2_remaining

FROM public.fy2017_districts_deluxe_matr as dd_2017
left join public.fy2016_districts_deluxe_matr as dd_2016 on dd_2016.esh_id = dd_2017.esh_id
-- only generate OR so can add in charters
WHERE dd_2017.postal_cd = 'OR'
AND dd_2017.district_type IN ('Traditional', 'Charter')
GROUP BY dd_2017.postal_cd

UNION

-------------------------------------
-- Schools states (DE,RI,HI)
-------------------------------------
SELECT sd17.postal_cd, 

/* POPULATIONS */
COUNT(sd17.campus_id) AS districts_population,
sum(sd17.num_schools) AS schools_population,
SUM(sd17.num_students) AS students_population,
COUNT(sd17.campus_id) AS campuses_population,
NULL AS mega_large_population,
/* SAMPLES */
-- IA
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' THEN sd17.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' THEN sd17.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' THEN sd17.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
NULL as districts_clean_wan_sample,
NULL as schools_clean_wan_sample,
NULL as students_clean_wan_sample,
-- IA cost
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN sd17.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN sd17.num_students ELSE 0 END) as students_clean_ia_cost_sample,
--Upgrades
NULL as districts_clean_upgrades_sample,
NULL as schools_clean_upgrades_sample,
NULL as students_clean_upgrades_sample,
-- *Upgrades (Not Meeting 2016)*
NULL as districts_clean_upgrades_2016_not_meeting_sample,
NULL as students_clean_upgrades_2016_not_meeting_sample,
-- WIFI
sum(CASE WHEN (dd_2017.needs_wifi = 't' OR dd_2017.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,
--Mega Districts
NULL as megas_dirty_2017_clean_2016,
NULL
as mega_large_clean_ia_sample,
/* UPGRADES */
-- Upgraded
NULL as districts_upgraded,
NULL as schools_upgraded,
NULL as students_upgraded,
-- Upgraded and Now Meeting Goals
NULL as districts_upgraded_meeting_goals,
NULL as schools_upgraded_meeting_goals,
NULL as students_upgraded_meeting_goals,

/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.meeting_2014_goal_no_oversub = 't' THEN sd17.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.meeting_2014_goal_no_oversub = 't' THEN sd17.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.ia_bandwidth_per_student_kbps >= 1000 THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.ia_bandwidth_per_student_kbps >= 1000 THEN sd17.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND sd17.ia_bandwidth_per_student_kbps >= 1000 THEN sd17.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' THEN sd17.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,

/* AFFORDABILITY */
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND sd17.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND sd17.meeting_knapsack_affordability_target = 't' THEN sd17.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND sd17.meeting_knapsack_affordability_target = 't' THEN sd17.num_students ELSE 0 END) as students_meeting_affordability,
-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN sd17.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,
-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN sd17.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,

 /* FIBER */
-- Total Scalable Campuses
sum(sd17.current_known_scalable_campuses + sd17.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(sd17.current_known_unscalable_campuses + sd17.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Total Unscalable Campuses (Rural and Small Town)
sum(CASE WHEN dd_2017.locale = 'Rural' OR dd_2017.locale = 'Town' THEN sd17.current_known_unscalable_campuses + sd17.current_assumed_unscalable_campuses ELSE 0 END) as unscalable_campuses_rural_small_town,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN sd17.current_known_unscalable_campuses + sd17.current_assumed_unscalable_campuses ELSE NULL END)::numeric, 0) as mean_unscalable_campuses_targets,
 -- Fiber Targets - Campuses
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN sd17.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN sd17.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN sd17.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN sd17.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN sd17.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,

/* WIFI */
-- Needs Wifi
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN sd17.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN sd17.num_students ELSE 0 END) as students_with_wifi,
-- Postdiscount C2 Funding (Across Years: 2015, 2016, 2017) (changed from Prediscount)
sum(dd_2017.c2_prediscount_budget_15) as c2_budget_2015,
sum(dd_2017.c2_postdiscount_remaining_15) as c2_remaining_2015,
sum(dd_2017.c2_postdiscount_remaining_16) as c2_remaining_2016,
sum(dd_2017.c2_postdiscount_remaining_17) as c2_remaining_2017,
-- Number of Districts that haven't used C2 funds
sum(CASE WHEN dd_2017.c2_prediscount_remaining_17 > 0 THEN 1 ELSE 0 END) as num_districts_c2_remaining
    
FROM public.fy2017_schools_deluxe_matr sd17

LEFT JOIN public.fy2017_districts_deluxe_matr dd_2017
ON sd17.district_esh_id = dd_2017.esh_id

LEFT JOIN public.districts_schools ds
ON sd17.campus_id = ds.campus_id

/*LEFT JOIN public.fy2016_schools_deluxe_matr
ON*/

GROUP BY sd17.postal_cd

UNION

-------------------------------------
--National Aggregation
-------------------------------------
select 'ALL' as postal_cd,

/* POPULATIONS */
count(dd_2017.esh_id) as districts_population,
sum(dd_2017.num_schools) as schools_population,
sum(dd_2017.num_students) as students_population,
sum(dd_2017.num_campuses) as campuses_population,
sum(CASE WHEN dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large' THEN 1 ELSE 0 END) as mega_large_population,


/* SAMPLES */
-- IA
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- Upgrades (Not Meeting 2016) 
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_2016_not_meeting_sample,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_2016_not_meeting_sample,
-- WIFI
sum(CASE WHEN (dd_2017.needs_wifi = 't' OR dd_2017.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,
--Mega Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 't' AND dd_2016.exclude_from_ia_analysis = 'f' AND dd_2017.district_size = 'Mega' THEN 1 ELSE 0 END) as megas_dirty_2017_clean_2016,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND (dd_2017.district_size = 'Mega' OR dd_2017.district_size = 'Large') THEN 1 ELSE 0 END) as mega_large_clean_ia_sample,


/* UPGRADES */
-- Upgraded
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_students ELSE 0 END) as students_upgraded,
-- Upgraded and Now Meeting Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_upgraded_meeting_goals,

/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,

/* AFFORDABILITY */
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_affordability,
-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.postal_cd != 'AK' THEN dd_2017.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,
-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2017.exclude_from_ia_cost_analysis = 'f' AND dd_2017.postal_cd != 'AK' THEN dd_2017.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,

/* FIBER */
-- Total Scalable Campuses
sum(dd_2017.current_known_scalable_campuses + dd_2017.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Total Unscalable Campuses (Rural and Small Town)
sum(CASE WHEN dd_2017.locale = 'Rural' OR dd_2017.locale = 'Town' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE 0 END) as unscalable_campuses_rural_small_town,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.current_known_unscalable_campuses + dd_2017.current_assumed_unscalable_campuses ELSE NULL END)::numeric, 0) as mean_unscalable_campuses_targets,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,

/* WIFI */
-- Needs Wifi
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2017.needs_wifi = 'f' THEN dd_2017.num_students ELSE 0 END) as students_with_wifi,
-- Postdiscount C2 Funding (Across Years: 2015, 2016, 2017) (changed from Prediscount)
sum(dd_2017.c2_prediscount_budget_15) as c2_budget_2015,
sum(dd_2017.c2_postdiscount_remaining_15) as c2_remaining_2015,
sum(dd_2017.c2_postdiscount_remaining_16) as c2_remaining_2016,
sum(dd_2017.c2_postdiscount_remaining_17) as c2_remaining_2017,
-- Number of Districts that haven't used C2 funds
sum(CASE WHEN dd_2017.c2_prediscount_remaining_17 > 0 THEN 1 ELSE 0 END) as num_districts_c2_remaining

FROM public.fy2017_districts_deluxe_matr as dd_2017
left join public.fy2016_districts_deluxe_matr as dd_2016 on dd_2016.esh_id = dd_2017.esh_id
-- take out non-US states at the end (AE, AP, AS, GU, MP, PR, VI)
WHERE dd_2017.postal_cd NOT IN ('GU', 'PR', 'VI', 'AE', 'AP', 'AS', 'MP')
AND dd_2017.district_type = 'Traditional'
AND dd_2017.include_in_universe_of_districts = 't'
GROUP BY 1

ORDER BY postal_cd

/* This query generates the state-level and National aggregation of most of the metrics for the State Metric Dashboard for 2017. */


