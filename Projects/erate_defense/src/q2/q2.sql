with bi_2016 as (
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

frns_16 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  fli.function,
  fli.type_of_product,
  fli.total_monthly_eligible_recurring_costs,
  fli.total_eligible_one_time_costs
  
  from fy2016.frns frn
  
  left join fy2016.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2016.current_frns
  )
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  fli.function,
  fli.type_of_product,
  fli.total_monthly_eligible_recurring_costs,
  fli.total_eligible_one_time_costs
  
  from fy2016.current_frns frn
  
  left join fy2016.current_frn_line_items fli
  on frn.frn = fli.frn

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

frns_17 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.frns frn
  
  left join fy2017.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2017.current_frns
  )
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.current_frns frn
  
  left join fy2017.current_frn_line_items fli
  on frn.frn = fli.frn

)

select distinct
  fr.application_number,
  fr.frn,
  fr.frn_status,
  fr.review_status,
  fr.ben,
  fr.funding_year,
  fr.fcdl_comment_for_frn,
  fr.fcdl_comment_for_application,
  fr.application_status,
  case
  	when fr.funding_year = '2017'
  		then bi17.category_of_service
  	else bi16.category_of_service
  end as category_of_service,
  case
  	when fr.funding_year = '2017'
  		then frns_17.fiber_sub_type
  	else frns_16.fiber_sub_type
  end as fiber_sub_type
  
from public.funding_requests_2016_and_later fr

left join bi_2017 bi17
on fr.application_number = bi17.application_number

left join bi_2016 bi16
on fr.application_number = bi16.application_number

left join frns_17
on fr.frn = frns_17.frn

left join frns_16
on fr.frn = frns_16.frn

where 
	(case 
		when funding_year = '2017' then bi17.category_of_service::numeric = 1
		else bi16.category_of_service::numeric = 1
	end)
and fr.frn_status='Denied'
and fr.funding_year = '2016'
--and fr.funding_year = '2017'
