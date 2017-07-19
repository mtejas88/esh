select '2017' as year, 'not meeting' as goals, 
count(esh_id) as ndistricts,
median(ia_bandwidth_per_student_kbps::numeric) as avg_bw_s
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
and meeting_2014_goal_no_oversub=false
group by 1,2
union
select '2017' as year, 'meeting' as goals, 
count(esh_id) as ndistricts,
median(ia_bandwidth_per_student_kbps::numeric) as avg_bw_s
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
and meeting_2014_goal_no_oversub=true
group by 1,2
union
select '2016' as year, 'not meeting' as goals, 
count(esh_id) as ndistricts,
median(ia_bandwidth_per_student_kbps::numeric) as avg_bw_s
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
and meeting_2014_goal_no_oversub=false
group by 1,2
union
select '2016' as year, 'meeting' as goals, 
count(esh_id) as ndistricts,
median(ia_bandwidth_per_student_kbps::numeric) as avg_bw_s
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
and meeting_2014_goal_no_oversub=true
group by 1,2
union
select '2015' as year, 'not meeting' as goals, 
count(esh_id) as ndistricts,
median((total_ia_bw_mbps*1000)/num_students::numeric) as avg_bw_s
from public.fy2015_districts_deluxe
where exclude_from_analysis=false
and meeting_2014_goal_no_oversub=false
group by 1,2
union
select '2015' as year, 'meeting' as goals, 
count(esh_id) as ndistricts,
median((total_ia_bw_mbps*1000)/num_students::numeric) as avg_bw_s
from public.fy2015_districts_deluxe
where exclude_from_analysis=false
and meeting_2014_goal_no_oversub=true
group by 1,2
order by 1,2

