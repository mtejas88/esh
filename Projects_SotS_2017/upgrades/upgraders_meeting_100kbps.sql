select

(select
count(esh_id)
from
fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and exclude_from_ia_analysis = 'False'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
) as "upgraders_2017",

(select
count(esh_id)
from
fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and exclude_from_ia_analysis = 'False'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub
) as "upgraders_2017_meeting_100kbps",

(select
count(esh_id)
from
fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and exclude_from_ia_analysis = 'False'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
) as "upgraders_2016",

(select
count(esh_id)
from
fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and exclude_from_ia_analysis = 'False'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub
) as "upgraders_2016_meeting_100kbps"
