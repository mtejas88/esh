select '2015' as year,
sum(num_schools::integer)::integer as schools,
sum(case when meeting_2014_goal_no_oversub=true then num_schools::integer else 0 end)::integer as schools_meeting,
count(esh_id)::integer as districts,
count(case when meeting_2014_goal_no_oversub=true then esh_id end)::integer as districts_meeting
from  public.fy2015_districts_deluxe_m
where exclude_from_analysis=false
group by 1
union
select '2016' as year,
sum(num_schools::integer)::integer as schools,
sum(case when meeting_2014_goal_no_oversub=true then num_schools::integer else 0 end)::integer as schools_meeting,
count(esh_id)::integer as districts,
count(case when meeting_2014_goal_no_oversub=true then esh_id end)::integer as districts_meeting          
from public.fy2016_districts_deluxe_matr
where exclude_from_ia_analysis=false
            and include_in_universe_of_districts
            and district_type = 'Traditional'
            group by 1
union
select '2017' as year,
sum(num_schools::integer)::integer as schools,
sum(case when meeting_2014_goal_no_oversub=true then num_schools::integer else 0 end)::integer as schools_meeting,
count(esh_id)::integer as districts,
count(case when meeting_2014_goal_no_oversub=true then esh_id end)::integer as districts_meeting        
from public.fy2017_districts_deluxe_matr
where exclude_from_ia_analysis=false
            and include_in_universe_of_districts
            and district_type = 'Traditional'
            group by 1
order by 1