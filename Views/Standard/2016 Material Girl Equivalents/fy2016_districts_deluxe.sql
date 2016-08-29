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
		when flag_array is null and district_type = 'Traditional' --note, on 8/16 flagging is not compatible with charters or BIEs
			then false
		else true
	end as exclude_from_analysis,
	case
		when flag_array is null and ia_monthly_cost_per_mbps is not null and district_type = 'Traditional'
			then 'clean_with_cost'
		when flag_array is null and district_type = 'Traditional' --note, on 8/16 flagging is not compatible with charters or BIEs
			then 'clean_no_cost'
		else 'dirty'
	end	as inclusion_status,
	flag_array,
	tag_array,
	flag_count as num_open_district_flags,
	case
		when flag_array is not null or district_type != 'Traditional' --note, on 8/16 flagging is not compatible with charters or BIEs
		--add further dimensioning of natively vs outreach needed? will dqs want to use this filter?
			then 'dirty'
		when 'outreach_confirmed' = any(tag_array)
			then  'outreach_confirmed'
		when 'line_items_outreach_confirmed' = any(tag_array)
			then 'line_items_outreach_confirmed'
		when 'outreach_confirmed_auto' = any(tag_array)
			then 'line_items_verified'
		when 'dqt_reviewed' = any(tag_array)
			then 'dqt_reviewed'
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
	nga_v2_known_scalable_campuses as nga_known_scalable_campuses,
	nga_v2_assumed_scalable_campuses as nga_assumed_scalable_campuses,
	nga_v2_known_unscalable_campuses as nga_known_unscalable_campuses,
	nga_v2_assumed_unscalable_campuses as nga_assumed_unscalable_campuses,
	known_scalable_campuses as sots_known_scalable_campuses,
	assumed_scalable_campuses as sots_assumed_scalable_campuses,
	known_unscalable_campuses as sots_known_unscalable_campuses,
	assumed_unscalable_campuses as sots_assumed_unscalable_campuses,
	known_fiber_campuses,
	assumed_nonfiber_campuses,
	known_fiber_campuses,
	assumed_nonfiber_campuses,
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
	null as consortium_name,
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
	non_fiber_lines

from public.fy2016_districts_metrics

/*
Author: Justine Schott
Created On Date: 8/15/2016
Last Modified Date: 8/26/2016
Name of QAing Analyst(s): 
Purpose: 2015 and 2016 district data in terms of 2016 methodology for longitudinal analysis
Methodology: NOTE-- WIP -- need to merge 2015 districts and 2016 districts
*/