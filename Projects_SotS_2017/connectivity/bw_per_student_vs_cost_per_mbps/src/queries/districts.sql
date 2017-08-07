select
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.county,
dd.num_students, 
dd.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps_17,
dd.ia_bandwidth_per_student_kbps as bandwidth_per_student_kbps_17,
d.ia_monthly_cost_per_mbps as ia_monthly_cost_per_mbps_16,
d.ia_bandwidth_per_student_kbps as bandwidth_per_student_kbps_16,
d15.monthly_ia_cost_per_mbps as ia_monthly_cost_per_mbps_15,
d15.ia_bandwidth_per_student::numeric as bandwidth_per_student_kbps_15


from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id::numeric = d.esh_id::numeric
left join public.fy2015_districts_deluxe_m d15
on dd.esh_id::numeric = d15.esh_id::numeric
where dd.exclude_from_ia_analysis=false
and dd.exclude_from_ia_cost_analysis=false
and d.exclude_from_ia_analysis=false
and d.exclude_from_ia_cost_analysis=false
and d15.exclude_from_analysis=false
and d15.ia_bandwidth_per_student !='Insufficient data'