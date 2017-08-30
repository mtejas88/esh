select 
  case
    when locale in ('Rural', 'Town')
      then 'Rural'
    else 'Urban'
  end as locale,
  count(*) as num_districts,
  median((ia_monthly_cost_total - ia_monthly_funding_total)*12/num_students) as median_oop_per_student_annual,
  sum(ia_monthly_cost_total - ia_monthly_funding_total)*12/sum(num_students::numeric) as agg_oop_per_student_annual,
  median(discount_rate_c1_matrix) as median_discount_rate,
  avg(discount_rate_c1_matrix) as avg_discount_rate
from fy2017_districts_deluxe_matr dd17
where dd17.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd17.exclude_from_ia_cost_analysis = false
group by 1