with gained as(
select dd.service_provider_assignment, dd.postal_cd,
count(distinct case when dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_gained
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and dd.switcher='Switched'
and dd.purpose_match='Same'
and dd.service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
group by 1,2),

lost as (
select dd.service_provider_assignment, dd.postal_cd,
count(distinct case when dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_lost
from public.fy2016_districts_deluxe_matr dd
left join public.fy2017_districts_deluxe_matr ddd
on dd.esh_id=ddd.esh_id
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and ddd.switcher='Switched'
and ddd.purpose_match='Same'
and dd.service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
group by 1,2
)


select dd.service_provider_assignment, dd.postal_cd,
num_districts_gained,
num_districts_lost,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=true and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_meeting_clean,
sum(case when exclude_from_ia_analysis=false and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_served_clean,
count(distinct case when dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_served_clean
from public.fy2017_districts_deluxe_matr dd
left join gained g on dd.service_provider_assignment=g.service_provider_assignment
and dd.postal_cd=g.postal_cd
left join lost l on dd.service_provider_assignment=l.service_provider_assignment
and dd.postal_cd=l.postal_cd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and dd.service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
group by 1,2,3,4