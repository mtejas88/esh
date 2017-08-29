
with districts_2017 as (
  select *
  from fy2017_districts_deluxe_matr
  where include_in_universe_of_districts
  and district_type = 'Traditional'
)


--What percent of service providers offer benchmark prices to at least one of their districts
  --broken down by goal meeting status, in case interesting
select  
dd.meeting_2014_goal_no_oversub::varchar,
count(distinct case when meeting_knapsack_affordability_target = true then dd.service_provider_assignment end)::numeric / 
count(distinct dd.service_provider_assignment) as pct_sps_offering_benchmark
from districts_2017 dd
where dd.exclude_from_ia_analysis=false
and dd.exclude_from_ia_cost_analysis=false
and dd.service_provider_assignment is not null
group by 1 

union

select  
'all' as meeting_2014_goal_no_oversub,
count(distinct case when meeting_knapsack_affordability_target = true then dd.service_provider_assignment end)::numeric / 
count(distinct dd.service_provider_assignment) as pct_sps_offering_benchmark
from districts_2017 dd
where dd.exclude_from_ia_analysis=false
and dd.exclude_from_ia_cost_analysis=false
and dd.service_provider_assignment is not null
group by 1
order by 1
