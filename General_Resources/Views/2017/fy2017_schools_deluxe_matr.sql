with state_level_extrap as (

  select sm.postal_cd,

  (sum(sm.current_known_unscalable_campuses) + sum(sm.current_assumed_unscalable_campuses))/sum(sm.num_campuses) as extrap_percent

  from public.fy2017_schools_metrics_matr sm
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
   		--exclude districts that are dirty unless the only flag is 'DQT_VETO'
   		--these should be excluded still at a district level, but are fine at the campus level
   		when (dd.exclude_from_ia_analysis = false or array_to_string(dd.flag_array,';') = 'dqt_veto')
   		--exclude campuses with no bandwidth
   		and sm.ia_bandwidth_per_student_kbps > 0
   		--exclude campuses with only ISP
   		and sm.upstream_bandwidth + sm.internet_bandwidth > 0
			then false
		else true
   end as exclude_from_ia_analysis,
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
	sm.ia_monthly_cost_no_backbone,
	case

		when sm.ia_bandwidth::integer > 0

			then affordability_calculator(sm.ia_monthly_cost::integer, sm.ia_bandwidth::integer)

		else false

	end as meeting_knapsack_affordability_target,

spa.reporting_name as service_provider_assignment,
spa.primary_sp_purpose as primary_sp_purpose,
spa.primary_sp_bandwidth as primary_sp_bandwidth,
spa.primary_sp_percent_of_bandwidth as primary_sp_percent_of_bandwidth

from public.fy2017_schools_metrics_matr sm
left join public.fy2017_districts_deluxe_matr dd
on sm.district_esh_id = dd.esh_id

left join state_level_extrap sle
on sle.postal_cd = sm.postal_cd

left join (
select  recipient_sp_bw_rank.recipient_id as campus_id, 
reporting_name, 
recipient_sp_bw_rank.purpose_list as primary_sp_purpose,
recipient_sp_bw_rank.bandwidth as primary_sp_bandwidth,
recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total as primary_sp_percent_of_bandwidth

  from (
    select  *,
            row_number() over (partition by recipient_id order by bandwidth desc ) as bw_rank
    from (
      select  recipient_id,
              case

                when reporting_name = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when reporting_name = 'Zayo'

                  then 'Zayo Group, LLC'

                when reporting_name = 'CenturyLink Qwest'

                  then 'CenturyLink'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                when reporting_name is null then service_provider_name
                else reporting_name

              end as reporting_name,
              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,
              sum(case
                    when purpose = 'Upstream'
                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district
                    else 0
                  end) as upstream_bandwidth,
              array_agg(distinct purpose order by purpose) as purpose_list
      from public.fy2017_school_services_received_matr sr
      where purpose in ('Upstream', 'Internet')
      and inclusion_status in ('clean_with_cost', 'clean_no_cost')
      and recipient_include_in_universe_of_districts
      and recipient_exclude_from_ia_analysis = false
      group by 1,2
    )recipient_sp_bw
  ) recipient_sp_bw_rank
  left join (
    select  recipient_id,
            sum(bandwidth) as bw_total
    from (
      select  recipient_id,
              case

                when reporting_name = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when reporting_name = 'Zayo'

                  then 'Zayo Group, LLC'

                when reporting_name = 'CenturyLink Qwest'

                  then 'CenturyLink'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                when reporting_name is null then service_provider_name
                else reporting_name

              end as reporting_name,
              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,
              sum(case
                    when purpose = 'Upstream'
                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district
                    else 0
                  end) as upstream_bandwidth
      from public.fy2017_school_services_received_matr sr
      where purpose in ('Upstream', 'Internet')
      and inclusion_status in ('clean_with_cost', 'clean_no_cost')
      and recipient_include_in_universe_of_districts
      and recipient_exclude_from_ia_analysis = false
      group by 1,2
    )recipient_sp_bw

    group by 1
  ) recipient_sp_bw_total
  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id
  where bw_rank = 1
  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5
) spa

on sm.campus_id = spa.campus_id

/*
Author: Jess Seok
Created On Date: 11/29/2016
Last Modified Date: 9/15/2017 -- jh got rid of some fields
Name of QAing Analyst(s):Justine Schott
*/