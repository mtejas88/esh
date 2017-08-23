select
(
select sum(cmtd_commitment_request)::numeric/1000000000 as funding_committment_request_billions

from
public.funding_requests
where
funding_year = '2014'
and cmtd_category_of_service = 'TELCOMM SERVICES') as "funding_for_voice_2014",

(
select sum(cmtd_commitment_request)::numeric/1000000000 as funding_committment_request_billions
from
public.funding_requests
where
funding_year = '2014'
and cmtd_category_of_service = 'INTERNET ACCESS') as "funding_for_internet_2014"
