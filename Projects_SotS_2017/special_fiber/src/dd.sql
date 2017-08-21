select 
  count(esh_id) as num_districts,
  sum(num_students) as num_students,
  sum(num_schools) as num_schools

from public.fy2017_districts_deluxe_matr dd

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'