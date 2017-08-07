select
'2017' as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.county,
dd.num_students, 
dd.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps,
dd.ia_bandwidth_per_student_kbps as bandwidth_per_student_kbps

from public.fy2017_districts_deluxe_matr dd
where dd.exclude_from_ia_analysis=false
and dd.exclude_from_ia_cost_analysis=false


union

select
'2016' as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.county,
dd.num_students, 
dd.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps,
dd.ia_bandwidth_per_student_kbps as bandwidth_per_student_kbps

from public.fy2016_districts_deluxe_matr dd
where dd.exclude_from_ia_analysis=false
and dd.exclude_from_ia_cost_analysis=false

union

select
'2015' as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.county,
dd.num_students::numeric, 
dd.monthly_ia_cost_per_mbps::numeric as ia_monthly_cost_per_mbps,
dd.ia_bandwidth_per_student::numeric as bandwidth_per_student_kbps
from public.fy2015_districts_deluxe_m dd
where dd.exclude_from_analysis=false
and dd.ia_bandwidth_per_student !='Insufficient data'
and dd.monthly_ia_cost_per_mbps not in ('Insufficient data','Infinity')
and dd.num_students !='Insufficient data'

