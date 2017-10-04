with fli_2017 as (

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
),

all_data as (

  select li.funding_year,
  li.id,
  fli.application_number,
  fli.frn,
  fli.frn_complete,
  fli.type_of_product,
  fli.function,
  fli.purpose,
  esp.name as service_provider_name,
  fli.make,
  fli.model,
  fli.other_manufacture,
  fli.basic_firewall_protection,
  fli.is_installation_included_in_price,
  fli.unit,
  fli.monthly_quantity::varchar,
  fli.one_time_quantity,
  fli.total_monthly_eligible_recurring_costs::numeric,
  fli.total_eligible_recurring_costs::numeric,
  fli.total_eligible_one_time_costs::numeric,
  fli.lease_or_non_purchase_agreement,
  fli.narrative,
  bi.form471_url,
  null as correct_recipients,
  null as correct_allocations

  from fli_2016 fli

  left join bi_2016 bi
  on fli.application_number = bi.application_number

  join public.esh_line_items li
  on li.frn_complete = fli.frn_complete
  and li.funding_year = 2016

  left join public.esh_service_providers esp
  on esp.id = li.service_provider_id

  where bi.category_of_service::numeric = 2


  UNION

  select li.funding_year,
  li.id,
  fli.application_number,
  fli.frn,
  fli.frn_complete,
  fli.type_of_product,
  fli.function,
  fli.purpose,
  esp.name as service_provider_name,
  fli.make,
  fli.model,
  fli.other_manufacture,
  fli.basic_firewall_protection,
  fli.is_installation_included_in_price,
  fli.unit,
  fli.monthly_quantity::varchar,
  fli.one_time_quantity,
  fli.total_monthly_eligible_recurring_costs::numeric,
  fli.total_eligible_recurring_costs::numeric,
  fli.total_eligible_one_time_costs::numeric,
  fli.lease_or_non_purchase_agreement,
  fli.narrative,
  bi.form471_url,
  null as correct_recipients,
  null as correct_allocations

  from fli_2017 fli

  left join bi_2017 bi
  on fli.application_number = bi.application_number

  join public.esh_line_items li
  on li.frn_complete = fli.frn_complete
  and li.funding_year = 2017

  left join public.esh_service_providers esp
  on esp.id = li.service_provider_id

  where bi.category_of_service::numeric = 2

)

select 
  service_provider_name,
  make,
  model,
  type_of_product,
  count(id) as num_line_items,
  sum(total_eligible_recurring_costs + total_eligible_one_time_costs) as total_cost

from all_data

where funding_year = 2017
--and type_of_product = 'Access Point'

group by 1,2,3, 4
order by 3 desc