  select
      frns.frn,
      frns.num_bids_received,
      del.esh_id,
      del.postal_cd,
      del.fiber_target_status,
      del.locale,
      del.ia_monthly_cost_per_mbps,
      del.meeting_knapsack_affordability_target,
      del.ia_bandwidth_per_student_kbps,
      del.meeting_2014_goal_no_oversub,
      del.exclude_from_ia_analysis,
      del.exclude_from_ia_cost_analysis,
      'Internet' = any(array_agg(sr.purpose)) as internet_indicator,
      'WAN' = any(array_agg(sr.purpose)) as wan_indicator,
      'Upstream' = any(array_agg(sr.purpose)) as upstream_indicator,
      'Backbone' = any(array_agg(sr.purpose)) as backbone_indicator,
      'ISP' = any(array_agg(sr.purpose)) as isp_indicator,
      'Lit Fiber' = any(array_agg(sr.purpose))
        or 'Dark Fiber' = any(array_agg(sr.purpose)) as fiber_indicator,
      'Other Copper' = any(array_agg(sr.purpose))
        or 'T-1' = any(array_agg(sr.purpose))
        or 'DSL' = any(array_agg(sr.purpose)) as copper_indicator,
      'Cable' = any(array_agg(sr.purpose)) as cable_indicator,
      'Fixed Wireless' = any(array_agg(sr.purpose)) as fixed_wireless_indicator
  from public.fy2016_services_received_matr sr
  left join public.fy2016_districts_deluxe_matr del
  on sr.recipient_id = del.esh_id
  left join fy2016.line_items li
  on sr.line_item_id = li.id
  left join fy2016.frns
  on li.frn = frns.frn
  where frns.frn is not null
  and sr.broadband
  and sr.inclusion_status != 'dqs_excluded'
  and (del.include_in_universe_of_districts
  or district_type = 'Charter')
  group by 1,2,3,4,5,6,7,8,9,10,11,12