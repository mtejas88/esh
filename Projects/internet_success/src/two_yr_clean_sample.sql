select distinct 
dd.esh_id,
dd.nces_cd,
dd.postal_cd,

dd.num_students as num_students,
dd.num_schools as num_schools,
dd.num_campuses as num_campuses,
dd.district_size as district_size,

/*getting this information from 2017 NCES since it is using 2014_2015 data sets */
d.locale as locale,
d.frl_percent as frl_percent,

dd.ia_bw_mbps_total as total_bw_16,
dd.ia_bandwidth_per_student_kbps as bw_per_student_16,
ddd.total_ia_bw_mbps as total_bw_15,
ddd.ia_bandwidth_per_student as bw_per_student_15,
(dd.ia_bandwidth_per_student_kbps-ddd.ia_bandwidth_per_student::numeric)/ddd.ia_bandwidth_per_student::numeric as percent_bw_per_student_change

from public.fy2016_districts_deluxe_matr dd 
inner join public.fy2015_districts_deluxe_m ddd
on dd.esh_id::numeric = ddd.esh_id::numeric 

inner join public.fy2017_districts_deluxe_matr d
on d.esh_id::numeric = dd.esh_id::numeric

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'

and dd.exclude_from_ia_analysis = false
and ddd.exclude_from_analysis = false
and ddd.ia_bandwidth_per_student != 'Insufficient data'