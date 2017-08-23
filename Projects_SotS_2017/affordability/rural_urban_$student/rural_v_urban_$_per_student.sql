with a as (select
2016 as year,
dd.esh_id::numeric,
dd.locale,
dd.discount_rate_c1,
dd.num_students,
case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 'Rural & Town' 
  when dd.locale = 'Urban' or dd.locale = 'Suburban'
  then 'Urban & Suburban'
  else null
end as locale_2,
dd.ia_monthly_funding_total,
dd.ia_monthly_funding_total/dd.num_students as ia_monthly_funding_total_per_student,
dd.ia_monthly_cost_total,
dd.ia_monthly_cost_total/dd.num_students as ia_monthly_cost_total_per_student,
(dd.ia_monthly_cost_total - dd.ia_monthly_funding_total) as ia_monthly_district_share,
(dd.ia_monthly_cost_total - dd.ia_monthly_funding_total)/dd.num_students as ia_monthly_district_share_per_student

from public.fy2016_districts_deluxe_matr dd

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_cost_analysis = false
and dd.exclude_from_ia_analysis = false

union 

select
2016 as year,
dd.esh_id::numeric,
dd.locale,
dd.discount_rate_c1,
dd.num_students,
case
  when dd.locale = 'Town' or dd.locale = 'Rural'
  then 'Rural & Town' 
  when dd.locale = 'Urban' or dd.locale = 'Suburban'
  then 'Urban & Suburban'
  else null
end as locale_2,
dd.ia_monthly_funding_total,
dd.ia_monthly_funding_total/dd.num_students as ia_monthly_funding_total_per_student,
dd.ia_monthly_cost_total,
dd.ia_monthly_cost_total/dd.num_students as ia_monthly_cost_total_per_student,
(dd.ia_monthly_cost_total - dd.ia_monthly_funding_total) as ia_monthly_district_share,
(dd.ia_monthly_cost_total - dd.ia_monthly_funding_total)/dd.num_students as ia_monthly_district_share_per_student

from public.fy2017_districts_deluxe_matr dd

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_cost_analysis = false
and dd.exclude_from_ia_analysis = false)

select year,
locale,
--locale_2,
round(median(ia_monthly_cost_total)) as median_ia_monthly_cost_total,
median(ia_monthly_cost_total_per_student) as median_ia_monthly_cost_total_per_student,
round(median(ia_monthly_funding_total)) as median_ia_monthly_funding_total,
median(ia_monthly_funding_total_per_student) as median_ia_monthly_funding_total_per_student,
round(median(ia_monthly_district_share)) as median_ia_monthly_district_share,
median(ia_monthly_district_share_per_student) as median_ia_monthly_district_share_per_student

from a 

where locale in ('Urban','Rural')

group by year,
locale
