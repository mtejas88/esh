select 
  bi.application_number,
  case
    when c.application_number is null
      then 0
    else 1
  end as consultant_indicator,
  total_funding_year_commitment_amount_request::numeric,
  count(distinct  case
                    when fiber_sub_type = 'Special Construction'
                      then bi.application_number
                  end) as special_construction_indicator,
  count(distinct frns.service_type) as num_service_types,
  array_to_string(array_agg(distinct frns.service_type),';') as service_types,
  count(distinct frns.service_provider_number) as num_spins,
  count(distinct ros.ben) as num_recipients,
  bi.applicant_type,
  bi.category_of_service,
  bi.urban_rural_status,
  bi.category_one_discount_rate,
  bi.fulltime_enrollment
   
from fy2017.frns
join (
  select *
  from fy2017.basic_informations
  where total_funding_year_commitment_amount_request::numeric > 0
  and window_status = 'In Window'
) bi
on frns.application_number = bi.application_number
left join fy2017.recipients_of_services ros
on frns.application_number = ros.application_number
left join fy2017.consultants c
on frns.application_number = c.application_number
group by 1,2,3,9,10,11,12,13