select

esh_id,
nces_cd,
district_size,
district_type,
num_schools,
num_campuses,
num_students,
locale,
frl_percent,
discount_rate_c1,
postal_cd,
county,
latitude,
longitude,
exclude_from_ia_analysis,
exclude_from_ia_cost_analysis,
include_in_universe_of_districts,
ia_bandwidth_per_student_kbps,
meeting_2014_goal_no_oversub,
meeting_2018_goal_oversub,
ia_monthly_cost_per_mbps,
meeting_knapsack_affordability_target,
fiber_target_status,
bw_target_status

from public.fy2016_districts_deluxe_matr
where include_in_universe_of_districts