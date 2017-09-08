-- Generates CCK12 District Fiber BW Wifi Summary page (for One Map)

select
  -- General Columns
  distinct dd.esh_id,
  dd.name,
  dd.locale,
  dd.longitude,
  dd.latitude,
  dd.postal_cd,
  dd.include_in_universe_of_districts,
  dd.exclude_from_ia_analysis,
  case
    when not(dd.exclude_from_ia_analysis) then dd.ia_bw_mbps_total
	end as ia_bw_mbps_total,
  lis.ia_total_monthly_cost,
  case
    when dd.ia_bandwidth_per_student_kbps is null or dd.ia_bandwidth_per_student_kbps = 0 then 6
		when dd.ia_bandwidth_per_student_kbps::numeric < 100 then 1
		when dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric >= 100 and dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric < 200 then 2
		when dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric >= 200 and dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric < 500 then 3
		when dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric >= 500 and dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric < 1000 then 4
		when dd.ia_bandwidth_per_student_kbps::numeric / dd.setda_concurrency_factor::numeric >= 1000 then 5
 end as bandwidth_ranking,
  case
    when not(dd.exclude_from_ia_cost_analysis) then dd.ia_monthly_cost_per_mbps
  end as ia_monthly_cost_per_mbps,
  -- projected bw for 2014
  case
    when dd.num_students is not null and dd.num_students != 0 then (100 * dd.num_students / 1000)::integer
    else null
  end as projected_bw_fy2014,
  -- projected bw for 2018
  case
    when dd.num_students is not null and dd.num_students != 0 then
    case
      when dd.setda_concurrency_factor > 0 then
	      case when (dd.num_students::numeric * dd.setda_concurrency_factor) < 28.5 then 25
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 34 then 30
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 56 then 50
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 111 then 100
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 221 then 200
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 331 then 300
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 551 then 500
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 1101 then 1000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 2201 then 2000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 3301 then 3000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 5501 then 5000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 11001 then 10000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 22001 then 20000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 33001 then 30000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 44001 then 40000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 55001 then 50000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 110001 then 100000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 220001 then 200000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 330001 then 300000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) < 550001 then 500000
					   when (dd.num_students::numeric * dd.setda_concurrency_factor) >= 550001 then 1000000
			  end
	  end
  end as projected_bw_fy2018,

  -- Service to be Replaced (hierarchy: IA, then WAN)
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then 'IA'
    when uc.bandwidth_in_mbps_unscalable_wan is not null then 'WAN'
    else null
  end as service_to_be_replaced_purpose,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.bandwidth_in_mbps_unscalable_ia
    when uc.bandwidth_in_mbps_unscalable_wan is not null then uc.bandwidth_in_mbps_unscalable_wan
    else null
  end as service_to_be_replaced_bandwidth_in_mbps,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.connect_category_unscalable_ia
    when uc.bandwidth_in_mbps_unscalable_wan is not null then uc.connect_category_unscalable_wan
    else null
  end as service_to_be_replaced_connect_category,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.connect_category_unscalable_ia_formatted
    when uc.bandwidth_in_mbps_unscalable_wan is not null then uc.connect_category_unscalable_wan_formatted
    else null
  end as service_to_be_replaced_connect_category_formatted,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.monthly_circuit_cost_recurring_unscalable_ia
    when uc.bandwidth_in_mbps_unscalable_wan is not null then uc.monthly_circuit_cost_recurring_unscalable_wan
    else null
  end as service_to_be_replaced_monthly_circuit_cost_recurring_per_connection,

  dd.fiber_target_status,
  -- IF TARGET:
  -- define the reason if the district is clean for IA and there is an unscalable IA or WAN line item
  -- otherwise the reason is 'No Data; Clarification Needed' (dirty) or 'Override' (clean)
  -- ELSE NULL.
  case
    when dd.fiber_target_status = 'Target' then
    case
      when dd.exclude_from_ia_analysis = FALSE and uc.bandwidth_in_mbps_unscalable_ia is not null then 'Unscalable IA'
      when dd.exclude_from_ia_analysis = FALSE and uc.bandwidth_in_mbps_unscalable_wan is not null then 'Unscalable WAN'
      when dd.exclude_from_ia_analysis = TRUE then 'No Data; Clarification Needed'
      else 'Override'
    end
    else NULL
  end as fiber_target_reason,

  -- collapse suggested districts array to the only array that we want to display for fiber based on hierarchy
  case
    when dd.exclude_from_ia_analysis = false and uc.bandwidth_in_mbps_unscalable_ia is not null then fi.fiber_ia_suggested_districts
    when dd.exclude_from_ia_analysis = false and uc.bandwidth_in_mbps_unscalable_wan is not null then fw.fiber_wan_suggested_districts
    else NULL
  end as fiber_suggested_districts,

  --Unscalable IA Line Item
  uc.line_item_id_unscalable_ia,
  uc.bandwidth_in_mbps_unscalable_ia,
  uc.monthly_circuit_cost_recurring_unscalable_ia,
  uc.ia_cost_per_mbps_unscalable,
  uc.connect_category_unscalable_ia,
  uc.connect_category_unscalable_ia_formatted,
  uc.service_provider_name_unscalable_ia,
  uc.reporting_name_unscalable_ia,
  --Unscalable WAN Line Item
  uc.line_item_id_unscalable_wan,
  uc.bandwidth_in_mbps_unscalable_wan,
  uc.monthly_circuit_cost_recurring_unscalable_wan,
  uc.connect_category_unscalable_wan,
  uc.connect_category_unscalable_wan_formatted,
  uc.service_provider_name_unscalable_wan,
  uc.reporting_name_unscalable_wan,

  --Scalable IA Line Item
  sc.line_item_id_scalable_ia,
  sc.bandwidth_in_mbps_scalable_ia,
  sc.monthly_circuit_cost_recurring_scalable_ia,
  sc.ia_cost_per_mbps_scalable,
  sc.connect_category_scalable_ia,
  sc.connect_category_scalable_ia_formatted,
  sc.service_provider_name_scalable_ia,
  sc.reporting_name_scalable_ia,
  -- Scalable WAN Line Item
  sc.line_item_id_scalable_wan,
  sc.bandwidth_in_mbps_scalable_wan,
  sc.monthly_circuit_cost_recurring_scalable_wan,
  sc.connect_category_scalable_wan,
  sc.connect_category_scalable_wan_formatted,
  sc.service_provider_name_scalable_wan,
  sc.reporting_name_scalable_wan,

  -- Bandwidth Columns
  dd.bw_target_status as bw_target_status_fy2014,
  case
    when not(dd.exclude_from_ia_analysis) then dd.service_provider_assignment
	end as dominant_ia_sp_name,
	case
	  when not(dd.exclude_from_ia_analysis) then dd.ia_bandwidth_per_student_kbps
	end as kbps_per_student,
  bw.bandwidth_suggested_districts,

  -- Wifi Columns
  case
    when dd.wifi_target_status is null then 'No Data'
    else dd.wifi_target_status
  end as wifi_target_status,
  nr.needs_wifi_reason,
  case
    when dd.c2_postdiscount_remaining_17 < 5000
      then round(dd.c2_postdiscount_remaining_17 / 100) * 100
	  when dd.c2_postdiscount_remaining_17 >= 5000
      then round(dd.c2_postdiscount_remaining_17 / 1000) * 1000
	end as c2_budget_remaining,
  tc.top_3_c2_consultants_in_state,
  tc.top_3_c2_service_providers_in_state

from endpoint.fy2017_districts_deluxe dd
left join endpoint.fy2017_line_item_summaries lis
on dd.esh_id = lis.recipient_id
left join endpoint.fy2017_needs_fiber_reasons nr
on dd.esh_id = nr.esh_id
left join endpoint.fy2017_services_received sr
on dd.esh_id = sr.recipient_id
left join endpoint.fy2017_unscalable_line_items uc
on dd.esh_id = uc.esh_id
left join endpoint.fy2017_scalable_line_items sc
on dd.esh_id = sc.esh_id
left join endpoint.fy2017_fiber_ia_suggested_districts fi
on dd.esh_id = fi.esh_id
left join endpoint.fy2017_fiber_wan_suggested_districts fw
on dd.esh_id = fw.esh_id
left join endpoint.fy2017_bandwidth_suggested_districts bw
on dd.esh_id = bw.esh_id
left join endpoint.fy2017_top_c2_consultants_and_service_providers tc
on dd.postal_cd = tc.postal_cd

where dd.include_in_universe_of_districts = TRUE

/*
Author: Jen Overgaag
Created On Date: 7/28/2017
Last Modified Date: 09/05/2017: Sierra - updated sedta concurrency factor divisions to multiplications, since the 2017 setda concurrenct factors are <= 1. Also changed fiber_suggested_districts to use clean districts (exclude_from_ia_analysis=false)
Name of QAing Analyst(s): 
Purpose: 
Methodology:
Dependencies: [endpoint.fy2017_districts_deluxe, endpoint.fy2017_line_item_summaries, endpoint.fy2017_needs_fiber_reasons, endpoint.fy2017_services_received, endpoint.fy2017_unscalable_line_items, endpoint.fy2017_scalable_line_items, endpoint.fy2017_fiber_ia_suggested_districts, endpoint.fy2017_fiber_wan_suggested_districts, endpoint.fy2017_bandwidth_suggested_districts, endpoint.fy2017_top_c2_consultants_and_service_providers]
*/
