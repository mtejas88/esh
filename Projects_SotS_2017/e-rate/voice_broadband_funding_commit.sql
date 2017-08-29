select  2015 as funding_year,
        case
          when frns."FRN Service Type" = 'VOICE SERVICES'
            then 'voice'
          when frns."FRN Service Type" ilike '%internal%'
            then 'c2'
          else 'broadband'
        end as category,
        sum(distinct(round(frns."Total Elig Chg"::numeric * (frns."Discount"::numeric/100),2)))/1000000000 as funding_commitment_request_$B
from public.fy2015_funding_request_key_informations frns

left join public.fy2015_basic_information_and_certifications bi
on frns."Application Number" = bi."Application Number"

left join public.entity_bens eb
on bi."BEN" = eb.ben

left join public.district_lookup_2015_m dl
on dl.district_esh_id = eb.entity_id

join public.fy2015_districts_deluxe_m dd
on dl.district_esh_id = dd.esh_id

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
        sum(distinct frns.funding_commitment_request::numeric)/1000000000 as funding_commitment_request_$B
from fy2016.frns frns

left join fy2016.basic_informations bi
on frns.application_number = bi.application_number

left join public.entity_bens eb
on bi.billed_entity_number = eb.ben

left join public.fy2016_district_lookup_matr dl
on dl.district_esh_id = eb.entity_id::varchar

join public.fy2016_districts_deluxe_matr dd
 on dl.district_esh_id = dd.esh_id

where
include_in_universe_of_districts
and district_type = 'Traditional'
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
        sum(distinct funding_commitment_request::numeric)/1000000000 as funding_commitment_request_$B
from fy2017.frns
left join public.entity_bens eb
on frns.ben = eb.ben

left join public.fy2017_district_lookup_matr dl
on dl.district_esh_id = eb.entity_id::varchar

join public.fy2017_districts_deluxe_matr dd
 on dl.district_esh_id = dd.esh_id

where
include_in_universe_of_districts
and district_type = 'Traditional'
group by 1, 2
order by funding_year, category
