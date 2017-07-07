select 
	dd16.fiber_target_status as fiber_target_status_16,
	dd17.fiber_target_status as fiber_target_status_17,
	count(*) as num_districts
from (
	select *
	from fy2016_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
) dd16
full outer join (
	select *
	from fy2017_districts_deluxe_matr 
	where include_in_universe_of_districts
	and district_type = 'Traditional'
) dd17
on dd16.esh_id = dd17.esh_id
group by 1,2