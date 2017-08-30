select 
  d17.esh_id,
  d17.name,
  d17.postal_cd,
  d17.exclude_from_ia_analysis,
  d17.exclude_from_wan_analysis,
  d17.fiber_target_status,
  d17.c2_prediscount_budget_15,
  d17.c2_prediscount_remaining_15 - d17.c2_prediscount_remaining_17 as c2_spend_16_17,
  d17.c2_prediscount_remaining_17,
  d17.locale,
  d17.district_size,
  d17.discount_rate_c1_matrix,
  case
    when d17.exclude_from_ia_analysis = true 
      or  d17.exclude_from_wan_analysis = true
      or d17.fiber_target_status = 'Potential'
        then true
    else false
  end as receives_survey,
  case
    when d17.needs_wifi = d16.needs_wifi 
     and d17.needs_wifi = false
        then 'Sufficient  16-17'
    when d17.needs_wifi = d16.needs_wifi 
     and d17.needs_wifi = true
        then 'Insufficient 16-17'
    when d17.needs_wifi is null
        then 'No wifi info 17'
  end as wifi_status


from public.fy2017_districts_deluxe_matr d17

left join public.fy2016_districts_deluxe_matr d16
on d17.esh_id = d16.esh_id

where d17.include_in_universe_of_districts = true
and d17.district_type = 'Traditional'
and (d17.needs_wifi = d16.needs_wifi
  or d17.needs_wifi is null)