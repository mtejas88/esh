select 2015 as funding_year, count(esh_id) from
public.fy2015_districts_deluxe_m
where
meeting_2018_goal_oversub  = 'True'
and exclude_from_analysis = 'False'

union

select 2016 as funding_year, count(esh_id) from
public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and meeting_2018_goal_oversub
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False'

union

select 2017 as funding_year, count(esh_id) from
public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and meeting_2018_goal_oversub
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False'

order by funding_year
