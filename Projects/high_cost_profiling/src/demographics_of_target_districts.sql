with targets as (
	select *
	from fy2016_districts_deluxe_matr dd
	where dd.include_in_universe_of_districts_all_charters
	and dd.fiber_target_status = 'Target'

)

select locale as category, count(*) as num_districts
from targets
group by 1

UNION

select district_size as category, count(*) as num_districts
from targets
group by 1