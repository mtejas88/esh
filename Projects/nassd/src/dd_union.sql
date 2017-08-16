/* TEMP TABLE FOR 2015: 
  at this point in time crusher dd15 has everything i want except for discount rate)*/
  with f as (select c.*,
    case
      when mg.discount_rate_c1::numeric <= 25
      then ' 20-25%'
      when mg.discount_rate_c1 is not null 
      then to_char(discount_rate_c1::numeric,'99%')
      when c.frl_percent is null
      then null
      when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 20-25%'
      when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 20-25%'
      when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 40%'
      when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 70%'
      when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 80%'
      when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 80%'
      when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 90%'
      when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 90%'
      else 'error'
    end as discount_rate_c1,
    case 
      when mg.discount_rate_c2::numeric <= 25
      then ' 20-25%'
      when mg.discount_rate_c2 is not null 
      then to_char(discount_rate_c2::numeric,'99%')
      when c.frl_percent is null
      then null
      when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 20-25%'
      when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 20-25%'
      when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 40%'
      when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 70%'
      when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 80%'
      when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 80%'
      when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 85%'
      when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 85%'
      else 'error'
    end as discount_rate_c2,
    case 
        when mg.discount_rate_c1 is not null
        then mg.discount_rate_c1::numeric/100
        when c.frl_percent is null
        then null 
        when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .2
        when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .25
        when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .4
        when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .5
        when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .6
        when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .6
        when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .6
        when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .7
        when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .8
        when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .8
        when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .9
        when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .9
        else null
      end as discount_rate_c1_num -- for calculations 

    from public.fy2015_districts_deluxe_m c
    left join endpoint.fy2015_districts_deluxe mg
    on c.esh_id = mg.esh_id)

/* 2015 DISTRICT DELUXE */

-- General Info/Demographic
select 2015 as year,
f.esh_id,
initcap(f.name) as name,
f.postal_cd,
f.num_students::numeric,
f.num_schools::numeric,
f.num_campuses,
case 
  when f.locale = 'Small Town' 
  then 'Town'
  else locale
end as locale,
case 
	when f.locale = 'Small Town' or f.locale = 'Rural'
	then 'Rural & Town'
	when f.locale = 'Urban' or f.locale = 'Suburban'
	then 'Urban & Suburban'
	else null
end as locale_2,
f.district_size,
f.frl_percent,
case
  when f.frl_percent is null
  then null
  when f.frl_percent < .05
  then '<5%'
  when f.frl_percent <=.74
  then '5-74%'
  else '75%+'
end as frl_percent_grouping,

-- General E-rate/Broadband Info
f.discount_rate_c1,
f.discount_rate_c2,
s.org_structure,
null as ia_procurement_type,
case
  when f.postal_cd in ('AZ','CA','CO','FL','IL','KS','MA','MD','MN','MO','MT','NC','NH','NJ','NM','NV','NY','OH','OK','TX','VA','WA','WI','WY','AK','AL','CT','NE','OR')
  then 'Engaged'
  else 'Non Engaged'
end as state_engagement,

-- CLEAN V DIRTY
case
  when f.exclude_from_analysis = false
  then 1
  else 0
end as exclude_from_ia_analysis,
case when f.exclude_from_analysis = false /* there isn't a 2015 equivalent so duplicating regular exclude from analysis*/
  then 1
  else 0
end as exclude_from_ia_cost_analysis,

-- BW 
case
  when f.exclude_from_analysis = true
  then null
  when f.meeting_2014_goal_no_oversub = true
  then 1
  else 0
end as meeting_2014_goal_no_oversub,
case
  when f.exclude_from_analysis = true
  then null
  when f.meeting_2018_goal_oversub = true 
  then 1
  else 0
end as meeting_2018_goal_oversub,
case
  when f.exclude_from_analysis = true or f.ia_bandwidth_per_student = 'Insufficient data'
  then null
  else f.ia_bandwidth_per_student::numeric 
end as ia_bandwidth_per_student_kbps,

-- FIBER 
null as fiber_target_status,
null as unscalable_campuses,

-- WIFI
null as needs_wifi,
null as percent_c2_budget_used,
null as percent_c2_budget_remaining,
null as c2_prediscount_remaining, 
null as c2_postdiscount_remaining,

-- AFFORDABILITY
null as meeting_knapsack,
case
  when f.exclude_from_analysis = true or f.monthly_ia_cost_per_mbps = 'Insufficient data' or f.monthly_ia_cost_per_mbps = 'Infinity'
  then null
  else f.monthly_ia_cost_per_mbps::numeric
end as ia_monthly_cost_per_mbps,
case 
  when f.exclude_from_analysis = true or f.monthly_ia_cost_per_mbps = 'Insufficient data' or f.monthly_ia_cost_per_mbps = 'Infinity'
  then null 
  else f.total_ia_bw_mbps::numeric 
end as ia_bw_mbps_total_efc, 
case 
  when f.exclude_from_analysis = false
  then f.total_ia_monthly_cost::numeric 
  else null
end as ia_monthly_cost_total,
case
  when f.exclude_from_analysis = false and discount_rate_c1_num > 0
  then f.total_ia_monthly_cost::numeric*(1-discount_rate_c1_num)
  else null
end as ia_monthly_district_total,
null as knapsack_bandwidth,
null as knapsack_meeting_2014_goal_no_oversub,
null as knapsack_meeting_2018_goal_oversub,

-- UPGRADE
null as upgrade,
null as upgraded_to_meet_2014_goal,
null cohort_16_to_17_fiber,
null cohort_16_to_17_connectivity,
-- SWITCHER

-- SERVICE PROVIDER
null as service_provider_assignment


from f
join public.states s
on s.postal_cd = f.postal_cd
/*Note: do not need to limit to districts in universe because 2015 DD is already limited to that */

union

/* 2016 DISTRICT DELUXE */ 

-- General Info/Demographic

select
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
  when dd.ia_monthly_cost_total < 700 /* knapsack bandwidth function doesn't work for costs below $700 */  
  then dd.ia_monthly_cost_total/14
  else knapsack_bandwidth(dd.ia_monthly_cost_total)
end as knapsack_bandwidth,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students < 100
  then 0
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students >= 100
  then 1 
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000/dd.num_students) < 100 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total)*1000/dd.num_students) >= 100 
  then 1
end as knapsack_meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students < 1000
  then 0
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students >= 1000
  then 1 
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
dd.service_provider_assignment

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
  when dd.ia_monthly_cost_total < 700
  then dd.ia_monthly_cost_total/14
  else knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)
end as knapsack_bandwidth,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students < 100
  then 0
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students >= 100
  then 1 
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000/dd.num_students) < 100 
  then 0
  when (knapsack_bandwidth(dd.ia_monthly_cost_total::numeric)*1000/dd.num_students) >= 100 
  then 1
end as knapsack_meeting_2014_goal_no_oversub,
case
  when dd.exclude_from_ia_cost_analysis = true or dd.exclude_from_ia_analysis = true
  then null
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students < 1000
  then 0
  when dd.ia_monthly_cost_total < 700 and ((dd.ia_monthly_cost_total/14)*1000)/dd.num_students >= 1000
  then 1 
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
dd.service_provider_assignment

from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id = d.esh_id
left join public.states s
on dd.postal_cd = s.postal_cd
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'