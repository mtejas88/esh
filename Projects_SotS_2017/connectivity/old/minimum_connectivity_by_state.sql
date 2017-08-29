select d17.postal_cd,d17.pct_meeting_100k_goal,
d17.pct_meeting_100k_goal - d16.pct_meeting_100k_goal as pct_diff_meeting_100k_goal
from 
(select postal_cd, 
count(case when meeting_2014_goal_no_oversub = true then esh_id end)::numeric / count(esh_id) as pct_meeting_100k_goal
from public.fy2017_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1) d17
join
(select postal_cd, 
count(case when meeting_2014_goal_no_oversub = true then esh_id end)::numeric / count(esh_id) as pct_meeting_100k_goal
from public.fy2016_districts_deluxe_matr 
where exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
group by 1) d16
on d17.postal_cd=d16.postal_cd
order by 3 desc