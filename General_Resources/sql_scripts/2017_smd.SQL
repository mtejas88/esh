SELECT dd_2017.postal_cd,


/* POPULATIONS */
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' THEN 1 ELSE 0 END) as districts_population,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_population,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' THEN dd_2017.num_students ELSE 0 END) as students_population,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' THEN dd_2017.num_campuses ELSE 0 END) as campuses_population,


/* SAMPLES */
-- IA
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_wan_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_cost_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2016.include_in_universe_of_districts = 't' AND dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2017.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- WIFI
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND (dd_2017.needs_wifi = 't' OR dd_2017.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,


/* UPGRADES */
-- Upgraded
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' THEN dd_2017.num_students ELSE 0 END) as students_upgraded,
-- Upgraded and Now Meeting Goals
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN 1 ELSE 0 END) as districts_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_upgraded_meeting_goals,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.upgrade_indicator = 't' AND dd_2017.meeting_2014_goal_no_oversub = 't' AND dd_2016.meeting_2014_goal_no_oversub = 'f' THEN dd_2017.num_students ELSE 0 END) as students_upgraded_meeting_goals,

/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2014_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_2018_goal_no_oversub = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,


/* AFFORDABILITY */
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.meeting_knapsack_affordability_target = 't' THEN dd_2017.num_students ELSE 0 END) as students_meeting_affordability,

-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_monthly_cost_total::numeric ELSE 0 END), 0) as ia_monthly_cost_total,

-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' THEN dd_2017.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 0) as median_ia_monthly_cost_per_mbps,


/* FIBER */
-- group A: dirty for both ia analysis and fiber analysis
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 't' AND dd_2017.exclude_from_current_fiber_analysis = 't' THEN dd_2017.current_known_scalable_campuses ELSE 0 END) as current_known_scalable_campuses_group_A,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 't' AND dd_2017.exclude_from_current_fiber_analysis = 't' THEN dd_2017.current_assumed_scalable_campuses ELSE 0 END) as current_assumed_scalable_campuses_group_A,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 't' AND dd_2017.exclude_from_current_fiber_analysis = 't' THEN dd_2017.num_campuses ELSE 0 END) as total_num_campuses_group_A,
-- group B: dirty for ia analysis and clean for fiber analysis
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 't' AND dd_2017.exclude_from_current_fiber_analysis = 'f' THEN dd_2017.current_known_scalable_campuses ELSE 0 END) as current_known_scalable_campuses_group_B,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 't' AND dd_2017.exclude_from_current_fiber_analysis = 'f' THEN dd_2017.current_assumed_scalable_campuses ELSE 0 END) as current_assumed_scalable_campuses_group_B,
-- group C: clean for both ia analysis and fiber analysis
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.exclude_from_current_fiber_analysis = 'f' THEN dd_2017.current_known_scalable_campuses ELSE 0 END) as current_known_scalable_campuses_group_C,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.exclude_from_current_fiber_analysis = 'f' THEN dd_2017.current_assumed_scalable_campuses ELSE 0 END) as current_assumed_scalable_campuses_group_C,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.exclude_from_current_fiber_analysis = 'f' THEN dd_2017.num_campuses ELSE 0 END) as total_num_campuses_group_C,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.fiber_target_status = 'Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.fiber_target_status = 'Potential Target' THEN dd_2017.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.exclude_from_ia_analysis = 'f' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,

/* WIFI */
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.needs_wifi = 'f' THEN dd_2017.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2017.include_in_universe_of_districts = 't' AND dd_2017.needs_wifi = 'f' THEN dd_2017.num_students ELSE 0 END) as students_with_wifi


FROM public.fy2017_districts_deluxe_matr as dd_2017
left join public.fy2016_districts_deluxe_matr as dd_2016 on dd_2016.esh_id = dd_2017.esh_id

-- take out non-US states at the end (GU, PR, VI)
-- also take out states at the school-level (RI, HI, DE)
WHERE dd_2017.postal_cd NOT IN ('GU', 'PR', 'VI', 'RI', 'HI', 'DE')

GROUP BY dd_2017.postal_cd
ORDER BY dd_2017.postal_cd

/* how to create a row at the end that represents the sum of all? National */


