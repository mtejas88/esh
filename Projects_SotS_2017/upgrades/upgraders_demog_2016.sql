select
(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
) as "total_districts_in_universe_2016",

(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and meeting_2014_goal_no_oversub) as "total_in_2016_meeting_2014",

(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and meeting_2014_goal_no_oversub
and meeting_2018_goal_oversub) as "total_in_2016_meeting_2018",


(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True') as "total_upgraders_in_universe_2016",

(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub) as "total_upgraders_in_2016_meeting_2014",

(select count(*)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub
and meeting_2018_goal_oversub) as "total_upgraders_in_2016_meeting_2018"
