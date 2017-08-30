select esh_id::varchar,
postal_cd,
num_students::varchar,
ia_bandwidth_per_student::varchar as bw_per_student,
case
  when ia_cost_per_mbps != 'Insufficient data'
   and ia_cost_per_mbps != 'Infinity'
    then ia_cost_per_mbps::numeric
end as ia_cost_per_mbps,
district_size,
locale,
2015 as year

from public.fy2015_districts_deluxe_m

where exclude_from_analysis = false

union

select esh_id::varchar,
postal_cd,
num_students::varchar,
ia_bandwidth_per_student_kbps::varchar as bw_per_student,
case
	when exclude_from_ia_cost_analysis = false
		then ia_monthly_cost_per_mbps
end as ia_cost_per_mbps,
district_size,
locale,
2016 as year

from public.fy2016_districts_deluxe_matr

where exclude_from_ia_analysis = false
and include_in_universe_of_districts
and district_type = 'Traditional'

union

select esh_id::varchar,
postal_cd,
num_students::varchar,
ia_bandwidth_per_student_kbps::varchar as bw_per_student,
case
	when exclude_from_ia_cost_analysis = false
		then ia_monthly_cost_per_mbps
end as ia_cost_per_mbps,
district_size,
locale,
2017 as year

from public.fy2017_districts_deluxe_matr

where exclude_from_ia_analysis = false
and include_in_universe_of_districts
and district_type = 'Traditional'