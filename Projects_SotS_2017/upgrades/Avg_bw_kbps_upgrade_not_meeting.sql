select sum(ia_bw_mbps_total) as total_ia, count(esh_id) as total_esh,
sum(num_students) as total_students,
((sum(ia_bw_mbps_total))/(sum(num_students)))*1000 as average_ia_kbps_student --2007
from public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and meeting_2014_goal_no_oversub = 'False'
and exclude_from_ia_analysis = 'False'
