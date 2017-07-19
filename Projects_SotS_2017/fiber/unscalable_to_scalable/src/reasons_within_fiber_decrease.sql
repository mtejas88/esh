with dist_2016 as (
	select *,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses
	from fy2016_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

dist_2017 as (
	select *,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
)

select
	case
	  when dist_2016.fiber_target_status = 'Target'
	    then 'Target'
	  else 'any other'
	end as target_2016,
	case
		when dist_2017.upgrade_indicator
			then 'bw_upgrade'
		when dist_2017.gt_1g_wan_lines > dist_2016.gt_1g_wan_lines 
			then 'more_high_bw_wan_lines'
		when dist_2017.wan_lines > dist_2016.wan_lines 
			then 'more_wan_lines'
		else 'unknown'
	end as reason,
	count(*)
from dist_2016
full outer join dist_2017
on dist_2016.esh_id = dist_2017.esh_id
where dist_2017.fiber_target_status = 'Not Target'
and dist_2016.fiber_target_status is not null
and dist_2016.unscalable_campuses > 0
group by 1, 2