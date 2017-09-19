with wifi_status as (
	--suffiency as of 7/24
	--copy of wifi connectivity informations except only using tags pre-7/24

	select 	ci.postal_cd,
			ci.parent_entity_name,

	(select distinct (eb_parent.entity_id) as parent_entity_id),
			--eb_parent.entity_id as parent_entity_id, using distinct entity id above and commenting non unique column
			sum(case
					when t.label = 'sufficient_wifi'
					  then 0
					when t.label = 'insufficient_wifi'
					  then 1
					when child_wifi in ('Sometimes','Never')
						then 1
					else 0
				end) as count_wifi_needed

	from fy2017.connectivity_informations ci


	left join public.entity_bens eb_parent

	on ci.parent_entity_number = eb_parent.ben

	left join public.fy2017_districts_demog_matr dd

	on eb_parent.entity_id = dd.esh_id::text::int

	left join public.tags t
	on dd.esh_id::text::int = t.taggable_id
	and t.label in ('sufficient_wifi', 'insufficient_wifi')
	and t.deleted_at is null
	and t.funding_year = 2017
	and t.created_at::date <= '2017-07-24'::date

	left join public.entity_bens eb_child   /*no funding year column in this*/
	on ci.child_entity_number = eb_child.ben

	left join public.fy2017_schools_demog_matr sd
	on eb_child.entity_id = sd.school_esh_id::text::int

	where dd.esh_id is not null
	and sd.school_esh_id is not null

	group by 	ci.postal_cd,
				ci.parent_entity_name,
				eb_parent.entity_id

),

temp as (

	select 
		d17.esh_id,
		d17.postal_cd,
		d17.num_students,
		d17.num_schools,
		d16.needs_wifi as needs_wifi_16,
		d17.needs_wifi as needs_wifi_17,
		CASE 	WHEN w.count_wifi_needed > 0 THEN true
	   			WHEN w.count_wifi_needed = 0 THEN false
	        	ELSE null
			   	END as needs_wifi_updated_17


	from public.fy2017_districts_predeluxe_matr d17

	join public.fy2016_districts_predeluxe_matr d16
	on d17.esh_id = d16.esh_id

	left join wifi_status w
	on d17.esh_id = w.parent_entity_id::varchar

	where d17.include_in_universe_of_districts
	and d17.district_type = 'Traditional'

),

temp_2 as (

select
	esh_id,
	postal_cd,
	num_students,
	num_schools,
	case 
	    when needs_wifi_16 = false
	      then 'Sufficient'
	    when needs_wifi_16 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_16,
  	case 
	    when needs_wifi_updated_17 = false
	      then 'Sufficient'
	    when needs_wifi_updated_17 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_17

from temp


),

suff as (

	select distinct 
		*,
		case
			when dd_response_17 = 'Sufficient' 
			 and dd_response_16 = 'Sufficient'
			 	then 0.944
			when dd_response_17 = 'Insufficient' 
			 and dd_response_16 = 'Insufficient'
			 	then .756
			when dd_response_17 = 'No response'
				then 	case
							when dd_response_16 = 'Sufficient'
								then 1
							else 0
						end
			when dd_response_16 = 'No response'
				then 	case
							when dd_response_17 = 'Sufficient'
								then 1
							else 0
						end
			when dd_response_17 = 'Sufficient'
				then 1
			else 0
		end as sufficient_district

	from temp_2

	where not(dd_response_16 = 'No response' and dd_response_17 = 'No response')

)


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

	 case
    -- calculate for any district that has a num_students > 0
    when dpd.num_students is not null and dpd.num_students != 0 then
    case
      when dpd.setda_concurrency_factor > 0 then
	      case when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 28.5 then 25
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 34 then 30
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 56 then 50
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 111 then 100
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 221 then 200
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 331 then 300
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 551 then 500
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 1101 then 1000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 2201 then 2000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 3301 then 3000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 5501 then 5000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 11001 then 10000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 22001 then 20000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 33001 then 30000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 44001 then 40000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 55001 then 50000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 110001 then 100000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 220001 then 200000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 330001 then 300000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) < 550001 then 500000
					   when (dpd.num_students::numeric * dpd.setda_concurrency_factor) >= 550001 then 1000000
			  end
	  end
  	end as projected_bw_fy2018_cck12,

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

	suff.sufficient_district as wifi_suff_sots_17,

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

	case when dspa.primary_sp_purpose is not null and d16.primary_sp_purpose is not null 
	and dspa.primary_sp_purpose::varchar=d16.primary_sp_purpose::varchar then 'Same' 
	when dspa.primary_sp_purpose is not null and d16.primary_sp_purpose is not null
	and dspa.primary_sp_purpose::varchar!=d16.primary_sp_purpose::varchar then 'Different' 
	end as purpose_match, 

	case when dspa.reporting_name is not null and d16.service_provider_assignment is not null
	and dspa.reporting_name!=d16.service_provider_assignment then 'Switched' 
	when dspa.reporting_name is not null and d16.service_provider_assignment is not null
	and dspa.reporting_name=d16.service_provider_assignment then 'Did Not Switch' 
	end as switcher,

	dpd.setda_concurrency_factor





from public.fy2017_districts_predeluxe_matr dpd

left join public.fy2017_fiber_bw_target_status_matr fbts

on dpd.esh_id::varchar = fbts.esh_id::varchar

left join public.fy2016_fy2017_districts_upgrades_matr du

on dpd.esh_id::varchar = du.esh_id_2017::varchar --correcting year to 2017

left join public.fy2017_districts_service_provider_assignments_matr dspa

on dpd.esh_id::varchar = dspa.esh_id::varchar

left join public.fy2016_districts_deluxe_matr d16

on dpd.esh_id::varchar = d16.esh_id::varchar

left join suff
on dpd.esh_id = suff.esh_id




/*
Author: Justine Schott
Created On Date: 8/15/2016
Last Modified Date: 9/15/2017 -- JH added wifi sufficiency from SOTS 17 and cck12 2018 rounded bw
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting assumptions built in but prior to fiber metric extrapolation
Methodology:
*/
