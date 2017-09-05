with base_2016 as (
select dd.* from 
public.fy2016_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'),

base_2017 as (
select dd.* from 
public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional')

select 
count(distinct case when base_2017.esh_id is null then base_2016.esh_id end) 
- count(distinct case when base_2016.esh_id is null then base_2017.esh_id end) as ndistricts_lost_net, 
sum(case when base_2017.esh_id is null then base_2016.num_students else 0 end) 
- sum(case when base_2016.esh_id is null then base_2017.num_students else 0 end) as num_students_lost_net,
sum(base_2016.num_students) as num_students_2016,
sum(base_2017.num_students) as num_students_2017
from base_2016
full outer join base_2017 
on base_2016.esh_id=base_2017.esh_id


