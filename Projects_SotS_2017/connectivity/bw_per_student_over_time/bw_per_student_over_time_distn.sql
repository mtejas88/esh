
select '2017' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'10th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.10) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2017' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'25th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2017' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'50th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2017' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'75th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2017' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'90th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.9) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4

union

select '2016' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'10th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.10) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2016' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'25th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2016' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'50th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2016' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'75th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4
union
select '2016' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'90th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.9) WITHIN GROUP (ORDER BY ia_bandwidth_per_student_kbps) AS "bw_per_student"
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1,2,3,4

union

select '2015' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'10th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.10) WITHIN GROUP (ORDER BY ((total_ia_bw_mbps*1000)/(num_students::numeric))) AS "bw_per_student"
from public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1,2,3,4
union
select '2015' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'25th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY ((total_ia_bw_mbps*1000)/(num_students::numeric))) AS "bw_per_student"
from public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1,2,3,4
union
select '2015' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'50th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.5) WITHIN GROUP (ORDER BY ((total_ia_bw_mbps*1000)/(num_students::numeric))) AS "bw_per_student"
from public.fy2015_districts_deluxe_m 
where exclude_from_analysis=false
group by 1,2,3,4
union
select '2015' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'75th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY ((total_ia_bw_mbps*1000)/(num_students::numeric))) AS "bw_per_student"
from public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1,2,3,4
union
select '2015' as year, meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
'90th' as percentile,
count(esh_id) as ndistricts,
PERCENTILE_CONT (0.9) WITHIN GROUP (ORDER BY ((total_ia_bw_mbps*1000)/(num_students::numeric))) AS "bw_per_student"
from public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1,2,3,4

order by 1,2,3,4



