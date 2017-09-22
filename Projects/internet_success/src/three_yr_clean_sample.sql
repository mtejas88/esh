select distinct 

d.esh_id,
d.nces_cd,
d.postal_cd,

d.num_students as num_students,
d.num_schools as num_schools,
d.num_campuses as num_campuses,
d.locale as locale,
d.district_size as district_size,
d.frl_percent as frl_percent,

d.ia_bw_mbps_total as total_bw_17,
d.ia_bandwidth_per_student_kbps as bw_per_student_17,
dd.ia_bw_mbps_total as total_bw_16,
(dd.ia_bw_mbps_total*1000)/d.num_students as bw_per_student_16,
ddd.total_ia_bw_mbps as total_bw_15,
(ddd.total_ia_bw_mbps*1000)/d.num_students as bw_per_student_15

from public.fy2017_districts_deluxe_matr d
inner join public.fy2016_districts_deluxe_matr dd 
on d.esh_id::numeric = dd.esh_id::numeric
inner join public.fy2015_districts_deluxe_m ddd
on d.esh_id::numeric = ddd.esh_id::numeric 


where d.include_in_universe_of_districts = true
and dd.include_in_universe_of_districts

and d.district_type = 'Traditional'
and dd.district_type = 'Traditional'

and d.exclude_from_ia_analysis = false
and dd.exclude_from_ia_analysis = false
and ddd.exclude_from_analysis = false