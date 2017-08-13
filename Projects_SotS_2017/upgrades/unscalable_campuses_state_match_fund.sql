select
sum(case
     when postal_cd in
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


         then current_known_unscalable_campuses + current_assumed_unscalable_campuses
     else 0
 end) as num_unscalable_campuses_with_state_match_fund
from fy2017_districts_deluxe_matr
where include_in_universe_of_districts
and district_type = 'Traditional'
