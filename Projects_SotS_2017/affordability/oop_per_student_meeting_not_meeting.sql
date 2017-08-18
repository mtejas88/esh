select 
  meeting_2014_goal_no_oversub,
--  hierarchy_ia_connect_category != 'Fiber' as no_fiber_internet_upstream,
  count(*) as num_districts,
  median(ia_monthly_cost_total*(1-discount_rate_c1_matrix)/num_students) as oop_per_student
from fy2017_districts_deluxe_matr dd17
where dd17.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd17.exclude_from_ia_cost_analysis = false
group by 1--, 2