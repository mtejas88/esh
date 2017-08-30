select
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
