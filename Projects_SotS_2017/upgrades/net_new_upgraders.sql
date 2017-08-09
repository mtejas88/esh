with a as
(select esh_id
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and upgrade_indicator = 'True'
)

select esh_id
from
public.fy2017_districts_deluxe_matr dd17
where

include_in_universe_of_districts
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and esh_id not in (select esh_id from a)
