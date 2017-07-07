select distinct

	dm.esh_id,

	nces_cd,

	name,

	union_code,

	null as state_senate_district,

	null as state_assembly_district,

	ulocal,

	locale,

	district_size,

	ia_oversub_ratio,

	district_type,

	num_schools,

	num_campuses,

	num_students,

	num_teachers,

	num_aides,

	num_other_staff,

	frl_percent,

	/*discount_rate_c1::numeric/100 as discount_rate_c1,

	discount_rate_c2::numeric/100 as discount_rate_c2,

	c2_discount_rate_for_remaining_budget as discount_rate_c2_for_remaining_budget,*/ -- commenting out as c2 funding view is not ready

	address,

	city,

	zip,

	county,

	dm.postal_cd,

	latitude,

	longitude,

	case
	
	when
	(flag_count = 1 and array_to_string(flag_array,',') ilike '%missing_wan%') or
	(flag_count = 1 and array_to_string(flag_array,',') ilike '%dirty_wan%') or
	(flag_count = 2 and array_to_string(flag_array,',') ilike '%missing_wan%') 
	and (array_to_string(flag_array,',') ilike '%dirty_wan%')

		/*when  	(flag_array is null or

				    (flag_count = 1 and array_to_string(flag_array,',') ilike '%missing_wan%'))*/ -- new changes based on flags 

            and ia_bandwidth_per_student_kbps > 0

			then false

		else true

	end as exclude_from_ia_analysis,

	case

	when 

	(flag_count = 1 and array_to_string(flag_array,',') ilike '%missing_wan%') or
	(flag_count = 1 and array_to_string(flag_array,',') ilike '%dirty_wan%') or
	(flag_count = 2 and array_to_string(flag_array,',') ilike '%missing_wan%') 
	and (array_to_string(flag_array,',') ilike '%dirty_wan%')


		/*when 	(flag_array is null or

				(flag_count = 1 and array_to_string(flag_array,',') ilike '%missing_wan%'))*/ -- new changes based on flags 

				and ia_no_cost_lines = 0

				and ia_bandwidth > 0

			then false

		else true

	end as exclude_from_ia_cost_analysis,

	case

		when 	flag_array is null

			then false

		else true

	end as exclude_from_wan_analysis,

	case

		when 	flag_array is null

				and wan_no_cost_lines = 0

				and wan_lines_w_dirty > 0

			then false

		else true

	end as exclude_from_wan_cost_analysis,

	include_in_universe_of_districts,

	include_in_universe_of_districts_all_charters,

	flag_array,

	tag_array,

	flag_count as num_open_district_flags,

	case

when
			(flag_count = 1 and array_to_string(flag_array,',') ilike '%missing_wan%') or
			(flag_count = 1 and array_to_string(flag_array,',') ilike '%dirty_wan%') or
			(flag_count = 2 and array_to_string(flag_array,',') ilike '%missing_wan%') 
			and (array_to_string(flag_array,',') ilike '%dirty_wan%')

				/*flag_count = 1 and array_to_string(flag_array,',') 
				ilike '%missing_wan%')-- commenting out due to new flag logic (see above)*/
				
			then 'dirty'

		when 'outreach_confirmed' = any(tag_array)

			then  'outreach_confirmed'

		when 'line_items_outreach_confirmed' = any(tag_array)

			then 'line_items_outreach_confirmed'

		when 'outreach_confirmed_auto' = any(tag_array)

			then 'line_items_verified'

		when 'dqt_reviewed' = any(tag_array)

			then 'dqt_reviewed'

		when machine_cleaned_lines > 0

			then 'machine_cleaned'

		else 'natively_clean'

	end as clean_categorization,

	ia_bandwidth_per_student_kbps,

	case

		when ia_bandwidth_per_student_kbps >= 100

			then true

		when ia_bandwidth_per_student_kbps < 100

			then false

	end as meeting_2014_goal_no_oversub,

	case

		when ia_bandwidth_per_student_kbps*ia_oversub_ratio >= 100

			then true

		when ia_bandwidth_per_student_kbps*ia_oversub_ratio < 100

			then false

	end as meeting_2014_goal_oversub,

	case

    	when ia_bandwidth_per_student_kbps >= 100

      	and broadband_internet_upstream_lines > 0

      		then TRUE

    	when ia_bandwidth_per_student_kbps < 100

    	or broadband_internet_upstream_lines = 0

    	or broadband_internet_upstream_lines is null

      		then FALSE

	end as meeting_2014_goal_no_oversub_fcc_25,

	case

		when ia_bandwidth_per_student_kbps >= 1000

			then true

		when ia_bandwidth_per_student_kbps < 1000

			then false

	end as meeting_2018_goal_no_oversub,

	case

		when ia_bandwidth_per_student_kbps*ia_oversub_ratio >= 1000

			then true

		when ia_bandwidth_per_student_kbps*ia_oversub_ratio < 1000

			then false

	end as meeting_2018_goal_oversub,

	case

    	when ia_bandwidth_per_student_kbps >= 1000

      	and broadband_internet_upstream_lines > 0

      		then TRUE

    	when ia_bandwidth_per_student_kbps < 1000

    	or broadband_internet_upstream_lines = 0

    	or broadband_internet_upstream_lines is null

      		then FALSE

	end as meeting_2018_goal_no_oversub_fcc_25,

	case

		when not_broadband_internet_upstream_lines > 0

			then true

		else false

	end as at_least_one_line_not_meeting_broadband_goal,

	ia_monthly_cost_per_mbps,

	ia_bandwidth as ia_bw_mbps_total,

	ia_monthly_cost as ia_monthly_cost_total,

	ia_monthly_cost_direct_to_district,

	ia_monthly_cost_shared,

	wan_monthly_cost_per_line,

	wan_monthly_cost as wan_monthly_cost_total,

	case

		when ia_monthly_cost_per_mbps <= 3

			then true

		when ia_monthly_cost_per_mbps > 3

			then false

	end as meeting_3_per_mbps_affordability_target,

	hierarchy_connect_category as hierarchy_ia_connect_category,

	all_ia_connectcat,

	current_known_scalable_campuses,

	current_assumed_scalable_campuses,

	current_known_unscalable_campuses,

	current_assumed_unscalable_campuses,

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

	/*CASE 	WHEN wifi.count_wifi_needed > 0 THEN true

   			WHEN wifi.count_wifi_needed = 0 THEN false

        	ELSE null

		   	END as needs_wifi,*/

	/*c2_prediscount_budget_15,

	c2_prediscount_remaining_15,

	c2_prediscount_remaining_16,

	c2_postdiscount_remaining_15,

	c2_postdiscount_remaining_16,

	received_c2_15,

	received_c2_16,

	budget_used_c2_15,

	budget_used_c2_16,*/ -- commenting out as c2 funding view is not ready

	wan_lines_w_dirty,

	ia_monthly_cost_district_applied,

	ia_monthly_cost_other_applied,

	ia_monthly_funding_total




from public.fy2017_districts_metrics_matr dm

left join public.fy2017_wifi_connectivity_informations_matr wifi

on dm.esh_id::varchar = wifi.parent_entity_id::varchar 

/*left join public.fy2017_districts_c2_funding_matr c2

on dm.esh_id = c2.esh_id::varchar*/ -- commenting out as c2 funding view is not ready




/*

Author: Justine Schott

Created On Date: 12/1/2016

Last Modified Date: 3/17/2017 -- include_in_universe_of_districts_all_charters, remove bw_upgrade_indicator

Name of QAing Analyst(s):

Purpose: 2016 district data in terms of 2016 methodology for longitudinal analysis

Methodology:

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise

*/
