select 
  case
    when (dd17.ia_monthly_cost_total/dd16.ia_monthly_cost_total)-1 < -.1
      then 'paid less'
    when (dd17.ia_monthly_cost_total/dd16.ia_monthly_cost_total)-1 > .1
      then 'paid more'
    else 'paid about the same'
  end as category,
  count(*) as num_districts
from fy2017_districts_deluxe_matr dd17
join fy2016_districts_deluxe_matr dd16
on dd17.esh_id = dd16.esh_id
where dd17.include_in_universe_of_districts
and dd16.include_in_universe_of_districts
and dd17.district_type = 'Traditional'
and dd16.district_type = 'Traditional'
and dd17.exclude_from_ia_cost_analysis = false
and dd16.exclude_from_ia_cost_analysis = false
and dd17.hierarchy_ia_connect_category = 'Fiber'
and dd16.hierarchy_ia_connect_category != 'Fiber'
group by 1