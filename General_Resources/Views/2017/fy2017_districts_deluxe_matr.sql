with state_level_extrap as (
	select postal_cd,
	(sum(current_known_unscalable_campuses) + sum(current_assumed_unscalable_campuses))/sum(num_campuses) as extrap_percent
	from fy2017_districts_fiberpredeluxe_matr
	where include_in_universe_of_districts = true
	and district_type = 'Traditional'
	and fiber_metric_calc_group = 'metric_extrapolation'
	group by postal_cd)

select distinct
	--basic demog info about district
	esh_id,
	nces_cd,
	name,
	address,
	city,
	dfpd.postal_cd,
	locale,
	district_size,
	district_type,
	include_in_universe_of_districts,
	num_schools,
	num_campuses,
	num_students,
	discount_rate_c1_matrix,
	discount_rate_c2,
	setda_concurrency_factor,
	latitude,
	longitude,

	--cleanliness
	exclude_from_ia_analysis,
	exclude_from_ia_cost_analysis,
	dfpd.exclude_from_wan_analysis,
	exclude_from_wan_cost_analysis,
	exclude_from_campus_analysis,
	num_open_district_flags,
	flag_array,
	tag_array,

	--targeting
	dfpd.fiber_target_status,
  	bw_target_status,
  	wifi_target_status,
  	needs_wifi,
  	wifi_suff_sots_17,

	--main metricts
	ia_bandwidth_per_student_kbps,
	ia_monthly_cost_per_mbps,
	ia_bw_mbps_total,
	ia_monthly_cost_total,
	meeting_2014_goal_no_oversub,
	meeting_2018_goal_no_oversub,
	case 
		when exclude_from_ia_analysis=false 
		 and ((ia_bw_mbps_total*1000)/num_students)/setda_concurrency_factor >= 1000 
		 	then true 
		when exclude_from_ia_analysis=false 
		 and ((ia_bw_mbps_total*1000)/num_students)/setda_concurrency_factor < 1000 
		 	then false
	end as meeting_2018_goal_oversub,
	projected_bw_fy2018_cck12,
	case
 	  when exclude_from_ia_analysis=false and projected_bw_fy2018_cck12 >= 1000 then true 
 	  when exclude_from_ia_analysis=false and projected_bw_fy2018_cck12 < 1000 then false
 	end as meeting_2018_goal_oversub_cck12,
	meeting_knapsack_affordability_target,
	
	--primary sp, upgrade, switcher, contract expiry
  	service_provider_assignment,
	upgrade_indicator,
	switcher,
	most_recent_ia_contract_end_date,

	--fiber details
	fiber_metric_calc_group,
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
	
	--more info network arch
	all_ia_connectcat,
	consortium_affiliation,
    ia_procurement_type,
	ia_applicants,
	hierarchy_ia_connect_category,

	--total lines
	lines_w_dirty,
	line_items_w_dirty,
	wan_lines_w_dirty,
	wan_lines,

	--fiber lines
	fiber_internet_upstream_lines_w_dirty,
	fiber_internet_upstream_lines,
	fiber_wan_lines_w_dirty,
	fiber_wan_lines,

	--non fiber lines
	non_fiber_lines,
    non_fiber_lines_w_dirty,
	non_fiber_internet_upstream_lines_w_dirty,
	fixed_wireless_internet_upstream_lines,
	cable_internet_upstream_lines,
	copper_internet_upstream_lines,
	satellite_lte_internet_upstream_lines,
	uncategorized_internet_upstream_lines,

	--wan summary
	gt_1g_wan_lines,
	lt_1g_fiber_wan_lines,
	lt_1g_nonfiber_wan_lines,
	
	--wifi details	
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

	--more cost details
	ia_monthly_cost_direct_to_district,
	ia_monthly_cost_shared,
	ia_monthly_cost_no_backbone,
  	backbone_monthly_cost,
	ia_monthly_cost_district_applied,
	ia_monthly_cost_other_applied,
	ia_monthly_funding_total,
	wan_monthly_cost_per_line,
	wan_monthly_cost_total,
	
	--primary sp and switcher dtials
	primary_sp_purpose,
	primary_sp_bandwidth,
	primary_sp_percent_of_bandwidth,
	purpose_match,
	
	--more demographic data
	zip,
	county,
	union_code,
	state_senate_district,
	state_assembly_district,
	ulocal,
	include_in_universe_of_districts_all_charters,
	num_teachers,
	num_aides,
	num_other_staff,
	discount_rate_c1,
	frl_percent,
	ia_oversub_ratio

from fy2017_districts_fiberpredeluxe_matr dfpd

left join state_level_extrap sle
on sle.postal_cd = dfpd.postal_cd

left join public.fy2017_clean_to_campus_matr c
on dfpd.esh_id = c.district_esh_id

order by include_in_universe_of_districts desc, district_type desc, postal_cd asc, name asc

/*
Author: Justine Schott, Jamie Barnes
Created On Date: 8/15/2016
Last Modified Date: 9/8/2017 -- JH reorganized, added wifi suffienciy sots, and cck12 projected bw 2018
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting and fiber metric extrapolation assumptions built in
Methodology:
*/