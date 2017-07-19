with dist_2016 as (
	select 
		esh_id,
		fiber_target_status as target_status_2016,
		fiber_metric_calc_group as fiber_metric_calc_group_2016,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses_2016
	from fy2016_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

dist_2017 as (
	select *,
		fiber_target_status as target_status_2017,
		fiber_metric_calc_group as fiber_metric_calc_group_2017,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses_2017
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
)

select
	case
	  when target_status_2016 = 'Target'
	    then 'Target'
	  else 'any other'
	end as target_2016,
	count(	case
		        when upgrade_indicator
		          then 1
		        else 0
	      	end)/count(	case
				        when exclude_from_ia_analysis = false
				          then 1
				        else 0
			      	end)::numeric as percent
from dist_2016
full outer join dist_2017
on dist_2016.esh_id = dist_2017.esh_id
where target_status_2017 = 'Not Target'
and target_status_2016 is not null
and unscalable_campuses_2016 > 0
group by 1

UNION

select
	'universe' as target_2016,
	sum(case
	        when upgrade_indicator
	          then 1
	        else 0
      	end)/count(	case
				        when exclude_from_ia_analysis = false
				          then 1
				        else 0
			      	end)::numeric as percent
from dist_2017
group by 1
