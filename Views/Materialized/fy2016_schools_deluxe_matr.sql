select 
	distinct sm.school_esh_id,
   sm.district_esh_id,
   sm.campus_id,
   sm.school_nces_code,
   sm.district_include_in_universe_of_districts,
   sm.name,
   sm.school_type,
   sm.address,
   sm.city,
   sm.postal_cd,
   sm.zip,
   sm.locale,
   sm.num_students,
   sm.frl_percent,
   sm.discount_rate_c1,
   sm.discount_rate_c2,
	   case when (flag_array is null or 
	   			 (flag_count = 1 
	   			 	and array_to_string(flag_array,',') ilike '%missing_wan%')) 
	   			 and ia_bandwidth_per_student_kbps > 0
			then false
		else true
   end as exclude_from_ia_analysis,
	flag_array,
	tag_array,
	flag_count as num_open_district_flags,
	ia_bandwidth_per_student_kbps,
	case
		when ia_bandwidth_per_student_kbps >= 100
			then true
		when ia_bandwidth_per_student_kbps < 100
			then false
	end as meeting_2014_goal_no_oversub,
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
		when not_broadband_internet_upstream_lines > 0
			then true
		else false
	end as at_least_one_line_not_meeting_broadband_goal,
	case
		when 'bw_upgrade' = any(tag_array)
			then true
		when 'bw_not_upgrade' = any(tag_array)
			then false
		else null
	end as bw_upgrade_indicator,
	ia_monthly_cost_per_mbps,
	ia_bandwidth as ia_bw_mbps_total,
	ia_monthly_cost as ia_monthly_cost_total,
	ia_monthly_cost_direct_to_district,
	ia_monthly_cost_shared,
	case
		when ia_monthly_cost_per_mbps <= 3
			then true
		when ia_monthly_cost_per_mbps > 3
			then false
	end as meeting_3_per_mbps_affordability_target,
	current_known_scalable_campuses,
	current_assumed_scalable_campuses,
	current_known_unscalable_campuses,
	current_assumed_unscalable_campuses,
	sots_known_scalable_campuses,
	sots_assumed_scalable_campuses,
	sots_known_unscalable_campuses,
	sots_assumed_unscalable_campuses,
	wan_lines,
	non_fiber_lines,
    non_fiber_lines_w_dirty,
    non_fiber_internet_upstream_lines_w_dirty,
    fiber_internet_upstream_lines_w_dirty,
    fiber_wan_lines_w_dirty,
	lines_w_dirty,
	fiber_wan_lines,
	
	ia_monthly_cost_no_backbone,
	CASE 	WHEN wifi.count_wifi_needed > 0 THEN true
   			WHEN wifi.count_wifi_needed = 0 THEN false
        	ELSE null
		   	END as needs_wifi,
	c2.c2_prediscount_budget_15,
	c2.c2_prediscount_remaining_15,
	c2.c2_prediscount_remaining_16,
	c2.c2_postdiscount_remaining_15,
	c2.c2_postdiscount_remaining_16,
	c2.received_c2_15,
	c2.received_c2_16,
	c2.budget_used_c2_15,
	c2.budget_used_c2_16

from public.fy2016_schools_metrics_matr sm
	left join public.fy2016_wifi_connectivity_informations_matr wifi
	on sm.district_esh_id = wifi.parent_entity_id::varchar
	left join public.fy2016_districts_c2_funding_matr c2
	on sm.district_esh_id = c2.esh_id::varchar

order by sm.postal_cd,
		 sm.campus_id

/*
Author: Jess Seok
Created On Date: 11/18/2016
Last Modified Date: 
Name of QAing Analyst(s):Justine Schott
*/