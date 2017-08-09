select d.service_provider_assignment,
count(dd.esh_id) as potential_districts,
sum(case
  when dd.service_provider_assignment is null
  then 1 end)
as no_assignment_yet,
sum(case
  when dd.service_provider_assignment = d.service_provider_assignment
  then 1 end)
as same_assignment,
sum(case
  when dd.service_provider_assignment != d.service_provider_assignment and dd.service_provider_assignment is not null
  then 1 end)
as different_assignment

from public.fy2017_districts_deluxe_matr dd

inner join public.fy2016_districts_deluxe_matr d
on d.esh_id = dd.esh_id

where dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true
and d.service_provider_assignment in ('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')

group by d.service_provider_assignment

/*

Author: Jamie Barnes
Date: 8/4/2017
Purpose: This is to track what happened to the districts that had one of the "Top 15" service providers we called out in SotS 2016 
with the intent of highlighting which truly lost districts and which have districts that have not been cleaned yet

*/