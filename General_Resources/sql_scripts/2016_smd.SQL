SELECT dd_2016.postal_cd,

--State Aggregation
----------------------

/* POPULATIONS */
count(dd_2016.esh_id) as districts_population,
sum(dd_2016.num_schools) as schools_population,
sum(dd_2016.num_students) as students_population,
sum(dd_2016.num_campuses) as campuses_population,

/* SAMPLES */
-- IA
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- WIFI
sum(CASE WHEN (dd_2016.needs_wifi = 't' OR dd_2016.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,


/* UPGRADES */
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN dd_2016.num_students ELSE 0 END) as students_upgraded,


/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2016.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2016.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,


/* AFFORDABILITY */
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_affordability,

-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,

-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,


/* FIBER */
-- Total Scalable Campuses
sum(dd_2016.current_known_scalable_campuses + dd_2016.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(dd_2016.current_known_unscalable_campuses + dd_2016.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN dd_2016.current_known_unscalable_campuses + dd_2016.current_assumed_unscalable_campuses ELSE 0 END)::numeric, 0) as mean_unscalable_campuses_targets,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Target' THEN dd_2016.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Potential Target' THEN dd_2016.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN dd_2016.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Potential Target' THEN dd_2016.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,


/* WIFI */
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN dd_2016.num_students ELSE 0 END) as students_with_wifi


FROM public.fy2016_districts_deluxe_matr as dd_2016
left join public.fy2015_districts_deluxe_m as dd_2015 on dd_2015.esh_id::char = dd_2016.esh_id

-- take out non-US states at the end (AE, AP, AS, GU, MP, PR, VI, DC)
-- also take out states at the school-level (RI, HI, DE)
WHERE dd_2016.postal_cd NOT IN ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DC', 'RI', 'HI', 'DE')
AND dd_2016.district_type = 'Traditional'
AND dd_2016.include_in_universe_of_districts = 't'
GROUP BY dd_2016.postal_cd


UNION
--National Aggregation
----------------------
select 'ALL' as postal_cd,

/* POPULATIONS */
count(dd_2016.esh_id) as districts_population,
sum(dd_2016.num_schools) as schools_population,
sum(dd_2016.num_students) as students_population,
sum(dd_2016.num_campuses) as campuses_population,


/* SAMPLES */
-- IA
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_ia_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.num_campuses ELSE 0 END) as campuses_clean_ia_sample,
-- WAN
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_wan_sample,
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_wan_sample,
sum(CASE WHEN dd_2016.exclude_from_wan_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_wan_sample,
-- IA Cost
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_ia_cost_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_ia_cost_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_ia_cost_sample,
-- Upgrades
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN 1 ELSE 0 END) as districts_clean_upgrades_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_clean_upgrades_sample,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2015.exclude_from_analysis = 'f' THEN dd_2016.num_students ELSE 0 END) as students_clean_upgrades_sample,
-- WIFI
sum(CASE WHEN (dd_2016.needs_wifi = 't' OR dd_2016.needs_wifi = 'f') THEN 1 ELSE 0 END) as districts_wifi_sample,


/* UPGRADES */
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN 1 ELSE 0 END) as districts_upgraded,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_upgraded,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.upgrade_indicator = 't' THEN dd_2016.num_students ELSE 0 END) as students_upgraded,


/* CONNECTIVITY */
-- Meeting 2014 Goals
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2014_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_2014_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2014_goal_no_oversub = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_2014_bw_goal,
-- Meeting 2018 Goals
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN 1 ELSE 0 END) as districts_meeting_2018_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_2018_bw_goal,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.meeting_2018_goal_no_oversub = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_2018_bw_goal,
-- Total IA BW (kbps)
round(sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' THEN dd_2016.ia_bw_mbps_total::numeric ELSE 0 END), 0) as ia_bw_mbps_total,
-- BW Targets
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.bw_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_bw_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_bw_potential_targets,
sum(CASE WHEN dd_2016.bw_target_status = 'Target' THEN 1 ELSE 0 END) as district_bw_targets,
sum(CASE WHEN dd_2016.bw_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_bw_potential_targets,


/* AFFORDABILITY */
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN 1 ELSE 0 END) as districts_meeting_affordability,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN dd_2016.num_schools ELSE 0 END) as schools_meeting_affordability,
sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' AND dd_2016.meeting_knapsack_affordability_target = 't' THEN dd_2016.num_students ELSE 0 END) as students_meeting_affordability,

-- Total IA Monthly Cost
round(sum(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.ia_monthly_cost_total::numeric ELSE 0 END), 2) as ia_monthly_cost_total,

-- Median IA Monthly Cost per Mbps
round(median(CASE WHEN dd_2016.exclude_from_ia_cost_analysis = 'f' THEN dd_2016.ia_monthly_cost_per_mbps ELSE NULL END)::numeric, 2) as median_ia_monthly_cost_per_mbps,


/* FIBER */
-- Total Scalable Campuses
sum(dd_2016.current_known_scalable_campuses + dd_2016.current_assumed_scalable_campuses) as scalable_campuses,
-- Total Unscalable Campuses
sum(dd_2016.current_known_unscalable_campuses + dd_2016.current_assumed_unscalable_campuses) as unscalable_campuses,
-- Average Number of Unscalable Campuses
round(avg(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN dd_2016.current_known_unscalable_campuses + dd_2016.current_assumed_unscalable_campuses ELSE 0 END)::numeric, 0) as mean_unscalable_campuses_targets,
-- Fiber Targets - Campuses
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Target' THEN dd_2016.num_campuses ELSE 0 END) as clean_campus_fiber_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Potential Target' THEN dd_2016.num_campuses ELSE 0 END) as clean_campus_fiber_potential_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN dd_2016.num_campuses ELSE 0 END) as campus_fiber_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Potential Target' THEN dd_2016.num_campuses ELSE 0 END) as campus_fiber_potential_targets,
-- Fiber Targets - Districts
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as clean_district_fiber_targets,
sum(CASE WHEN dd_2016.exclude_from_ia_analysis = 'f' AND dd_2016.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as clean_district_fiber_potential_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Target' THEN 1 ELSE 0 END) as district_fiber_targets,
sum(CASE WHEN dd_2016.fiber_target_status = 'Potential Target' THEN 1 ELSE 0 END) as district_fiber_potential_targets,


/* WIFI */
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN 1 ELSE 0 END) as districts_with_wifi,
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN dd_2016.num_schools ELSE 0 END) as schools_with_wifi,
sum(CASE WHEN dd_2016.needs_wifi = 'f' THEN dd_2016.num_students ELSE 0 END) as students_with_wifi


FROM public.fy2016_districts_deluxe_matr as dd_2016
left join public.fy2015_districts_deluxe_m as dd_2015 on dd_2015.esh_id::char = dd_2016.esh_id
-- take out non-US states at the end (AE, AP, AS, GU, MP, PR, VI, DC)
WHERE dd_2016.postal_cd NOT IN ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DC')
AND dd_2016.district_type = 'Traditional'
AND dd_2016.include_in_universe_of_districts = 't'
GROUP BY 1
ORDER BY postal_cd

/* This query generates the state-level and National aggregation of most of the metrics for the State Metric Dashboard for 2016. */

