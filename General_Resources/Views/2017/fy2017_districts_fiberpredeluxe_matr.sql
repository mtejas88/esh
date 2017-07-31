--district fiberpredeluxe


select distinct

	dpd.esh_id,

	dpd.nces_cd,

	dpd.name,

	dpd.union_code,

	dpd.state_senate_district,

	dpd.state_assembly_district,

	dpd.ulocal,

	dpd.locale,

	dpd.district_size,

	dpd.ia_oversub_ratio,

	dpd.district_type,

	dpd.num_schools,

	dpd.num_campuses,

	dpd.num_students,

	dpd.num_teachers,

	dpd.num_aides,

	dpd.num_other_staff,

	dpd.frl_percent,

	dpd.discount_rate_c1,

	dpd.discount_rate_c1_matrix,

	dpd.discount_rate_c2,

	dpd.address,

	dpd.city,

	dpd.zip,

	dpd.county,

	dpd.postal_cd,

	dpd.latitude,

	dpd.longitude,

	dpd.exclude_from_ia_analysis,

	dpd.exclude_from_ia_cost_analysis,

	dpd.exclude_from_wan_analysis,

	dpd.exclude_from_wan_cost_analysis,

	case

	    when  fbts.fiber_target_status in ('Target', 'Not Target')

	    	  or (fbts.fiber_target_status = 'No Data'

	            and dpd.num_campuses <= 2)

	          or (fbts.fiber_target_status = 'Potential Target'

	            and dpd.exclude_from_ia_analysis = false)

	    	then false

	   	else true

	end as exclude_from_current_fiber_analysis,

	case

	    when  dpd.exclude_from_ia_analysis = false

	    	then 'metric_extrapolation'

	   	when  fbts.fiber_target_status in ('Target', 'Not Target')

	    	  or (fbts.fiber_target_status = 'No Data'

	            and dpd.num_campuses <= 2)

	          or (fbts.fiber_target_status = 'Potential Target'

	            and dpd.exclude_from_ia_analysis = false)

	    	then 'metric'

	   	else 'extrapolate_to'

	end as fiber_metric_calc_group,

	case

	    when  dpd.exclude_from_ia_analysis = false and fbts.fiber_target_status = 'Target'

	    	then 'clean_target'

	    when  fbts.fiber_target_status = 'Target'

	    	then 'dirty_target'

	    when  dpd.exclude_from_ia_analysis = false and fbts.fiber_target_status = 'Not Target'

	    	then 'clean_not_target'

	    when  fbts.fiber_target_status = 'Not Target'

	    	then 'dirty_not_target'

	    when  dpd.current_known_unscalable_campuses + dpd.current_assumed_unscalable_campuses = 0

	    	  and dpd.exclude_from_ia_analysis = false

	    	  and fbts.fiber_target_status = 'Potential Target'

	    	then 'clean_no_unscalable_potential_target'

	    when  dpd.exclude_from_ia_analysis = false

	    	  and fbts.fiber_target_status = 'Potential Target'

	    	then 'clean_unscalable_potential_target'

	    when  fbts.fiber_target_status = 'Potential Target'

	    	then 'dirty_potential_target'

	   	when  dpd.num_campuses <= 2

	    	then 'small_no_data'

	   	else 'large_no_data'

	end as fiber_metric_status,

	dpd.include_in_universe_of_districts,

	dpd.include_in_universe_of_districts_all_charters,

	dpd.flag_array,

	dpd.tag_array,

	dpd.num_open_district_flags,

	dpd.clean_categorization,

	dpd.ia_bandwidth_per_student_kbps,

	dpd.meeting_2014_goal_no_oversub,

	dpd.meeting_2014_goal_oversub,

	dpd.meeting_2014_goal_no_oversub_fcc_25,

	dpd.meeting_2018_goal_no_oversub,

	dpd.meeting_2018_goal_oversub,

	dpd.meeting_2018_goal_no_oversub_fcc_25,

	dpd.at_least_one_line_not_meeting_broadband_goal,

	dpd.ia_monthly_cost_per_mbps,

	dpd.ia_bw_mbps_total,

	dpd.ia_monthly_cost_total,

	dpd.ia_monthly_cost_direct_to_district,

	dpd.ia_monthly_cost_shared,

	dpd.wan_monthly_cost_per_line,

	dpd.wan_monthly_cost_total,

	dpd.meeting_3_per_mbps_affordability_target,

	case

		when dpd.ia_bw_mbps_total::integer > 0

			then affordability_calculator(dpd.ia_monthly_cost_total::integer, dpd.ia_bw_mbps_total::integer)

		else false

	end as meeting_knapsack_affordability_target,

	dpd.hierarchy_ia_connect_category,

	dpd.all_ia_connectcat,

	case

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses = 0

	          and dpd.non_fiber_lines > 0

	    then 0

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses > 0

	  	then dpd.current_known_scalable_campuses

	  when fbts.fiber_target_status in ('Target', 'No Data')

	    then 0

	  when fbts.fiber_target_status = 'Not Target'

	    then 0

	  else dpd.current_known_scalable_campuses

	end as current_known_scalable_campuses,

	case

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses = 0

	          and dpd.non_fiber_lines > 0

	    then 	case

		    		when dpd.non_fiber_lines > dpd.num_campuses

		    			then 0

		    		else dpd.num_campuses - dpd.non_fiber_lines

		    	end

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses > 0

	  	then  dpd.current_assumed_scalable_campuses

	  when    fbts.fiber_target_status in ('Target', 'No Data')

	          and dpd.num_campuses = 1

	    then 0

	  when    fbts.fiber_target_status in ('Target', 'No Data')

	          and dpd.num_campuses = 2

	    then 1

	  when    fbts.fiber_target_status in ('Target', 'No Data')

	    then dpd.num_campuses::numeric * .66

	  when fbts.fiber_target_status = 'Not Target'

	    then dpd.num_campuses

	  else dpd.current_assumed_scalable_campuses

	end as current_assumed_scalable_campuses,

	case

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses = 0

	          and dpd.non_fiber_lines > 0

	    then 0

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses > 0

	  	then  dpd.current_known_unscalable_campuses

	  when    fbts.fiber_target_status in ('Target', 'No Data', 'Not Target')

	    then 0

	  else dpd.current_known_unscalable_campuses

	end as current_known_unscalable_campuses,

	case

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses = 0

	          and dpd.non_fiber_lines > 0

	    then 	case

		    		when dpd.non_fiber_lines > dpd.num_campuses

		    			then dpd.num_campuses

		    		else dpd.non_fiber_lines

		    	end

	  when    dpd.exclude_from_ia_analysis = false

	          and fbts.fiber_target_status = 'Target'

	          and dpd.current_known_unscalable_campuses +

	              dpd.current_assumed_unscalable_campuses > 0

	  	then  dpd.current_assumed_unscalable_campuses

	  when    fbts.fiber_target_status in ('Target', 'No Data')

	          and dpd.num_campuses in (1,2)

	    then 1

	  when    fbts.fiber_target_status in ('Target', 'No Data')

	    then dpd.num_campuses::numeric * .34

	  when fbts.fiber_target_status = 'Not Target'

	    then 0

	  else dpd.current_assumed_unscalable_campuses

	end as current_assumed_unscalable_campuses,

	dpd.sots_known_scalable_campuses,

	dpd.sots_assumed_scalable_campuses,

	dpd.sots_known_unscalable_campuses,

	dpd.sots_assumed_unscalable_campuses,

	dpd.fiber_internet_upstream_lines,

	dpd.fixed_wireless_internet_upstream_lines,

	dpd.cable_internet_upstream_lines,

	dpd.copper_internet_upstream_lines,

	dpd.satellite_lte_internet_upstream_lines,

	dpd.uncategorized_internet_upstream_lines,

	dpd.wan_lines,

	dpd.wan_bandwidth_low,

	dpd.wan_bandwidth_high,

	dpd.gt_1g_wan_lines,

	dpd.lt_1g_fiber_wan_lines,

	dpd.lt_1g_nonfiber_wan_lines,

    dpd.consortium_affiliation,

    dpd.ia_procurement_type,

	dpd.ia_applicants,

	dpd.dedicated_isp_sp,

	dpd.dedicated_isp_services,

	dpd.dedicated_isp_contract_expiration,

	dpd.bundled_internet_sp,

	dpd.bundled_internet_services,

	dpd.bundled_internet_contract_expiration,

	dpd.upstream_sp,

	dpd.upstream_services,

	dpd.upstream_contract_expiration,

	dpd.wan_applicants,

	dpd.wan_sp,

	dpd.wan_services,

	dpd.wan_contract_expiration,

	dpd.non_fiber_lines,

    dpd.non_fiber_lines_w_dirty,

    dpd.non_fiber_internet_upstream_lines_w_dirty,

    dpd.fiber_internet_upstream_lines_w_dirty,

    dpd.fiber_wan_lines_w_dirty,

	dpd.lines_w_dirty,

	dpd.line_items_w_dirty,

	dpd.fiber_wan_lines,

	dpd.most_recent_ia_contract_end_date,

	dpd.wan_lines_w_dirty,

  	dpd.ia_monthly_cost_no_backbone,

  	(dpd.ia_monthly_cost_total - dpd.ia_monthly_cost_no_backbone) as backbone_monthly_cost,

	dpd.needs_wifi,

	dpd.c2_prediscount_budget_15,

	dpd.c2_prediscount_remaining_15,

	dpd.c2_prediscount_remaining_16,

	dpd.c2_prediscount_remaining_17,

	dpd.c2_postdiscount_remaining_15,

	dpd.c2_postdiscount_remaining_16,

	dpd.c2_postdiscount_remaining_17,

	dpd.received_c2_15,

	dpd.received_c2_16,

	dpd.received_c2_17,

	dpd.budget_used_c2_15,

	dpd.budget_used_c2_16,

	dpd.budget_used_c2_17,

	fbts.fiber_target_status,

  	fbts.bw_target_status,

  	dpd.wifi_target_status,

  	case

  		when du.upgrade_indicator

  			then true

  		else false

  	end as upgrade_indicator,

	dpd.ia_monthly_cost_district_applied,

	dpd.ia_monthly_cost_other_applied,

	dpd.ia_monthly_funding_total,

	dspa.reporting_name as service_provider_assignment,

	dspa.primary_sp_purpose as primary_sp_purpose,

	dspa.primary_sp_bandwidth as primary_sp_bandwidth,

	dspa.primary_sp_percent_of_bandwidth as primary_sp_percent_of_bandwidth,

	case when dspa.reporting_name is not null and d16.service_provider_assignment is not null
	and dspa.reporting_name!=d16.service_provider_assignment then 'Switched' 
	when when dspa.reporting_name is not null and d16.service_provider_assignment is not null
	and dspa.reporting_name=d16.service_provider_assignment then 'Did Not Switch' 
	end as switcher





from public.fy2017_districts_predeluxe_matr dpd

left join public.fy2017_fiber_bw_target_status_matr fbts

on dpd.esh_id::varchar = fbts.esh_id::varchar

left join public.fy2016_fy2017_districts_upgrades_matr du

on dpd.esh_id::varchar = du.esh_id_2017::varchar --correcting year to 2017

left join public.fy2017_districts_service_provider_assignments_matr dspa

on dpd.esh_id::varchar = dspa.esh_id::varchar

left join public.fy2016_districts_deluxe_matr d16

on dpd.esh_id::varchar = d16.esh_id::varchar




/*
Author: Justine Schott
Created On Date: 8/15/2016
Last Modified Date: 7/11/2017 -- JH fixed affordability calculator to only take integers
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting assumptions built in but prior to fiber metric extrapolation
Methodology:
*/
