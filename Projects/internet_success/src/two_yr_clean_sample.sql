select distinct 
dd.esh_id,
dd.nces_cd,
dd.postal_cd,
dd.num_students,
dd.num_schools,
dd.num_campuses,
dd.district_size,
dd.locale,
dd.ulocal,
dd.frl_percent,
case 
	when dd.num_teachers = 0
	then null
	else dd.num_students/dd.num_teachers 
end as student_teacher_ratio,
dd.num_teachers,
case
  when dd.c2_prediscount_budget_15 = 0 or dd.c2_prediscount_budget_15 is null
  then null 
  else (dd.c2_prediscount_budget_15 - dd.c2_prediscount_remaining_16)/dd.c2_prediscount_budget_15
end as percent_c2_budget_used,
dd.ia_bw_mbps_total as total_bw_16,
dd.ia_bandwidth_per_student_kbps as bw_per_student_16,
ddd.total_ia_bw_mbps as total_bw_15,
ddd.ia_bandwidth_per_student as bw_per_student_15,
(dd.ia_bandwidth_per_student_kbps-ddd.ia_bandwidth_per_student::numeric)/ddd.ia_bandwidth_per_student::numeric as percent_bw_per_student_change

from public.fy2016_districts_deluxe_matr dd 
inner join public.fy2015_districts_deluxe_m ddd
on dd.esh_id::numeric = ddd.esh_id::numeric 

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'

and dd.exclude_from_ia_analysis = false
and ddd.exclude_from_analysis = false
and ddd.ia_bandwidth_per_student != 'Insufficient data'