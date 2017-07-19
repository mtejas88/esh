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
	select
		esh_id,
		fiber_target_status as target_status_2017,
		fiber_metric_calc_group as fiber_metric_calc_group_2017,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses_2017
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
)

select
	case
	  when fiber_metric_calc_group_2017 = 'extrapolate_to'
	    then 'any'
	  when fiber_metric_calc_group_2017 is null
	    then 'any'
	  when (target_status_2017 = 'No Data' and (target_status_2016 != 'No Data' or target_status_2016 is null))
	  or (target_status_2016 = 'Not Target' and target_status_2017 != 'Not Target')
	  or (target_status_2016 = 'Target' and target_status_2017 = 'Potential Target')
	  	then 'any'
	  when target_status_2017 = 'Not Target' and target_status_2016 = 'Target'
	  	then 'target'
	  when target_status_2017 = 'Not Target'
	  	then 'any_other'
	  when target_status_2017 in ('Target', 'Potential Target') and target_status_2016 in ('Target', 'Potential Target') 
	  	then 'potential_or_target'
	  when target_status_2017 = 'No Data' and target_status_2016 = 'No Data'
	  	then 'no_data'
	  else 'no_data'
	end as status_2016,
	case
	  when fiber_metric_calc_group_2017 = 'extrapolate_to'
	    then 'cleaning_outstanding'
	  when fiber_metric_calc_group_2017 is null
	    then null
	  when (target_status_2017 = 'No Data' and (target_status_2016 != 'No Data' or target_status_2016 is null))
	  or (target_status_2016 = 'Not Target' and target_status_2017 != 'Not Target')
	  or (target_status_2016 = 'Target' and target_status_2017 = 'Potential Target')
	  	then 'cleaning_outstanding'
	  when target_status_2017 = 'Not Target' and target_status_2016 = 'Target'
	  	then 'not_target'
	  when target_status_2017 = 'Not Target'
	  	then 'not_target'
	  when target_status_2017 in ('Target', 'Potential Target') and target_status_2016 in ('Target', 'Potential Target') 
	  	then 'potential_or_target'
	  when target_status_2017 = 'No Data' and target_status_2016 = 'No Data'
	  	then 'no_data'
	  else 'potential_or_target'
	end as status_2017,
	sum(case
			when unscalable_campuses_2016 is null
				then 0
			else unscalable_campuses_2016
		end) as unscalable_campuses_2016,
	sum(case
			when unscalable_campuses_2017 is null
				then 0
			else unscalable_campuses_2017
		end) as unscalable_campuses_2017,
	sum(case
			when unscalable_campuses_2017 is null
				then 0
			else unscalable_campuses_2017
		end) - sum(	case
						when unscalable_campuses_2016 is null
							then 0
						else unscalable_campuses_2016
					end) as unscalable_campuses_drop
from dist_2016
full outer join dist_2017
on dist_2016.esh_id = dist_2017.esh_id
group by 1, 2,
	case
	  when fiber_metric_calc_group_2017 = 'extrapolate_to'
	    then 1
	  when fiber_metric_calc_group_2017 is null
	    then 2
	  when (target_status_2017 = 'No Data' and (target_status_2016 != 'No Data' or target_status_2016 is null))
	  or (target_status_2016 = 'Not Target' and target_status_2017 != 'Not Target')
	  or (target_status_2016 = 'Target' and target_status_2017 = 'Potential Target')
	  	then 1
	  when target_status_2017 = 'Not Target' and target_status_2016 = 'Target'
	  	then 3
	  when target_status_2017 = 'Not Target'
	  	then 4
	  when target_status_2017 in ('Target', 'Potential Target') and target_status_2016 in ('Target', 'Potential Target') 
	  	then 7
	  when target_status_2017 = 'No Data' and target_status_2016 = 'No Data'
	  	then 5
	  else 6
	end
order by 	
	case
	  when fiber_metric_calc_group_2017 = 'extrapolate_to'
	    then 1
	  when fiber_metric_calc_group_2017 is null
	    then 2
	  when (target_status_2017 = 'No Data' and (target_status_2016 != 'No Data' or target_status_2016 is null))
	  or (target_status_2016 = 'Not Target' and target_status_2017 != 'Not Target')
	  or (target_status_2016 = 'Target' and target_status_2017 = 'Potential Target')
	  	then 1
	  when target_status_2017 = 'Not Target' and target_status_2016 = 'Target'
	  	then 3
	  when target_status_2017 = 'Not Target'
	  	then 4
	  when target_status_2017 in ('Target', 'Potential Target') and target_status_2016 in ('Target', 'Potential Target') 
	  	then 7
	  when target_status_2017 = 'No Data' and target_status_2016 = 'No Data'
	  	then 5
	  else 6
	end
