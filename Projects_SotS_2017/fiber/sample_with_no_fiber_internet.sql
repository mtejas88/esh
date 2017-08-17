select 
  meeting_2014_goal_no_oversub,
  hierarchy_ia_connect_category != 'Fiber' as no_fiber_internet_upstream,
  count(*) as num_districts
from fy2017_districts_deluxe_matr dd17
where dd17.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd17.exclude_from_ia_analysis = false
group by 1, 2