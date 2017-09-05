select '2016' as year,
exclude_from_ia_analysis, count(*) as num_districts,
sum(num_schools) as num_schools,
sum(num_campuses) as num_campuses,
sum(num_students) as num_students
from public.fy2016_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1,2
union
select '2017' as year,
exclude_from_ia_analysis, count(*) as num_districts,
sum(num_schools) as num_schools,
sum(num_campuses) as num_campuses,
sum(num_students) as num_students
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1,2
order by 1,2