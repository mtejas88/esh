select  distinct 
  li.frn,
  li.application_type,
  li.applicant_ben,
  li.applicant_name,
  li.applicant_postal_cd,
  li.service_provider_id,
  li.service_provider_name,
  frn.num_bids_received,
  frn.based_on_state_master_contract,
  frn.was_fcc_form470_posted

from fy2016.line_items li

left join fy2016.frn_line_items fli
on fli.line_item = li.frn_complete

left join fy2016.frns frn
on li.frn = frn.frn

left join public.esh_service_providers esp
on esp.id = li.service_provider_id

join fy2016.allocations a
on li.id = a.line_item_id
and a.cat_2_cost > 0

join public.entity_bens eb
on a.recipient_ben = eb.ben

join public.fy2016_district_lookup_matr dl
on eb.entity_id::varchar = dl.esh_id

left join public.fy2016_districts_deluxe_matr dd
on dl.district_esh_id = dd.esh_id

where li.service_category::numeric = 2
and dd.include_in_universe_of_districts_all_charters = true
 
