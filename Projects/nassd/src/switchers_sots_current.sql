with d15 as (select c.*
    from public.fy2015_districts_deluxe_m c
    )

select
2016 as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.num_students, 
dd.num_schools::numeric,
dd.num_campuses,
dd.locale,
dd.district_size,
dd.frl_percent,
dd.exclude_from_ia_analysis,
dd.exclude_from_ia_cost_analysis,
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
case when dd.needs_wifi=true then 'Insuff. Wi-Fi'
when dd.needs_wifi=false then 'Suff. Wi-Fi' else 'Unknown' 
end as wifi_need,
dd.fiber_target_status,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal,
case
  when d.exclude_from_analysis = true
  then null
  when d.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal_16,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_1m_goal,
case
  when d.exclude_from_analysis = true
  then null
  when d.meeting_2018_goal_oversub = true 
  then 1
  else 0
end as meeting_1m_goal_16,
case when dd.exclude_from_ia_analysis = false then dd.ia_bw_mbps_total end as ia_bw_mbps_total,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_total end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then true
  when dd.exclude_from_ia_analysis = false and d.exclude_from_analysis = false and 
  (dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false) or (dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = true)
  then false
  else null
end as upgrade_indicator,
case
  when dd.exclude_from_ia_analysis = false then dd.upgrade_indicator
  else null
end as upgrade_indicator2,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target,
case when d.exclude_from_analysis = false then d.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target_16,
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
case
  when ddd.exclude_from_ia_analysis = false and dd.exclude_from_ia_analysis = false and ddd.meeting_2018_goal_oversub = true and dd.meeting_2018_goal_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity_1m,
dd.service_provider_assignment as dominant_sp,
dd.primary_sp_bandwidth,
dd.primary_sp_percent_of_bandwidth,

case when d.exclude_from_analysis=false then d.total_ia_bw_mbps::numeric end as ia_bw_mbps_total_16,
case when d.exclude_from_analysis=false then d.monthly_ia_cost_per_mbps::numeric end as ia_monthly_cost_per_mbps_16,
case when d.exclude_from_analysis=false then d.total_ia_monthly_cost::numeric end as ia_monthly_cost_total_16,
d.service_provider_assignment as dominant_sp_16,
case when sr15.earliest_contract_end_date < '2016-07-01' then 'Expiring' else 'Mid-Contract'
end as contract_expiring,
dd.purpose_match, 
dd.switcher


from public.fy2016_districts_deluxe_matr dd
left join d15 d
on dd.esh_id::numeric = d.esh_id
left join public.fy2017_districts_deluxe_matr ddd
on ddd.esh_id::numeric = dd.esh_id::numeric
left join public.states s
on dd.postal_cd = s.postal_cd
left join (select recipient_id, case when reporting_name is null then service_provider_name else reporting_name end as reporting_name, min(contract_end_date) as earliest_contract_end_date
from public.fy2015_services_received_m
group by 1,2) sr15
on dd.esh_id::numeric=sr15.recipient_id::numeric
and d.service_provider_assignment=sr15.reporting_name
left join  public.general_sp_not_switchers gsp
on d.service_provider_assignment=gsp.service_provider_2015
and dd.service_provider_assignment=gsp.service_provider_2016
left join public.state_specific_sp_not_switchers ssp
on d.service_provider_assignment=ssp.service_provider_2015
and dd.service_provider_assignment=ssp.service_provider_2016
and dd.postal_cd=ssp.postal_cd
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.service_provider_assignment is not null 
and d.service_provider_assignment is not null
and d.monthly_ia_cost_per_mbps not in ('Insufficient data','Infinity')

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
dd.district_size,
dd.frl_percent,
dd.exclude_from_ia_analysis,
dd.exclude_from_ia_cost_analysis,
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
case when dd.needs_wifi=true then 'Insuff. Wi-Fi'
when dd.needs_wifi=false then 'Suff. Wi-Fi' else 'Unknown' 
end as wifi_need,
dd.fiber_target_status,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal,
case
  when d.exclude_from_ia_analysis = true
  then null
  when d.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal_16,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_1m_goal,
case
  when d.exclude_from_ia_analysis = true
  then null
  when d.meeting_2018_goal_oversub = true 
  then 1
  else 0
end as meeting_1m_goal_16,
case when dd.exclude_from_ia_analysis = false then dd.ia_bw_mbps_total end as ia_bw_mbps_total,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_total end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then true
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and 
  (dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false) or (dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = true)
  then false
  else null
end as upgrade_indicator,
case
  when dd.exclude_from_ia_analysis = false then dd.upgrade_indicator
  else null
end as upgrade_indicator2,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target,
case when d.exclude_from_ia_analysis = false and d.exclude_from_ia_cost_analysis = false then d.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target_16,
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
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and dd.meeting_2018_goal_oversub = true and d.meeting_2018_goal_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity_1m,
dd.service_provider_assignment as dominant_sp,
dd.primary_sp_bandwidth,
dd.primary_sp_percent_of_bandwidth,

case when d.exclude_from_ia_analysis = false then d.ia_bw_mbps_total end as ia_bw_mbps_total_16,
case when d.exclude_from_ia_analysis = false and d.exclude_from_ia_cost_analysis = false then d.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps_16,
case when d.exclude_from_ia_analysis = false and d.exclude_from_ia_cost_analysis = false then d.ia_monthly_cost_total end as ia_monthly_cost_total_16,
d.service_provider_assignment as dominant_sp_16,
case when sr16.earliest_contract_end_date < '2017-07-01' then 'Expiring' else 'Mid-Contract'
end as contract_expiring,
dd.purpose_match, 
dd.switcher


from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id::numeric = d.esh_id::numeric
left join public.states s
on dd.postal_cd = s.postal_cd
left join (select recipient_id, case when reporting_name is null then service_provider_name else reporting_name end as reporting_name, min(contract_end_date) as earliest_contract_end_date
from public.fy2016_services_received_matr
group by 1,2) sr16
on dd.esh_id::numeric=sr16.recipient_id::numeric
and d.service_provider_assignment=sr16.reporting_name
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.service_provider_assignment is not null 
and d.service_provider_assignment is not null