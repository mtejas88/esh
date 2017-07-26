with dd_union as (select
2016 as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.num_students, 
dd.num_schools::numeric,
dd.num_campuses,
dd.locale,
case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 'Rural & Town' 
  when dd.locale = 'Urban' or dd.locale = 'Suburban'
  then 'Urban & Suburban'
  else null
end as locale_2,
dd.district_size,
dd.frl_percent,
case
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .05
  then '<5%'
  when dd.frl_percent <=.74
  then '5-74%'
  else '75%+'
end as frl_percent_grouping,

-- General E-rate/Broadband Info
case
  when dd.discount_rate_c1_matrix <= .25
  then ' 20-25%'
  else to_char(dd.discount_rate_c1_matrix*100,'99%')
end as discount_rate_c1,
case
  when dd.discount_rate_c2 <= .25
  then ' 20-25%'
  when dd.discount_rate_c2 is not null 
  then to_char(dd.discount_rate_c2*100,'99%')
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .1 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 20-25%'
  when dd.frl_percent < .1 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 20-25%'
  when dd.frl_percent < .2 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 40%'
  when dd.frl_percent < .2 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Urban' or dd.locale = 'Suburban')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 70%'
  when dd.frl_percent < .75 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 80%'
  when dd.frl_percent < .75 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 80%'
  else ' 85%'
end as discount_rate_c2,
org_structure,
case 
  when dd.exclude_from_ia_analysis = false
  then dd.ia_procurement_type
  else null
end as ia_procurement_type,
case
  when dd.postal_cd in ('AZ','CA','CO','FL','IL','KS','MA','MD','MN','MO','MT','NC','NH','NJ','NM','NV','NY','OH','OK','TX','VA','WA','WI','WY','AK','AL','CT','NE','OR')
  then 'Engaged'
  else 'Non Engaged'
end as state_engagement,

-- CLEAN V DIRTY
case
  when dd.exclude_from_ia_analysis = false 
  then 1
  else 0
end as exclude_from_ia_analysis,
case
  when dd.exclude_from_ia_cost_analysis = false
  then 1
  else 0
end as exclude_from_ia_cost_analysis,

-- BW 
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_2018_goal_oversub,
case
  when dd.exclude_from_ia_analysis = false
  then dd.ia_bandwidth_per_student_kbps
  else null
end as ia_bandwidth_per_student_kbps,
-- FIBER
dd.fiber_target_status,
(dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses) as unscalable_campuses,

-- WIFI
case
  when dd.needs_wifi = true 
  then 1
  when dd.needs_wifi = false
  then 0
  else null
end as needs_wifi,
case
  when dd.c2_prediscount_budget_15 = 0
  then null
  else (dd.c2_prediscount_budget_15 - dd.c2_prediscount_remaining_16)/dd.c2_prediscount_budget_15
end as percent_c2_budget_used,
case 
  when dd.c2_prediscount_budget_15 = 0
  then null
  else 1-((dd.c2_prediscount_budget_15 - dd.c2_prediscount_remaining_16)/dd.c2_prediscount_budget_15) 
end as percent_c2_budget_remaining,
dd.c2_prediscount_remaining_16 as c2_prediscount_remaining,
dd.c2_postdiscount_remaining_16 as c2_postdiscount_remaining,

-- AFFORDABILITY
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_knapsack_affordability_target = true
  then 1
  else 0
end as meeting_knapsack,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null 
  else dd.ia_monthly_cost_per_mbps
end as ia_monthly_cost_per_mbps,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null 
  else dd.ia_bw_mbps_total -- will specifically be used to calculated Weighted Average $/Mbps
end as ia_bw_mbps_total_efc, 
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  else dd.ia_monthly_cost_total
end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true -- and discount_rate_c1 > 0 /* this is a part of 2015 calc, should it be included in 2016? */
  then null
  else dd.ia_monthly_cost_total-dd.ia_monthly_funding_total
end as ia_monthly_district_total,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  else knapsack_bandwidth(dd.ia_monthly_cost_total)
end as knapsack_bandwidth,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000/dd.num_students) < 100 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000/dd.num_students) >= 100 
  then 1
end as knapsack_meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000*dd.ia_oversub_ratio/dd.num_students) < 1000 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000*dd.ia_oversub_ratio/dd.num_students) >= 1000 
  then 1
end as knapsack_meeting_2018_goal_oversub,
-- UPGRADE
case
   when dd.exclude_from_ia_analysis = true or d.exclude_from_analysis = true
   then null
   when dd.upgrade_indicator = true 
   then 1
   else 0
end as upgrade,
case
  when dd.exclude_from_ia_analysis = true or d.exclude_from_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false 
  then 1
  else 0
end as upgraded_to_meet_2014_goal,
case 
  when ddd.fiber_target_status = 'Not Target' and dd.fiber_target_status = 'Target' 
  then 1
  else null
end as cohort_16_to_17_fiber,
case
  when ddd.exclude_from_ia_analysis = false and dd.exclude_from_ia_analysis = false and ddd.meeting_2014_goal_no_oversub = true and dd.meeting_2014_goal_no_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity,

-- SWITCHER

-- SERVICE PROVIDER
dd.service_provider_assignment,
case
  when dd.service_provider_assignment in ('Connecticut Education Network', 'County of Clackamas', 'Douglas Sevices Inc', 'Eastern Suffolk', 'EDLINK12', 'ESA Region 20', 
        'ESC Region 1', 'ESC Region 11', 'ESC Region 17', 'ESC Region 2', 'ESC Region 6', 'ESC7Net', 'Illinois Century', 'King County', 'Lake Geauga', 'Lower Hudson', 
        'Metropolitan Dayton', 'Miami Valley', 'Midland Council', 'NC OH Comp Coop', 'NE OH Management', 'NE OH Network', 'NE Serv Coop', 'Norther OH Area CS', 'Northern Buckeye', 
        'Northern OH Ed Comp', 'OH Mid Eastern ESA', 'Region 16 ESC', 'Region 18 ESC', 'Region 19 ESC', 'Region 3 ESC', 'Region 4 ESC', 'Region 9 ESC', 'SC OH Comp', 'SE MN Network', 
        'South Dakota Network', 'Stark Portage', 'SW OH Comp Asso', 'W OH Computer Org', 'W Suffolk Boces', 'Wasioja Cooperative','NC Office','Dept of Admin Services, CT','State of Iowa')
    

  then 'Consortia'
  when dd.service_provider_assignment = 'District Owned'
  then 'District Owned'
  when dd.service_provider_assignment is null
  then null
  else 'Regular'
end as service_provider_assignment_type


from public.fy2016_districts_deluxe_matr dd
left join public.fy2015_districts_deluxe_m d
on dd.esh_id::numeric = d.esh_id
left join public.fy2017_districts_deluxe_matr ddd
on ddd.esh_id::numeric = dd.esh_id::numeric
left join public.states s
on dd.postal_cd = s.postal_cd
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'

union 

select
2017 as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.num_students, 
dd.num_schools::numeric,
dd.num_campuses,
dd.locale,
case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 'Rural & Town' 
  when dd.locale = 'Urban' or dd.locale = 'Suburban'
  then 'Urban & Suburban'
  else null
end as locale_2,
dd.district_size,
dd.frl_percent,
case
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .05
  then '<5%'
  when dd.frl_percent <=.74
  then '5-74%'
  else '75%+'
end as frl_percent_grouping,

-- General E-rate/Broadband Info
case
  when dd.discount_rate_c1_matrix <= .25
  then ' 20-25%'
  else to_char(dd.discount_rate_c1_matrix*100,'99%')
end as discount_rate_c1,
case
  when dd.discount_rate_c2 <= .25
  then ' 20-25%'
  when dd.discount_rate_c2 is not null 
  then to_char(dd.discount_rate_c2*100,'99%')
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .1 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 20-25%'
  when dd.frl_percent < .1 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 20-25%'
  when dd.frl_percent < .2 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 40%'
  when dd.frl_percent < .2 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Urban' or dd.locale = 'Suburban')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 70%'
  when dd.frl_percent < .75 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 80%'
  when dd.frl_percent < .75 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 80%'
  else ' 85%'
end as discount_rate_c2,
s.org_structure,
case
  when dd.exclude_from_ia_analysis = false 
  then dd.ia_procurement_type
  else null
end as ia_procurement_type,
case
  when dd.postal_cd in ('AZ','CA','CO','FL','IL','KS','MA','MD','MN','MO','MT','NC','NH','NJ','NM','NV','NY','OH','OK','TX','VA','WA','WI','WY','AK','AL','CT','NE','OR')
  then 'Engaged'
  else 'Non Engaged'
end as state_engagement,

-- CLEAN V DIRTY
case
  when dd.exclude_from_ia_analysis = false 
  then 1
  else 0
end as exclude_from_ia_analysis,
case
  when dd.exclude_from_ia_cost_analysis = false
  then 1
  else 0
end as exclude_from_ia_cost_analysis,

-- BW 
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_2018_goal_oversub,
case
  when dd.exclude_from_ia_analysis = false
  then dd.ia_bandwidth_per_student_kbps
  else null
end as ia_bandwidth_per_student_kbps,
-- FIBER
dd.fiber_target_status,
(dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses) as unscalable_campuses,

-- WIFI
case
  when dd.needs_wifi = true 
  then 1
  when dd.needs_wifi = false
  then 0
  else null
end as needs_wifi,
case
  when dd.c2_prediscount_budget_15 = 0 or dd.c2_prediscount_budget_15 is null
  then null 
  else (dd.c2_prediscount_budget_15 - dd.c2_prediscount_remaining_17)/dd.c2_prediscount_budget_15 
end as percent_c2_budget_used,
case 
  when dd.c2_prediscount_budget_15 = 0 or dd.c2_prediscount_budget_15 is null
  then null 
  else 1-((dd.c2_prediscount_budget_15 - dd.c2_prediscount_remaining_17)/dd.c2_prediscount_budget_15) 
end as percent_c2_budget_remaining,
dd.c2_prediscount_remaining_17 as c2_prediscount_remaining,
dd.c2_postdiscount_remaining_17 as c2_postdiscount_remaining,

-- AFFORDABILITY
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_knapsack_affordability_target = true
  then 1
  else 0
end as meeting_knapsack,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null 
  else dd.ia_monthly_cost_per_mbps
end as ia_monthly_cost_per_mbps,

case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true 
  then null 
  else dd.ia_bw_mbps_total -- will specifically be used to calculated Weighted Average $/Mbps
end as ia_bw_mbps_total_efc, 
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  else dd.ia_monthly_cost_total
end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true -- and discount_rate_c1 > 0 /* this is a part of 2015 calc, should it be included in 2016? */
  then null
  else dd.ia_monthly_cost_total-dd.ia_monthly_funding_total
end as ia_monthly_district_total,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  else knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)
end as knapsack_bandwidth,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000/dd.num_students) < 100 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000/dd.num_students) >= 100 
  then 1
end as knapsack_meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000*dd.ia_oversub_ratio/dd.num_students) < 1000 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000*dd.ia_oversub_ratio/dd.num_students) >= 1000 
  then 1
end as knapsack_meeting_2018_goal_oversub,
-- UPGRADE
case
   when dd.exclude_from_ia_analysis = true or d.exclude_from_ia_analysis = true
   then null
   when dd.upgrade_indicator = true 
   then 1
   else 0
end as upgrade,
case
  when dd.exclude_from_ia_analysis = true or d.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false 
  then 1
  else 0
end as upgraded_to_meet_2014_goal,
case 
  when dd.fiber_target_status = 'Not Target' and d.fiber_target_status = 'Target' 
  then 1
  else null
end as cohort_16_to_17_fiber,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity,

-- SWITCHER

-- SERVICE PROVIDER
dd.service_provider_assignment,
case
  when dd.service_provider_assignment in ('Connecticut Education Network', 'County of Clackamas', 'Douglas Sevices Inc', 'Eastern Suffolk', 'EDLINK12', 'ESA Region 20', 
        'ESC Region 1', 'ESC Region 11', 'ESC Region 17', 'ESC Region 2', 'ESC Region 6', 'ESC7Net', 'Illinois Century', 'King County', 'Lake Geauga', 'Lower Hudson', 
        'Metropolitan Dayton', 'Miami Valley', 'Midland Council', 'NC OH Comp Coop', 'NE OH Management', 'NE OH Network', 'NE Serv Coop', 'Norther OH Area CS', 'Northern Buckeye', 
        'Northern OH Ed Comp', 'OH Mid Eastern ESA', 'Region 16 ESC', 'Region 18 ESC', 'Region 19 ESC', 'Region 3 ESC', 'Region 4 ESC', 'Region 9 ESC', 'SC OH Comp', 'SE MN Network', 
        'South Dakota Network', 'Stark Portage', 'SW OH Comp Asso', 'W OH Computer Org', 'W Suffolk Boces', 'Wasioja Cooperative','NC Office','Dept of Admin Services, CT','State of Iowa')
    

  then 'Consortia'
  when dd.service_provider_assignment = 'District Owned'
  then 'District Owned'
  when dd.service_provider_assignment is null
  then null
  else 'Regular'
end as service_provider_assignment_type

from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id = d.esh_id
left join public.states s
on dd.postal_cd = s.postal_cd
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional')








-- AGGREGATED TO STATES

select dd.year,
dd.postal_cd,
dd.service_provider_assignment,
dd.service_provider_assignment_type,
case
  when dd.service_provider_assignment in ('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
  then 1
  else null end
as sots_2016_service_provider,

-- DEMOGRAPHIC
count(dd.esh_id) as districts_served,
sum(dd.num_students) as students_served,
sum(case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 1
  else null end)
as districts_rural_and_town,


-- CONNECTIVIITY
sum(dd.meeting_2014_goal_no_oversub) as districts_meeting_100k,
sum(dd.meeting_2014_goal_no_oversub)/count(dd.meeting_2014_goal_no_oversub)::numeric as districts_meeting_100k_p,
sum(case
  when dd.meeting_2014_goal_no_oversub = 1
  then dd.num_students
  else null end)
as students_meeting_100k,
case 
  when (sum(dd.meeting_2014_goal_no_oversub)/count(dd.meeting_2014_goal_no_oversub)::numeric) > .99 
  then true
  else false
end as all_districts_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then 1
  else null end)
as districts_not_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then 1
  else null end)/count(dd.meeting_2014_goal_no_oversub)::numeric as districts_not_meeting_100k_p,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then dd.num_students
  else null end)
as students_not_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then dd.num_students
  else null end)/sum(case
  when dd.meeting_2014_goal_no_oversub = 0 or dd.meeting_2014_goal_no_oversub = 1
  then dd.num_students
  else null end)
as students_not_meeting_100k_p,
sum(dd.meeting_2018_goal_oversub) as districts_meeting_1m,
sum(dd.meeting_2018_goal_oversub)/count(dd.meeting_2018_goal_oversub)::numeric as districts_meeting_1m_p,
sum(case
  when meeting_2018_goal_oversub = 0
  then 1
  else null end)
as districts_not_meeting_1m,
sum(case
  when meeting_2018_goal_oversub = 0
  then 1
  else null end)/count(dd.meeting_2018_goal_oversub)::numeric as districts_not_meeting_1m_p,
median(dd.ia_bandwidth_per_student_kbps) as median_bw_per_student_kbps,

-- FIBER
sum(case
  when dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_not_target,
sum(case
  when dd.fiber_target_status = 'Not Target'
  then 1
  else null end)/sum(
  case when dd.fiber_target_status = 'Target' or dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_not_target_p,
sum(case
  when dd.fiber_target_status = 'Target'
  then 1
  else null end)
as districts_fiber_target,
sum(case
  when dd.fiber_target_status = 'Target'
  then 1
  else null end)/sum(
  case when dd.fiber_target_status = 'Target' or dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_fiber_target_p,
sum(dd.unscalable_campuses) as unscalable_campuses,

-- AFFORDABILITY
sum(dd.meeting_knapsack) as districts_meeting_knapsack,
sum(dd.meeting_knapsack)/count(dd.meeting_knapsack)::numeric as districts_meeting_knapsack_p,
median(dd.ia_monthly_cost_per_mbps) as median_ia_monthly_cost_per_mbps,

-- UPGRADE
sum(dd.upgrade) as districts_upgrade,
sum(dd.upgraded_to_meet_2014_goal) as districts_goal_meeting_change_upgrade,

-- COHORT 16 to 17

sum(cohort_16_to_17_fiber) as districts_cohort_16_to_17_fiber,
sum(cohort_16_to_17_connectivity) as districts_cohort_16_to_17_connectivity

from dd_union dd
where dd.service_provider_assignment is not null
and dd.service_provider_assignment != ''


group by dd.year,
dd.postal_cd,
dd.service_provider_assignment,
dd.service_provider_assignment_type





UNION




-- AGGREGATED TO NATIONAL 

select dd.year,
'National' as postal_cd,
dd.service_provider_assignment,
dd.service_provider_assignment_type,
case
  when dd.service_provider_assignment in ('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
  then 1
  else null end
as sots_2016_service_provider,

-- DEMOGRAPHIC
count(dd.esh_id) as districts_served,
sum(dd.num_students) as students_served,
sum(case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 1
  else null end)
as districts_rural_and_town,


-- CONNECTIVIITY
sum(dd.meeting_2014_goal_no_oversub) as districts_meeting_100k,
sum(dd.meeting_2014_goal_no_oversub)/count(dd.meeting_2014_goal_no_oversub)::numeric as districts_meeting_100k_p,
sum(case
  when dd.meeting_2014_goal_no_oversub = 1
  then dd.num_students
  else null end)
as students_meeting_100k,
case 
  when (sum(dd.meeting_2014_goal_no_oversub)/count(dd.meeting_2014_goal_no_oversub)::numeric) > .99 
  then true
  else false
end as all_districts_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then 1
  else null end)
as districts_not_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then 1
  else null end)/count(dd.meeting_2014_goal_no_oversub)::numeric as districts_not_meeting_100k_p,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then dd.num_students
  else null end)
as students_not_meeting_100k,
sum(case
  when dd.meeting_2014_goal_no_oversub = 0
  then dd.num_students
  else null end)/sum(case
  when dd.meeting_2014_goal_no_oversub = 0 or dd.meeting_2014_goal_no_oversub = 1
  then dd.num_students
  else null end)
as students_not_meeting_100k_p,
sum(dd.meeting_2018_goal_oversub) as districts_meeting_1m,
sum(dd.meeting_2018_goal_oversub)/count(dd.meeting_2018_goal_oversub)::numeric as districts_meeting_1m_p,
sum(case
  when meeting_2018_goal_oversub = 0
  then 1
  else null end)
as districts_not_meeting_1m,
sum(case
  when meeting_2018_goal_oversub = 0
  then 1
  else null end)/count(dd.meeting_2018_goal_oversub)::numeric as districts_not_meeting_1m_p,
median(dd.ia_bandwidth_per_student_kbps) as median_bw_per_student_kbps,

-- FIBER
sum(case
  when dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_not_target,
sum(case
  when dd.fiber_target_status = 'Not Target'
  then 1
  else null end)/sum(
  case when dd.fiber_target_status = 'Target' or dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_not_target_p,
sum(case
  when dd.fiber_target_status = 'Target'
  then 1
  else null end)
as districts_fiber_target,
sum(case
  when dd.fiber_target_status = 'Target'
  then 1
  else null end)/sum(
  case when dd.fiber_target_status = 'Target' or dd.fiber_target_status = 'Not Target'
  then 1
  else null end)
as districts_fiber_target_p,
sum(dd.unscalable_campuses) as unscalable_campuses,

-- AFFORDABILITY
sum(dd.meeting_knapsack) as districts_meeting_knapsack,
sum(dd.meeting_knapsack)/count(dd.meeting_knapsack)::numeric as districts_meeting_knapsack_p,
median(dd.ia_monthly_cost_per_mbps) as median_ia_monthly_cost_per_mbps,

-- UPGRADE
sum(dd.upgrade) as districts_upgrade,
sum(dd.upgraded_to_meet_2014_goal) as districts_goal_meeting_change_upgrade,

-- COHORT 16 to 17

sum(cohort_16_to_17_fiber) as districts_cohort_16_to_17_fiber,
sum(cohort_16_to_17_connectivity) as districts_cohort_16_to_17_connectivity

from dd_union dd
where dd.service_provider_assignment is not null
and dd.service_provider_assignment != ''


group by dd.year,
dd.service_provider_assignment,
dd.service_provider_assignment_type