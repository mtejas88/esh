with state_level_extrap as (

  select sm.postal_cd,

  (sum(sm.current_known_unscalable_campuses) + sum(sm.current_assumed_unscalable_campuses))/sum(sm.num_campuses) as extrap_percent

  from sm
  left join public.fy2017_districts_deluxe_matr dd
  on sm.district_esh_id = dd.esh_id

  where dd.include_in_universe_of_districts = true

  and dd.district_type = 'Traditional'

  and dd.fiber_metric_calc_group = 'metric_extrapolation'
  and dd.postal_cd in ('RI', 'HI', 'DE')

  group by sm.postal_cd)

select
	distinct
   sm.campus_id,
   sm.school_esh_ids,
   sm.district_esh_id,
   dd.name as district_name,
   sm.postal_cd,
   sm.num_students,
   sm.num_schools,
   sm.num_campuses,
   sm.frl_percent,
   dd.fiber_target_status as district_fiber_target_status,
   dd.bw_target_status as district_bw_target_status,
   case
   		when dd.exclude_from_ia_analysis = false 
   		--exclude campuses with no bandwidth
   		and sm.ia_bandwidth_per_student_kbps > 0
   		--exclude campuses with only ISP
   		and sm.upstream_bandwidth + sm.internet_bandwidth > 0
			then false
		else true
   end as exclude_from_ia_analysis,
   case
   		when dd.exclude_from_current_fiber_analysis = false
			then false
		else true
   end as exclude_from_current_fiber_analysis,
	sm.ia_bandwidth_per_student_kbps,
	case
		when sm.ia_bandwidth_per_student_kbps >= 100
			then true
		when sm.ia_bandwidth_per_student_kbps < 100
			then false
	end as meeting_2014_goal_no_oversub,
	case
    	when sm.ia_bandwidth_per_student_kbps >= 100
      	and broadband_internet_upstream_lines > 0
      		then TRUE
    	when sm.ia_bandwidth_per_student_kbps < 100
    	or broadband_internet_upstream_lines = 0
    	or broadband_internet_upstream_lines is null
      		then FALSE
	end as meeting_2014_goal_no_oversub_fcc_25,
	case
		when not_broadband_internet_upstream_lines > 0
			then true
		else false
	end as at_least_one_line_not_meeting_broadband_goal,
	sm.ia_monthly_cost_per_mbps,
	ia_bandwidth as ia_bw_mbps_total,
	ia_monthly_cost as ia_monthly_cost_total,
	sm.ia_monthly_cost_direct_to_district,
	sm.ia_monthly_cost_shared,
	case
		when sm.ia_monthly_cost_per_mbps <= 3
			then true
		when sm.ia_monthly_cost_per_mbps > 3
			then false
	end as meeting_3_per_mbps_affordability_target,
	case
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses = 0
	          and sm.non_fiber_lines > 0
	    then 0
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses > 0
	  	then sm.current_known_scalable_campuses
	  when dd.fiber_target_status in ('Target', 'No Data')
	    then 0
	  when dd.fiber_target_status = 'Not Target'
	    then 0
	  when fiber_metric_calc_group = 'extrapolate_to'
	  	then 0 
	  else sm.current_known_scalable_campuses
	end as current_known_scalable_campuses,
	case
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses = 0
	          and sm.non_fiber_lines > 0
	    then 	case
		    		when sm.non_fiber_lines > 1
		    			then 0
		    		else 1 - sm.non_fiber_lines
		    	end
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses > 0
	  	then  sm.current_assumed_scalable_campuses
	  when    dd.fiber_target_status in ('Target', 'No Data')
	          and dd.num_campuses = 1
	    then 0
	  when    dd.fiber_target_status in ('Target', 'No Data')
	          and dd.num_campuses = 2
	    then .5
	  when    dd.fiber_target_status in ('Target', 'No Data')
	    then .66
	  when dd.fiber_target_status = 'Not Target'
	    then 1
	  when fiber_metric_calc_group = 'extrapolate_to'
	  	then (sm.num_campuses * (1-extrap_percent))
	  else sm.current_assumed_scalable_campuses
	end as current_assumed_scalable_campuses,
	case
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses = 0
	          and sm.non_fiber_lines > 0
	    then 0
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses > 0
	  	then  sm.current_known_unscalable_campuses
	  when    dd.fiber_target_status in ('Target', 'No Data', 'Not Target')
	    then 0
	  when fiber_metric_calc_group = 'extrapolate_to'
	  	then 0 
	  else sm.current_known_unscalable_campuses
	end as current_known_unscalable_campuses,
	case
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses = 0
	          and sm.non_fiber_lines > 0
	    then 	case
		    		when sm.non_fiber_lines > 1
		    			then 1
		    		else sm.non_fiber_lines
		    	end
	  when    dd.exclude_from_ia_analysis = false
	          and dd.fiber_target_status = 'Target'
	          and sm.current_known_unscalable_campuses +
	              sm.current_assumed_unscalable_campuses > 0
	  	then  sm.current_assumed_unscalable_campuses
	  when    dd.fiber_target_status in ('Target', 'No Data')
	          and dd.num_campuses = 1
	    then 1
	  when    dd.fiber_target_status in ('Target', 'No Data')
	          and dd.num_campuses = 2
	    then .5
	  when    dd.fiber_target_status in ('Target', 'No Data')
	    then .34
	  when dd.fiber_target_status = 'Not Target'
	    then 0
	  when fiber_metric_calc_group = 'extrapolate_to'
	  	then (sm.num_campuses * (extrap_percent))
	  else sm.current_assumed_unscalable_campuses
	end as current_assumed_unscalable_campuses,
	sm.wan_lines,
	sm.ia_monthly_cost_no_backbone

from public.fy2017_schools_metrics_matr sm
left join public.fy2017_districts_deluxe_matr dd
on sm.district_esh_id = dd.esh_id

left join state_level_extrap sle

on sle.postal_cd = sm.postal_cd

/*
Author: Jess Seok
Created On Date: 11/29/2016
Last Modified Date: 7/31/2017 -- copied from fy2016_schools_deluxe
Name of QAing Analyst(s):Justine Schott
*/