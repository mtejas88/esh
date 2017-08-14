select '2017' as year, meeting_2014_goal_no_oversub,
count(esh_id) as ndistricts,
sum(ia_bw_mbps_total*1000)::numeric as total_bw,
sum(num_students) as total_students
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2
union
select '2016' as year, meeting_2014_goal_no_oversub,
count(esh_id) as ndistricts,
sum(ia_bw_mbps_total*1000)::numeric as total_bw,
sum(num_students) as total_students
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2
union
select '2015' as year, meeting_2014_goal_no_oversub,
count(esh_id) as ndistricts,
sum((total_ia_bw_mbps*1000)) as total_bw,
sum(num_students::numeric)::numeric as total_students
from public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1,2
order by 1,2

