select
(
select sum(orig_commitment_request)::numeric/1000000000 as funding_committment_request_billions

from
public.funding_requests
where
funding_year = '2014'
and cmtd_category_of_service = 'TELCOMM SERVICES') as "funding_for_voice_2014",

-- voice funding might not possible, Telomm services does not represent voice - keeping it here for now for discusion
(
select sum(orig_commitment_request)::numeric/1000000000 as funding_committment_request_billions
from
public.funding_requests
where
funding_year = '2014'
and cmtd_category_of_service = 'INTERNET ACCESS') as "funding_for_internet_2014"
