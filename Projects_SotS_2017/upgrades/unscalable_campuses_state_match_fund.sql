
select
sum(sots_known_unscalable_campuses+sots_assumed_unscalable_campuses) as total_campuses_in_matched_funding_states
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and postal_cd in
(
'MT',
'ID',
'MN',
'KS',
'IL',
'MD',
'MA',
'MO',
'NH',
'AZ',
'VA',
'NC',
'TX',
'CA',
'NM',
'NY',
'OK',
'FL',
'ME'
)
