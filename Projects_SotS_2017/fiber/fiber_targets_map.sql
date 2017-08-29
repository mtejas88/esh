select esh_id, name, postal_cd, county,
fiber_target_status,
current_known_unscalable_campuses,
current_assumed_unscalable_campuses,
(current_known_unscalable_campuses + current_assumed_unscalable_campuses) as known_and_assumed_unscalable_campuses,

case when current_known_unscalable_campuses >=1 then 'Known Unscalable'
when current_assumed_unscalable_campuses >=1 then 'Assumed Unscalable'
else 'Other' end as fiber_category,

longitude, latitude
 from public.fy2017_districts_deluxe_matr del
where include_in_universe_of_districts
and district_type = 'Traditional'
and (current_known_unscalable_campuses + current_assumed_unscalable_campuses) > 0

--filtering out 'Other' in the dashboard