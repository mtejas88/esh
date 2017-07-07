with lookup_16 as (

select 
d16.postal_cd,
sum(case when d16.ia_bandwidth_per_student_kbps >= 100 then d16.num_students end) / sum(d16.num_students) as extrap_16

from public.fy2016_districts_deluxe_matr d16


where d16.include_in_universe_of_districts
and d16.exclude_from_ia_analysis = false
and district_type = 'Traditional'

group by 1
order by 1

),

lookup_15 as (

select 
postal_cd,
sum(case when ia_bandwidth_per_student::numeric >= 100 then num_students::numeric end) / sum(num_students::numeric) as extrap_15

from public.fy2015_districts_deluxe_m

where exclude_from_analysis = false
and ia_bandwidth_per_student != 'Insufficient data'
and esh_id::varchar in (
  select esh_id
  from public.fy2016_districts_metrics_matr 
  where include_in_universe_of_districts
  and district_type = 'Traditional'
)


group by 1
order by 1

)

select l16.postal_cd,
extrap_16,
extrap_15,
extrap_16 * d.num_students_16 as extrap_16_students,
extrap_15 * d.num_students_16 as extrap_15_students,
case when extrap_16 * d.num_students_16 < extrap_15 * d.num_students_16 then 0 
      else extrap_16 * d.num_students_16 - extrap_15 * d.num_students_16 end as new_students_meeting

        
from lookup_16 l16

left join lookup_15 l15
on l16.postal_cd = l15.postal_cd

left join (
  select postal_cd,
  sum(num_students) as num_students_16
  from public.fy2016_districts_deluxe_matr 
  where include_in_universe_of_districts
  and district_type = 'Traditional'
  group by 1
) d
on d.postal_cd = l16.postal_cd