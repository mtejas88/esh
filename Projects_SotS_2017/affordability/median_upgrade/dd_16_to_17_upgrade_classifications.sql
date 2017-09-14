/*
Author: Jamie Barnes
Created On Date: 8/17/2017
Last Modified Date: 
Name of QAing Analyst(s): HAS NOT BEEN QA-ED
Purpose: exploratory SotS analysis to look at affordabilty changes for districts for districts that upgraded in some fashion from 2016 to 2017
Methodology: limited to districts in our universe, clean for cost for both years
*/


select 
2017 as year,
dd.esh_id,
dd.name,
dd.postal_cd,
dd.num_students, 
dd.locale,
dd.district_size,

--metrics
dd.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps,

dd.ia_bw_mbps_total as ia_bw_mbps_total,

dd.ia_monthly_cost_total as ia_monthly_cost_total,

-- cohort type for filtering

/* limit to fiber upgrades */
case
  when dd.fiber_target_status = 'Not Target' and d.fiber_target_status = 'Target'
  then 'Fiber Upgrade in 2017'
  when dd.fiber_target_status = 'Target' and d.fiber_target_status = 'Target'
  then 'Still Fiber Target in 2017'
end as fiber_target_in_2016,

/* limit to connectivity_status change */
case
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then 'Newly Meeting Connectivity Goal in 2017'
  when dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false
  then 'Still Not Meeting in 2017'
end as connectivity_status,

/* limit to connectivity_status change with upgrade indicator */
case
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false and dd.upgrade_indicator = true
  then 'Newly Meeting Connectivity Goal in 2017'
  when dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false
  then 'Still Not Meeting in 2017'
end as connectivity_status_upgrade_limit,

/* limit to upgrades */
dd.upgrade_indicator as upgrade_2017,

/* limit to knapsack change */
case 
  when dd.meeting_knapsack_affordability_target = true and d.meeting_knapsack_affordability_target = false
  then 'Newly Meeting Knapsack in 2017'
  when dd.meeting_knapsack_affordability_target = false and d.meeting_knapsack_affordability_target = false
  then 'Still Not Meeting Knapsack'
end as knapsack_status

from public.fy2017_districts_deluxe_matr dd
inner join public.fy2016_districts_deluxe_matr d
on d.esh_id = dd.esh_id

where 
-- 2017
dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_analysis = false 
and dd.exclude_from_ia_cost_analysis = false

-- 2016
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'
and d.exclude_from_ia_analysis = false 
and d.exclude_from_ia_cost_analysis = false

union

select
2016 as year,
dd.esh_id,
dd.name,
dd.postal_cd,
dd.num_students, 
dd.locale,
dd.district_size,

--metrics
d.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps,

d.ia_bw_mbps_total as ia_bw_mbps_total,

d.ia_monthly_cost_total as ia_monthly_cost_total,

-- cohort type for filtering

/* limit to fiber upgrades */
case
  when dd.fiber_target_status = 'Not Target' and d.fiber_target_status = 'Target'
  then 'Fiber Upgrade in 2017'
  when dd.fiber_target_status = 'Target' and d.fiber_target_status = 'Target'
  then 'Still Fiber Target in 2017'
end as fiber_target_in_2016,

/* limit to connectivity_status change */
case
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then 'Newly Meeting Connectivity Goal in 2017'
  when dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false
  then 'Still Not Meeting in 2017'
end as connectivity_status,

/* limit to connectivity_status change with upgrade indicator */
case
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false and dd.upgrade_indicator = true
  then 'Newly Meeting Connectivity Goal in 2017'
  when dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false
  then 'Still Not Meeting in 2017'
end as connectivity_status_upgrade_limit,

/* limit to upgrades */
dd.upgrade_indicator as upgrade_2017,

/* limit to knapsack change */
case 
  when dd.meeting_knapsack_affordability_target = true and d.meeting_knapsack_affordability_target = false
  then 'Newly Meeting Knapsack in 2017'
  when dd.meeting_knapsack_affordability_target = false and d.meeting_knapsack_affordability_target = false
  then 'Still Not Meeting Knapsack'
end as knapsack_status

from public.fy2017_districts_deluxe_matr dd
inner join public.fy2016_districts_deluxe_matr d
on d.esh_id = dd.esh_id

where 
-- 2017
dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_analysis = false 
and dd.exclude_from_ia_cost_analysis = false

-- 2016
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'
and d.exclude_from_ia_analysis = false 
and d.exclude_from_ia_cost_analysis = false