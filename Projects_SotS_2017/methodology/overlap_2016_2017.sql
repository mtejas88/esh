select
count(*) as num_districts,
sum(a.num_schools) as num_schools,
sum(a.num_campuses) as num_campuses,
sum(a.num_students) as num_students
from public.fy2016_districts_deluxe_matr a
join public.fy2017_districts_deluxe_matr dd
on a.esh_id=dd.esh_id
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_analysis=false 
and a.include_in_universe_of_districts
and a.district_type = 'Traditional'
and a.exclude_from_ia_analysis=false 