select
	esh_id,
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
	frl_percent,
	discount_rate_c1,
	discount_rate_c2,
	address,
	city,
	zip,
	county,
	postal_cd,
	latitude,
	longitude,
	case
		when  	(flag_array is null or
				    (flag_count = 1 and array_to_string(flag_array,',') ilike '%wan%'))
            and ia_bandwidth_per_student_kbps > 0
			then false
		else true
	end as exclude_from_ia_analysis,
	case
		when 	(flag_array is null or
				(flag_count = 1 and array_to_string(flag_array,',') ilike '%wan%'))
				and ia_no_cost_lines = 0
				and ia_monthly_cost > 0
				and ia_monthly_cost_per_mbps > 0
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
				and wan_monthly_cost > 0
				and wan_monthly_cost_per_line > 0
			then false
		else true
	end as exclude_from_wan_cost_analysis,
	include_in_universe_of_districts,
	flag_array,
	tag_array,
	flag_count as num_open_district_flags,
	case
		when 	(flag_array is not null or
				flag_count = 1 and array_to_string(flag_array,',') ilike '%wan%')
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
	fiber_wan_lines,
	most_recent_ia_contract_end_date,
  ia_monthly_cost_no_backbone

from public.fy2016_districts_metrics_matr

/*
Author: Justine Schott
Created On Date: 8/15/2016
Last Modified Date: 10/17/2016
Name of QAing Analyst(s):
Purpose: 2015 and 2016 district data in terms of 2016 methodology for longitudinal analysis
Methodology:
*/