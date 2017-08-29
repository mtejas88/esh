select meeting_2014_goal_no_oversub, count(*),
count(case when hierarchy_ia_connect_category = 'Fiber' then esh_id end) as fiber_cnt
from public.fy2017_districts_deluxe_matr 
where include_in_universe_of_districts
and district_type='Traditional'
and exclude_from_ia_analysis=false
group by 1