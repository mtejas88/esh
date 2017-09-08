select
  distinct dd.esh_id,
  -- General Columns
  dd.name,
  dd.locale,
  dd.longitude,
  dd.latitude,
  dd.postal_cd,
  dd.include_in_universe_of_districts,
  ds.ia_bw_mbps_total,
  ds.ia_total_monthly_cost,
  ds.bandwidth_ranking,
  ds.ia_monthly_cost_per_mbps,
  ds.projected_bw_fy2014::integer,
  case
    when not(dd.exclude_from_ia_analysis) then ds.projected_bw_fy2018
  end as projected_bw_fy2018,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then 'IA'
    else 'WAN'
  end as service_to_be_replaced_purpose,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.bandwidth_in_mbps_unscalable_ia
    else uc.bandwidth_in_mbps_unscalable_wan
  end as service_to_be_replaced_bandwidth_in_mbps,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.connect_category_unscalable_ia
    else uc.connect_category_unscalable_wan
  end as service_to_be_replaced_connect_category,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.connect_category_unscalable_ia_formatted
    else uc.connect_category_unscalable_wan_formatted
  end as service_to_be_replaced_connect_category_formatted,
  case
    when uc.bandwidth_in_mbps_unscalable_ia is not null then uc.monthly_circuit_cost_recurring_unscalable_ia
    else uc.monthly_circuit_cost_recurring_unscalable_wan
  end as service_to_be_replaced_monthly_circuit_cost_recurring_per_connection,
  ts.fiber_target_status,
  case
    when ds.needs_fiber_reason = 'Target' then 'Unscalable IA'
    when ds.needs_fiber_wan_reason = 'Target' then 'Unscalable WAN'
    else null
  end as fiber_target_reason,
  fi.fiber_ia_suggested_districts,
  fw.fiber_wan_suggested_districts,

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
  ts.bw_target_status as bw_target_status_fy2014,
  ds.dominant_ia_sp_name,
  ds.ia_bandwidth_per_student_kbps as kbps_per_student,
  bw.bandwidth_suggested_districts,

  -- Wifi Columns
  dd.wifi_target_status,
  ds.needs_wifi_reason,
  ds.rounded_c2_prediscount_remaining_17 as c2_budget_remaining,
  tc.top_3_c2_consultants_in_state,
  tc.top_3_c2_service_providers_in_state

from endpoint.fy2017_cck12_district_summary ds
left join endpoint.fy2017_districts_deluxe dd
on dd.esh_id = ds.esh_id
left join endpoint.fy2017_fiber_bw_target_status ts
on dd.esh_id = ts.esh_id
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

/*
Author: Jen Overgaag
Created On Date: 7/28/2017
Last Modified Date: 08/16/2017 - Adrianna - adding suggested districts for Fiber IA, Fiber WAN, and Bandwidth
Name of QAing Analyst(s):
Purpose: Fiber, bandwidth, and wifi summary metrics for CCK12 state level and district level maps
Methodology:
Dependencies: [endpoint.fy2017_districts_deluxe, endpoint.fy2017_fiber_bw_target_status, endpoint.fy2017_cck12_district_summary, endpoint.fy2017_unscalable_line_items, endpoint.fy2017_scalable_line_items, endpoint.fy2017_fiber_ia_suggested_districts, endpoint.fy2017_fiber_wan_suggested_districts, endpoint.fy2017_bandwidth_suggested_districts, endpoint.fy2017_top_c2_consultants_and_service_providers]
*/
