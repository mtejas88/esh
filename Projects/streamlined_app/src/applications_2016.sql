-- base from query that will be QA'd by jamie 
-- https://github.com/educationsuperhighway/ficher/blob/profiling_high_cost/Projects/high_cost_profiling/src/applications.sql
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
    count(distinct frns.service_provider_number) as num_spins,
    count(distinct ros.ben) as num_recipients,
    bi.applicant_type,
    bi.category_of_service,
    bi.urban_rural_status,
    bi.category_one_discount_rate,
    bi.fulltime_enrollment,
    sum(case
          when fr.frn_status = 'Funded'
            then 1
          else 0
        end) as funded_frns,
    sum(case
          when fr.frn_status = 'Denied'
            then 1
          else 0
        end) as denied_frns,
    count(*) as frns,
    avg(case
          when wave_number is not null and wave_number != ''
            then wave_number::numeric
        end) as avg_wave_number
     
  from fy2016.frns
  join (
    select *
    from fy2016.basic_informations
    where total_funding_year_commitment_amount_request::numeric > 0
    and window_status = 'In Window'
  ) bi
  on frns.application_number = bi.application_number
  left join fy2016.recipients_of_services ros
  on frns.application_number = ros.application_number
  left join fy2016.consultants c
  on frns.application_number = c.application_number
  left join (
    select * 
    from funding_requests_2016_and_later
    where funding_year = '2016'
  ) fr
  on frns.frn = fr.frn
  group by 1,2,3,8,9,10,11,12