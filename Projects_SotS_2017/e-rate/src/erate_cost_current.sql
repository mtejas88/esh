with frns_17 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  service_type,
  purpose,
  function,
  total_monthly_eligible_recurring_costs::numeric,
  case
    when total_monthly_eligible_recurring_costs is null 
      or total_monthly_eligible_recurring_costs::numeric = 0
        then total_eligible_one_time_costs::numeric / (case
                                                        when months_of_service is null 
                                                          or months_of_service::numeric = 0
                                                            then 12
                                                        else months_of_service::numeric
                                                      end)
    else total_monthly_eligible_recurring_costs::numeric
  end as monthly_cost_mrc_unless_null
  
  from fy2017.frns frn
  
  left join fy2017.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2017.current_frns
  )
  and frn_status not in ('Cancelled', 'Denied')
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  service_type,
  purpose,
  function,
  total_monthly_eligible_recurring_costs::numeric,
  case
    when total_monthly_eligible_recurring_costs is null 
      or total_monthly_eligible_recurring_costs::numeric = 0
        then total_eligible_one_time_costs::numeric / (case
                                                        when months_of_service is null 
                                                          or months_of_service::numeric = 0
                                                            then 12
                                                        else months_of_service::numeric
                                                      end)
    else total_monthly_eligible_recurring_costs::numeric
  end as monthly_cost_mrc_unless_null
  
  from fy2017.current_frns frn
  
  left join fy2017.current_frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn_status not in ('Cancelled', 'Denied')

),

bi_17 as (
	select application_number,
	category_of_service::numeric
	from fy2017.basic_informations 
	where application_number not in (
	  select application_number
	  from fy2017.current_basic_informations 
	)

	union 

	select application_number,
	category_of_service::numeric
	from fy2017.current_basic_informations 
),

ros_17 as (
  select line_item,
  ben as recipient_ben,
  quantity
  
  from fy2017.recipients_of_services
  
  where line_item not in (
    select line_item 
    from fy2017.current_recipients_of_services 
  )
  
  union
  
  select line_item,
  ben as recipient_ben,
  quantity
  
  from fy2017.current_recipients_of_services 

),

costs as (

  select distinct frns_17.line_item, 
    frns_17.purpose,
    frns_17.function,
    frns_17.monthly_cost_mrc_unless_null,
    frns_17.monthly_cost_mrc_unless_null * 12 as total_cost,
    bi_17.category_of_service
  
  from frns_17
  
  join ros_17
  on frns_17.line_item = ros_17.line_item
  --this makes IA drop to 381M (vs 1.3B)
  --and ros_17.quantity is not null
  --and ros_17.quantity::numeric > 0
  
  join bi_17
  on frns_17.application_number = bi_17.application_number
  and bi_17.category_of_service = 1
  
  where frns_17.service_type != 'Voice'
  and frns_17.purpose is not null
  and (frns_17.fiber_sub_type != 'Special Construction' or frns_17.fiber_sub_type is null)
  and ros_17.recipient_ben in (
    select eb.ben
    from public.fy2017_district_lookup_matr dl
    
    join public.fy2017_districts_deluxe_matr dd
    on dl.district_esh_id = dd.esh_id
    and dd.include_in_universe_of_districts = true
    and dd.district_type = 'Traditional'
    
    join public.entity_bens eb
    on dl.esh_id = eb.entity_id::varchar
  )
  
  and frns_17.line_item not in (
    select eli.frn_complete as line_item
    from public.fy2017_services_received_matr sr
    join public.esh_line_items eli
    on sr.line_item_id = eli.id
    and eli.funding_year = 2017
    where inclusion_status = 'dqs_excluded'
  )

)

select 
  case
    when purpose != 'Data Connection between two or more sites entirely within the applicant’s network'
      then 'Internet'
    else 'WAN'
  end as purpose_adj,
  --function,
  sum(total_cost) as total_cost
  
from costs

where function not in ('Switches','Connectors/Couplers','Cabling','UPS',
                      'Cabinets','Patch Panels', 'Routers')

group by 1
--order by 1, 2