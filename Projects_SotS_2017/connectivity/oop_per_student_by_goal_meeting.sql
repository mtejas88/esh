select 
  meeting_2014_goal_no_oversub::varchar,
  count(*) as num_districts,
  median((ia_monthly_cost_total - ia_monthly_funding_total)/num_students) as oop_per_student,
  median(discount_rate_c1_matrix) as median_discount_rate
from fy2017_districts_deluxe_matr dd17
where dd17.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd17.exclude_from_ia_cost_analysis = false
group by 1

UNION

select 
  'overall' as meeting_2014_goal_no_oversub,
  count(*) as num_districts,
  median((ia_monthly_cost_total - ia_monthly_funding_total)/num_students) as oop_per_student,
  median(discount_rate_c1_matrix) as median_discount_rate
from fy2017_districts_deluxe_matr dd17
where dd17.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd17.exclude_from_ia_cost_analysis = false