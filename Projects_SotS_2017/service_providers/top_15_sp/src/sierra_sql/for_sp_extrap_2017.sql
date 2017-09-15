select service_provider_assignment, postal_cd,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=true then num_students else 0 end) as num_students_meeting_clean,
sum(case when exclude_from_ia_analysis=false then num_students else 0 end) as num_students_served_clean,
sum(num_students) as num_students_total
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1,2