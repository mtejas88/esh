with ros_2017 as (

  select 
  application_number,
  line_item,
  ben,
  amount::numeric
  from fy2017.recipients_of_services
  
  where line_item not in (
    select distinct line_item
    from fy2017.current_recipients_of_services 
  )
  
  union
  
  select 
  application_number,
  line_item,
  ben,
  amount::numeric
  from fy2017.current_recipients_of_services

), 

ros_2016 as (

  select 
  application_number,
  line_item,
  ben,
  amount::numeric
  from fy2016.recipients_of_services
  
  where line_item not in (
    select distinct line_item
    from fy2016.current_recipients_of_services 
  )
  
  union
  
  select 
  application_number,
  line_item,
  ben,
  amount::numeric
  from fy2016.current_recipients_of_services

),

fli_2017 as (

  select 
    fli.application_number,
    fli.frn,
    fli.line_item as frn_complete,
    fli.type_of_product,
    fli.function,
    fli.purpose,
    fli.make,
    fli.model,
    fli.other_manufacture,
    fli.basic_firewall_protection,
    fli.is_installation_included_in_price,
    fli.unit,
    fli.monthly_quantity,
    fli.one_time_quantity,
    fli.total_monthly_eligible_recurring_costs,
    fli.total_eligible_recurring_costs,
    fli.total_eligible_one_time_costs,
    fli.lease_or_non_purchase_agreement,
    frn.narrative
    
  from fy2017.current_frn_line_items fli
  
  left join fy2017.current_frns frn
  on fli.frn = frn.frn
  
  union
  
  select 
    fli.application_number,
    fli.frn,
    fli.line_item as frn_complete,
    fli.type_of_product,
    fli.function,
    fli.purpose,
    fli.make,
    fli.model,
    fli.other_manufacture,
    fli.basic_firewall_protection,
    fli.is_installation_included_in_price,
    fli.unit,
    fli.monthly_quantity,
    fli.one_time_quantity,
    fli.total_monthly_eligible_recurring_costs,
    fli.total_eligible_recurring_costs,
    fli.total_eligible_one_time_costs,
    fli.lease_or_non_purchase_agreement,
    frn.narrative
  
  from fy2017.frn_line_items fli
  
  left join fy2017.frns frn
  on fli.frn = frn.frn
  
  where fli.line_item not in (
    select distinct line_item
    from fy2017.current_frn_line_items
  )

),

fli_2016 as (
    select 
    fli.application_number,
    fli.frn,
    fli.line_item as frn_complete,
    fli.type_of_product,
    fli.function,
    fli.purpose,
    fli.make,
    fli.model,
    fli.other_manufacture,
    fli.basic_firewall_protection,
    fli.is_installation_included_in_price,
    fli.unit,
    fli.monthly_quantity,
    fli.one_time_quantity,
    fli.total_monthly_eligible_recurring_costs,
    fli.total_eligible_recurring_costs,
    fli.total_eligible_one_time_costs,
    fli.lease_or_non_purchase_agreement,
    frn.narrative
    
  from fy2016.current_frn_line_items fli
  
  left join fy2016.current_frns frn
  on fli.frn = frn.frn
  
  union
  
  select 
    fli.application_number,
    fli.frn,
    fli.line_item as frn_complete,
    fli.type_of_product,
    fli.function,
    fli.purpose,
    fli.make,
    fli.model,
    fli.other_manufacture,
    fli.basic_firewall_protection,
    fli.is_installation_included_in_price,
    fli.unit,
    fli.monthly_quantity,
    fli.one_time_quantity,
    fli.total_monthly_eligible_recurring_costs,
    fli.total_eligible_recurring_costs,
    fli.total_eligible_one_time_costs,
    fli.lease_or_non_purchase_agreement,
    frn.narrative
  
  from fy2016.frn_line_items fli
  
  left join fy2016.frns frn
  on fli.frn = frn.frn
  
  where fli.line_item not in (
    select distinct line_item
    from fy2016.current_frn_line_items
  )
),

bi_2017 as (
  select 
    application_number,
    category_of_service,
    form471_url
  from fy2017.current_basic_informations 
  UNION
  select
    application_number,
    category_of_service,
    form471_url
  from fy2017.basic_informations 
  where application_number not in (
    select distinct application_number
    from fy2017.current_basic_informations
  )
),

bi_2016 as (
  select 
    application_number,
    category_of_service,
    null as form471_url
  
  from fy2016.current_basic_informations 
  UNION
  select
    application_number,
    category_of_service,
    form471_url
  from fy2016.basic_informations 
  where application_number not in (
    select distinct application_number
    from fy2016.current_basic_informations
  )
)
/*
select distinct
  li.funding_year,
  li.id,
  fli.type_of_product,
  esp.name as service_provider_name,
  fli.make,
  fli.model,
  fli.other_manufacture,
  fli.total_monthly_eligible_recurring_costs::numeric,
  fli.total_eligible_recurring_costs::numeric,
  fli.total_eligible_one_time_costs::numeric,
  ros.ben,
  ros.amount

from fli_2016 fli

left join bi_2016 bi
on fli.application_number = bi.application_number

left join ros_2016 ros
on ros.line_item = fli.frn_complete

join public.esh_line_items li
on li.frn_complete = fli.frn_complete
and li.funding_year = 2016

left join public.esh_service_providers esp
on esp.id = li.service_provider_id

join public.entity_bens eb
on ros.ben = eb.ben

join public.fy2016_district_lookup_matr dl
on eb.entity_id::varchar = dl.esh_id

join public.fy2016_districts_deluxe_matr dd
on dl.district_esh_id = dd.esh_id
and dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true

where bi.category_of_service::numeric = 2

UNION

*/

select distinct
  li.funding_year,
  li.id,
  fli.type_of_product,
  esp.name as service_provider_name,
  fli.make,
  fli.model,
  fli.other_manufacture,
  fli.total_monthly_eligible_recurring_costs::numeric,
  fli.total_eligible_recurring_costs::numeric,
  fli.total_eligible_one_time_costs::numeric,
  ros.ben,
  ros.amount

from fli_2017 fli

left join bi_2017 bi
on fli.application_number = bi.application_number

left join ros_2017 ros
on ros.line_item = fli.frn_complete

join public.esh_line_items li
on li.frn_complete = fli.frn_complete
and li.funding_year = 2017

left join public.esh_service_providers esp
on esp.id = li.service_provider_id

join public.entity_bens eb
on ros.ben = eb.ben

join public.fy2017_district_lookup_matr dl
on eb.entity_id::varchar = dl.esh_id

join public.fy2017_districts_deluxe_matr dd
on dl.district_esh_id = dd.esh_id
and dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true

where bi.category_of_service::numeric = 2

