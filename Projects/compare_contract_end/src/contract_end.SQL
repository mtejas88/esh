select 
  distinct frn.frn,
  sr.recipient_postal_cd,
  eli.contract_end_date,
  --frn.contract_expiry_date::date,
  frn.expiration_date::date,
  case 
    when frn.expiration_date::date is null
      then 'missing expiration date'
    when frn.expiration_date::date > eli.contract_end_date
      then 'contract end date is earlier than expiration date'
    when eli.contract_end_date > frn.expiration_date::date
      then 'expiration date is earlier than contract end date'
    when eli.contract_end_date = frn.expiration_date::date
      then 'same dates'
  end as comparing_dates,
  case 
    when frn.expiration_date::date is null
      then null
    else frn.expiration_date::date - eli.contract_end_date
  end as expiry_minus_contract
  

from public.esh_line_items eli

join fy2017.frn_line_items fli
on eli.frn_complete = fli.line_item

join fy2017.frns frn
on fli.frn = frn.frn

join public.fy2017_services_received_matr sr
on eli.id = sr.line_item_id

where eli.erate = true
and eli.broadband = true
and eli.funding_year = 2017
and sr.recipient_include_in_universe_of_districts = true