select service_provider_assignment, postal_cd,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_served_clean,
count(distinct case when dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_served_clean
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
group by 1,2