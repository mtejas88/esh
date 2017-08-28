select  2015 as funding_year,
        case
          when frns."FRN Service Type" = 'VOICE SERVICES'
            then 'voice'
          when frns."FRN Service Type" ilike '%internal%'
            then 'c2'
          else 'broadband'
        end as category,
        sum(round(frns."Total Elig Chg"::numeric * (frns."Discount"::numeric/100),2))/1000000000 as funding_commitment_request_$B
from public.fy2015_funding_request_key_informations frns
group by 1, 2

UNION

select  2016 as funding_year,
        case
          when  frns.service_type = 'Voice'
            then 'voice'
          when  fiber_sub_type  = 'Special Construction'
            then 'special construction'
          when  frns.service_type  ilike '%internal%'
            then 'c2'
          else 'broadband'
        end as category,
        sum(frns.funding_commitment_request::numeric)/1000000000 as funding_commitment_request_$B
from fy2016.frns
group by 1, 2

UNION

select  2017 as funding_year,
        case
          when service_type = 'Voice'
            then 'voice'
          when fiber_sub_type = 'Special Construction'
            then 'special construction'
          when service_type ilike '%internal%'
            then 'c2'
          else 'broadband'
        end as category,
        sum(funding_commitment_request::numeric)/1000000000 as funding_commitment_request_$B
from fy2017.frns
group by 1, 2
order by funding_year, category
