select 'newly meeting 2014' as goals, dd.meeting_knapsack_affordability_target,
count(dd.esh_id) as ndistricts, 
count(case when dd.postal_cd != 'AK' and dd.exclude_from_ia_cost_analysis=false then dd.esh_id end) as ndistricts_cost,
sum(case when dd.postal_cd != 'AK'  and dd.exclude_from_ia_cost_analysis=false then dd.ia_monthly_cost_total end) as ia_monthly_cost_total,
sum(case when dd.postal_cd != 'AK'  and d.exclude_from_ia_cost_analysis=false then d.ia_monthly_cost_total end) as ia_monthly_cost_total_16,
sum(case when dd.postal_cd != 'AK'  and dd.exclude_from_ia_cost_analysis=false then dd.ia_bw_mbps_total end) as ia_bw_mbps_total,
sum(case when dd.postal_cd != 'AK'  and d.exclude_from_ia_cost_analysis=false then d.ia_bw_mbps_total end) as ia_bw_mbps_total_16

from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id::numeric=d.esh_id::numeric
where dd.exclude_from_ia_analysis=false
and dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and dd.meeting_2014_goal_no_oversub=true
and d.meeting_2014_goal_no_oversub=false
group by 1,2

union

select 'newly meeting 2018' as goals, dd.meeting_knapsack_affordability_target,
count(dd.esh_id) as ndistricts, 
count(case when dd.postal_cd != 'AK'  and dd.exclude_from_ia_cost_analysis=false then dd.esh_id end) as ndistricts_cost,
sum(case when dd.postal_cd != 'AK'  and dd.exclude_from_ia_cost_analysis=false then dd.ia_monthly_cost_total end) as ia_monthly_cost_total,
sum(case when dd.postal_cd != 'AK'  and d.exclude_from_ia_cost_analysis=false then d.ia_monthly_cost_total end) as ia_monthly_cost_total_16,
sum(case when dd.postal_cd != 'AK'  and dd.exclude_from_ia_cost_analysis=false then dd.ia_bw_mbps_total end) as ia_bw_mbps_total,
sum(case when dd.postal_cd != 'AK'  and d.exclude_from_ia_cost_analysis=false then d.ia_bw_mbps_total end) as ia_bw_mbps_total_16

from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id::numeric=d.esh_id::numeric
where dd.exclude_from_ia_analysis=false
and dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and dd.meeting_2018_goal_no_oversub=true
and d.meeting_2018_goal_no_oversub=false
group by 1,2
order by 1,2
