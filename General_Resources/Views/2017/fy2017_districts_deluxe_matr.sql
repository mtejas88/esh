with state_level_extrap as (

	select postal_cd,

	(sum(current_known_unscalable_campuses) + sum(current_assumed_unscalable_campuses))/sum(num_campuses) as extrap_percent

	from fy2017_districts_fiberpredeluxe_matr

	where include_in_universe_of_districts = true

	and district_type = 'Traditional'

	and fiber_metric_calc_group = 'metric_extrapolation'

	group by postal_cd)


select distinct

	esh_id,

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

	num_teachers,

	num_aides,

	num_other_staff,

	frl_percent,

	discount_rate_c1,

	discount_rate_c2,

	address,

	city,

	zip,

	county,

	dfpd.postal_cd,

	latitude,

	longitude,

	exclude_from_ia_analysis,

	exclude_from_ia_cost_analysis,

	exclude_from_wan_analysis,

	exclude_from_wan_cost_analysis,

	exclude_from_current_fiber_analysis,

	fiber_metric_calc_group,

	fiber_metric_status,

	include_in_universe_of_districts,

	include_in_universe_of_districts_all_charters,

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

	ia_monthly_cost_per_mbps,

	ia_bw_mbps_total,

	ia_monthly_cost_total,

	ia_monthly_cost_direct_to_district,

	ia_monthly_cost_shared,

	wan_monthly_cost_per_line,

	wan_monthly_cost_total,

	meeting_3_per_mbps_affordability_target,

	meeting_knapsack_affordability_target,

	hierarchy_ia_connect_category,

	all_ia_connectcat,

	case

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type = 'Traditional' --adding district_type logic to cater for SOTS for now, per Justine

		then 0

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type not in ('Traditional')

		then null

		else current_known_scalable_campuses

	end as current_known_scalable_campuses,

	case

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type = 'Traditional'  --adding district_type logic to cater for SOTS for now, per Justine

		then (num_campuses * (1-extrap_percent))

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type not in ('Traditional')
		then null

		else current_assumed_scalable_campuses

	end as 	current_assumed_scalable_campuses,

	case

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type = 'Traditional'  --adding district_type logic to cater for SOTS for now, per Justine

		then 0

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type not in ('Traditional')
		then null

		else current_known_unscalable_campuses

	end as current_known_unscalable_campuses,

	case

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type = 'Traditional'  --adding district_type logic to cater for SOTS for now, per Justine

		then (num_campuses * extrap_percent)

		when fiber_metric_calc_group = 'extrapolate_to'
		and district_type not in ('Traditional')
		then null -- adding this logic in all extrapolate to instances to add the logic for district types that are not traditional

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

	wan_lines_w_dirty,

  	ia_monthly_cost_no_backbone,

  	backbone_monthly_cost,

	needs_wifi,

	c2_prediscount_budget_15, 

	c2_prediscount_remaining_15, 

	c2_prediscount_remaining_16,

	c2_prediscount_remaining_17,

	c2_postdiscount_remaining_15, 

	c2_postdiscount_remaining_16,

	c2_postdiscount_remaining_17,

	received_c2_15, 

	received_c2_16,

	received_c2_17,

	budget_used_c2_15, 

	budget_used_c2_16,

	budget_used_c2_17,

	fiber_target_status,

  	bw_target_status,

	upgrade_indicator,

	ia_monthly_cost_district_applied,

	ia_monthly_cost_other_applied,

	ia_monthly_funding_total,

	service_provider_assignment,

	primary_sp_purpose,

	primary_sp_bandwidth,

	primary_sp_percent_of_bandwidth

from fy2017_districts_fiberpredeluxe_matr dfpd

left join state_level_extrap sle

on sle.postal_cd = dfpd.postal_cd







/*
Author: Justine Schott, Jamie Barnes
Created On Date: 8/15/2016
Last Modified Date: 6/5/2017 -- JH added 2017 wifi fields
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting and fiber metric extrapolation assumptions built in
Methodology:
*/
