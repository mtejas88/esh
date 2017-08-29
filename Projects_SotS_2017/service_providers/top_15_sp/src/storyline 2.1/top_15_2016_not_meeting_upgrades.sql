with districts_notmeeting_2016_top15 as
(select distinct esh_id, service_provider_assignment,
meeting_2014_goal_no_oversub, num_students
from public.fy2016_districts_deluxe_matr del
where  exclude_from_ia_analysis=false
and include_in_universe_of_districts
and meeting_2014_goal_no_oversub=false
and service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
)

select 
dd.switcher,
dd.upgrade_indicator,
count(distinct nm16.esh_id) as ndistricts,
sum(nm16.num_students) as nstudents
from districts_notmeeting_2016_top15 nm16
left join  public.fy2017_districts_deluxe_matr dd
on nm16.esh_id=dd.esh_id
and dd.exclude_from_ia_analysis=false
and dd.include_in_universe_of_districts
group by 1,2 order by 1,2