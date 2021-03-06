select distinct
	dpd.esh_id,
	nces_cd,
	name,
	union_code,
	state_senate_district,
	state_assembly_district,
	ulocal,
	locale,
	district_size,
	ia_oversub_ratio,
	district_type,
	num_schools,
	num_campuses,
	num_students,
	frl_percent,
	discount_rate_c1,
	discount_rate_c2,
	address,
	city,
	zip,
	county,
	dpd.postal_cd,
	latitude,
	longitude,
	dpd.exclude_from_ia_analysis,
	exclude_from_ia_cost_analysis,
	dpd.exclude_from_wan_analysis,
	exclude_from_wan_cost_analysis,
	case
	    when  fbts.fiber_target_status in ('Target', 'Not Target')
	          or (fbts.fiber_target_status = 'Potential Target'
	            and dpd.exclude_from_ia_analysis = false)
	          or (fbts.fiber_target_status = 'No Data'
	            and num_campuses <= 2)
	    	then false
	   	else true
	end as exclude_from_current_fiber_analysis,
	include_in_universe_of_districts,
	flag_array,
	tag_array,
	num_open_district_flags,
	clean_categorization,
	ia_bandwidth_per_student_kbps,
	meeting_2014_goal_no_oversub,
	meeting_2014_goal_oversub,
	meeting_2014_goal_no_oversub_fcc_25,
	meeting_2018_goal_no_oversub,
	meeting_2018_goal_oversub,
	meeting_2018_goal_no_oversub_fcc_25,
	at_least_one_line_not_meeting_broadband_goal,
	bw_upgrade_indicator,
	ia_monthly_cost_per_mbps,
	ia_bw_mbps_total,
	ia_monthly_cost_total,
	ia_monthly_cost_direct_to_district,
	ia_monthly_cost_shared,
	wan_monthly_cost_per_line,
	wan_monthly_cost_total,
	meeting_3_per_mbps_affordability_target,
	hierarchy_ia_connect_category,
	all_ia_connectcat,
	case
	  when    dpd.exclude_from_ia_analysis = false
	          and fbts.fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses = 0
	          and non_fiber_lines > 0
	    then 0
	  when    dpd.exclude_from_ia_analysis = false
	          and fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses > 0
	  	then current_known_scalable_campuses
	  when fbts.fiber_target_status in ('Target', 'No Data')
	    then 0
	  when fbts.fiber_target_status = 'Not Target'
	    then 0
	  else current_known_scalable_campuses
	end as current_known_scalable_campuses,
	case
	  when    dpd.exclude_from_ia_analysis = false
	          and fbts.fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses = 0
	          and non_fiber_lines > 0
	    then 	case
		    		when non_fiber_lines > num_campuses
		    			then 0
		    		else num_campuses - non_fiber_lines
		    	end
	  when    dpd.exclude_from_ia_analysis = false
	          and fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses > 0
	  	then  current_assumed_scalable_campuses
	  when    fbts.fiber_target_status in ('Target', 'No Data')
	          and num_campuses = 1
	    then 0
	  when    fbts.fiber_target_status in ('Target', 'No Data')
	          and num_campuses = 2
	    then 1
	  when    fbts.fiber_target_status in ('Target', 'No Data')
	    then num_campuses::numeric * .66
	  when fbts.fiber_target_status = 'Not Target'
	    then num_campuses
	  else current_assumed_scalable_campuses
	end as current_assumed_scalable_campuses,
	case
	  when    dpd.exclude_from_ia_analysis = false
	          and fbts.fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses = 0
	          and non_fiber_lines > 0
	    then 0
	  when    dpd.exclude_from_ia_analysis = false
	          and fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses > 0
	  	then  current_known_unscalable_campuses
	  when    fbts.fiber_target_status in ('Target', 'No Data', 'Not Target')
	    then 0
	  else current_known_unscalable_campuses
	end as current_known_unscalable_campuses,
	case
	  when    dpd.exclude_from_ia_analysis = false
	          and fbts.fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses = 0
	          and non_fiber_lines > 0
	    then 	case
		    		when non_fiber_lines > num_campuses
		    			then num_campuses
		    		else non_fiber_lines
		    	end
	  when    dpd.exclude_from_ia_analysis = false
	          and fiber_target_status = 'Target'
	          and current_known_unscalable_campuses +
	              current_assumed_unscalable_campuses > 0
	  	then  current_assumed_unscalable_campuses
	  when    fbts.fiber_target_status in ('Target', 'No Data')
	          and num_campuses in (1,2)
	    then 1
	  when    fbts.fiber_target_status in ('Target', 'No Data')
	    then num_campuses::numeric * .34
	  when fbts.fiber_target_status = 'Not Target'
	    then 0
	  else current_assumed_unscalable_campuses
	end as current_assumed_unscalable_campuses,
	sots_known_scalable_campuses,
	sots_assumed_scalable_campuses,
	sots_known_unscalable_campuses,
	sots_assumed_unscalable_campuses,
	fiber_internet_upstream_lines,
	fixed_wireless_internet_upstream_lines,
	cable_internet_upstream_lines,
	copper_internet_upstream_lines,
	satellite_lte_internet_upstream_lines,
	uncategorized_internet_upstream_lines,
	wan_lines,
	wan_bandwidth_low,
	wan_bandwidth_high,
	gt_1g_wan_lines,
	lt_1g_fiber_wan_lines,
	lt_1g_nonfiber_wan_lines,
    consortium_affiliation,
    ia_procurement_type,
	ia_applicants,
	dedicated_isp_sp,
	dedicated_isp_services,
	dedicated_isp_contract_expiration,
	bundled_internet_sp,
	bundled_internet_services,
	bundled_internet_contract_expiration,
	upstream_sp,
	upstream_services,
	upstream_contract_expiration,
	wan_applicants,
	wan_sp,
	wan_services,
	wan_contract_expiration,
	non_fiber_lines,
    non_fiber_lines_w_dirty,
    non_fiber_internet_upstream_lines_w_dirty,
    fiber_internet_upstream_lines_w_dirty,
    fiber_wan_lines_w_dirty,
	lines_w_dirty,
	line_items_w_dirty,
	fiber_wan_lines,
	most_recent_ia_contract_end_date,
  	ia_monthly_cost_no_backbone,
	needs_wifi,
	c2_prediscount_budget_15,
	c2_prediscount_remaining_15,
	c2_prediscount_remaining_16,
	c2_postdiscount_remaining_15,
	c2_postdiscount_remaining_16,
	received_c2_15,
	received_c2_16,
	budget_used_c2_15,
	budget_used_c2_16,
	fbts.fiber_target_status,
  	fbts.bw_target_status

from public.fy2016_districts_predeluxe dpd
left join public.fy2016_fiber_bw_target_status fbts
on dpd.esh_id = fbts.esh_id

/*
Author: Justine Schott
Created On Date: 8/15/2016
Last Modified Date: 11/10/2016
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting assumptions built in
Methodology:
*/