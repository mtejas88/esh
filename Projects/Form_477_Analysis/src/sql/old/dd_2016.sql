select

esh_id,
district_size,
district_type,
locale,
postal_cd,
latitude,
longitude,
fiber_target_status,
bw_target_status,
current_assumed_unscalable_campuses,
current_known_unscalable_campuses

from endpoint.fy2016_districts_deluxe
where include_in_universe_of_districts