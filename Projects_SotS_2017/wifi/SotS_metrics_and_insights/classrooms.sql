select s.district_esh_id,
s.school_esh_id,
d.postal_cd,
s.name,
s.num_students,
--assume 25 students per classroom
--source: http://www.nea.org/home/rankings-and-estimates-2013-2014.html
case
  when s.num_students <= 25
    then 1
  else ceil((s.num_students / 25))
end as num_classrooms

from public.fy2017_schools_demog_matr s
join public.fy2017_districts_deluxe_matr d
on s.district_esh_id = d.esh_id

where d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'

order by s.num_students desc