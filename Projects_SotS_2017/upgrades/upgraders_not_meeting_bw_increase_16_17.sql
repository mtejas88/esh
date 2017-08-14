with a as(
select esh_id
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub = 'False'
)
select
(
select sum(ia_bw_mbps_total)
from public.fy2016_districts_deluxe_matr
where esh_id in (select * from a)
) as "bw_in_2016",
(
select sum(ia_bw_mbps_total)
from public.fy2017_districts_deluxe_matr
where esh_id in (select * from a)
) as "bw_in_2017"
