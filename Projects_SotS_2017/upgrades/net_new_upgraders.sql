with a as
(select esh_id
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True')

select
(select
count(esh_id)
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and esh_id not in (select * from a)
) as "net_new_upgrades_2017",

(select
count(esh_id)
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and esh_id in (select * from a)
) as "repeat_upgrades_2017"
