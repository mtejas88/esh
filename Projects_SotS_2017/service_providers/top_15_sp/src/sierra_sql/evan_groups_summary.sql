with t as(
select d.service_provider_assignment,
'2016' as cohort_year,
case
when d.service_provider_assignment is not null and dd.service_provider_assignment is not null 
and d.service_provider_assignment=dd.service_provider_assignment then '2017 retained'
when d.service_provider_assignment is not null and dd.service_provider_assignment is not null 
and d.service_provider_assignment!=dd.service_provider_assignment then '2017 switchers'
when d.service_provider_assignment is not null and (dd.service_provider_assignment is null 
and dd.exclude_from_ia_analysis!=false) then 'unknown dirty'
when d.service_provider_assignment is not null and dd.service_provider_assignment is null 
and (dd.exclude_from_ia_analysis=false) then 'unknown clean'
end as cohort_group,
case
when dd.exclude_from_ia_analysis=true and d.meeting_2014_goal_no_oversub=true then 'meeting 2016, dirty 2017'
when dd.exclude_from_ia_analysis=true and d.meeting_2014_goal_no_oversub=false then 'not meeting 2016, dirty 2017'
when d.meeting_2014_goal_no_oversub=true and dd.meeting_2014_goal_no_oversub=true then 'still meeting'
when d.meeting_2014_goal_no_oversub=false and dd.meeting_2014_goal_no_oversub=false then 'still not meeting'
when d.meeting_2014_goal_no_oversub=true and dd.meeting_2014_goal_no_oversub=false then 'downgrades'
when d.meeting_2014_goal_no_oversub=false and dd.meeting_2014_goal_no_oversub=true then 'upgrades'
end as progress_group,
count(d.esh_id) as districts,
sum(d.num_students) as students_2016,
sum(dd.num_students) as students_2017
from public.fy2016_districts_deluxe_matr d
inner join public.fy2017_districts_deluxe_matr dd
on d.esh_id = dd.esh_id

where dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true
and d.service_provider_assignment in ('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'
group by 1,2,3,4

union

select 
dd.service_provider_assignment,
'2017' as cohort_year,
case
when d.service_provider_assignment is not null and dd.service_provider_assignment is not null 
and d.service_provider_assignment!=dd.service_provider_assignment then '2017 new customers'
when dd.service_provider_assignment is not null and (d.service_provider_assignment is null 
and d.exclude_from_ia_analysis!=false) then 'new/unknown dirty'
when dd.service_provider_assignment is not null and d.service_provider_assignment is null 
and (d.exclude_from_ia_analysis=false) then 'new/unknown clean'
end as cohort_group,
case
when d.exclude_from_ia_analysis=true and dd.meeting_2014_goal_no_oversub=true then 'meeting 2017, dirty 2016'
when d.exclude_from_ia_analysis=true and dd.meeting_2014_goal_no_oversub=false then 'not meeting 2017, dirty 2016'
when d.meeting_2014_goal_no_oversub=true and dd.meeting_2014_goal_no_oversub=true then 'still meeting'
when d.meeting_2014_goal_no_oversub=false and dd.meeting_2014_goal_no_oversub=false then 'still not meeting'
when d.meeting_2014_goal_no_oversub=true and dd.meeting_2014_goal_no_oversub=false then 'downgrades'
when d.meeting_2014_goal_no_oversub=false and dd.meeting_2014_goal_no_oversub=true then 'upgrades'
end as progress_group,
count(dd.esh_id) as districts,
sum(d.num_students) as students_2016,
sum(dd.num_students) as students_2017

from public.fy2017_districts_deluxe_matr dd
inner join public.fy2016_districts_deluxe_matr d
on dd.esh_id = d.esh_id

where dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true
and dd.service_provider_assignment in ('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'
and not (d.service_provider_assignment is not null and dd.service_provider_assignment is not null 
and d.service_provider_assignment=dd.service_provider_assignment)
group by 1,2,3,4
)

select * from t order by 1,2,3,4