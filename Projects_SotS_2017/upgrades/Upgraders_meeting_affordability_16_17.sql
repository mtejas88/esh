
select
(select count(esh_id)
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_knapsack_affordability_target = 'True'
) as "number_districts_meeting_affrodability_2017",

(select count(esh_id)
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_knapsack_affordability_target = 'False'
) as "number_districts_not_meeting_affrodability_2017",

(select count(esh_id)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_knapsack_affordability_target = 'True'
) as "number_districts_meeting_affrodability_2016",

(select count(esh_id)
from public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis = 'False'
and upgrade_indicator = 'True'
and meeting_knapsack_affordability_target = 'False'
) as "number_districts_not_meeting_affrodability_2016"
