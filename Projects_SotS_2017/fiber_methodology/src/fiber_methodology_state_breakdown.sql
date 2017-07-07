select
	dd.postal_cd,
	sum(dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses) as num_unscalable_campuses,
	sum(dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses)/sum(dd.num_campuses) as pct_unscalable_campuses,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 
			sum(case
					when dd.fiber_target_status = 'Not Target'
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_not_target,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 
			sum(case
					when dd.fiber_target_status = 'Potential Target'
					and dd.exclude_from_ia_analysis = false
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses) 
	end as pct_unscalable_campuses_potential_target_clean,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 
			sum(case
					when dd.fiber_target_status = 'Potential Target'
					and dd.exclude_from_ia_analysis = true
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses) 
	end as pct_unscalable_campuses_potential_target_dirty,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'Target'
					and dd.exclude_from_ia_analysis = false
					and dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses = 
						dm.current_assumed_unscalable_campuses+dm.current_known_unscalable_campuses
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_target_clean_baseline_methodology,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'Target'
					and dd.exclude_from_ia_analysis = false
					and dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses != 
						dm.current_assumed_unscalable_campuses+dm.current_known_unscalable_campuses
					and dd.non_fiber_lines > 0
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_target_clean_non_fiber_lines,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'Target'
					and (
							(	dd.exclude_from_ia_analysis = false
								and dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses != 
									dm.current_assumed_unscalable_campuses+dm.current_known_unscalable_campuses
								and dd.non_fiber_lines = 0
							)
						or dd.exclude_from_ia_analysis = true
					) 
					and dd.num_campuses <= 2 
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_target_small_assump,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'Target'
					and (
							(	dd.exclude_from_ia_analysis = false
								and dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses != 
									dm.current_assumed_unscalable_campuses+dm.current_known_unscalable_campuses
								and dd.non_fiber_lines = 0
							)
						or dd.exclude_from_ia_analysis = true
					) 
					and dd.num_campuses > 2 
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_target_large_assump,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'No Data'
					and dd.num_campuses <= 2
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses)
	end as pct_unscalable_campuses_no_data_small_assump,
	case
		when sum(dd.num_campuses) = 0
			then 0
		else 	
			sum(case
					when dd.fiber_target_status = 'No Data'
					and dd.num_campuses > 2
						then dd.current_assumed_unscalable_campuses+dd.current_known_unscalable_campuses
					else 0
				end)/sum(dd.num_campuses) 
	end as pct_unscalable_campuses_no_data_large_assump, 
	sum(case
			when dd.fiber_target_status = 'Target'
				then 1
			else 0
		end) as num_districts_target, 
	sum(case
			when dd.fiber_target_status = 'Potential Target'
				then 1
			else 0
		end) as num_districts_potential_target, 
	sum(case
			when dd.fiber_target_status = 'No Data'
				then 1
			else 0
		end) as num_districts_no_data
from fy2016_districts_deluxe_matr dd
join fy2016_districts_metrics_matr dm
on dd.esh_id = dm.esh_id
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1
order by 1