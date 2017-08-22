with frns_17 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.frns frn
  
  left join fy2017.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2017.current_frns
  )
  and frn_status not in ('Cancelled', 'Denied')
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.current_frns frn
  
  left join fy2017.current_frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn_status not in ('Cancelled', 'Denied')

),

frns_16 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2016.frns frn
  
  left join fy2016.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2016.current_frns
  )
  and frn_status not in ('Cancelled', 'Denied')
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2016.current_frns frn
  
  left join fy2016.current_frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn_status not in ('Cancelled', 'Denied')

),

results_17 as (

select distinct dd.esh_id,
  dd.locale,
  dd.num_students,
  dd.num_schools,
  dd.district_size,
  dd.discount_rate_c1_matrix
from frns_17

join public.esh_line_items eli
on frns_17.line_item = eli.frn_complete
and eli.funding_year = 2017

join public.fy2017_services_received_matr sr
on eli.id = sr.line_item_id

join public.fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and sr.inclusion_status != 'dqs_excluded'
and (frns_17.fiber_sub_type = 'Special Construction' OR 
    'special_construction' = any(sr.open_flags) OR
    'special_construction_tag' = any(sr.open_tags)
    )
),

results_16 as (

select distinct dd.esh_id,
  dd.locale,
  dd.num_students,
  dd.num_schools,
  dd.district_size,
  dd.discount_rate_c1_matrix
from frns_16

join public.esh_line_items eli
on frns_16.line_item = eli.frn_complete
and eli.funding_year = 2016

join public.fy2016_services_received_matr sr
on eli.base_line_item_id = sr.line_item_id

--purposefully joining to 2017 to make sure in universe in 16 and 17
join public.fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id

where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and sr.inclusion_status != 'dqs_excluded'
--check subtype
and (frns_16.fiber_sub_type = 'Special Construction' OR 
    'special_construction' = any(sr.open_flags) OR
    'special_construction_tag' = any(sr.open_tags)
    )
),

special_fiber_districts as (

  select distinct * from (
    select * 
    from results_17
    union
    select * 
    from results_16
  ) unioned

)

/*
select 
count(esh_id) as num_districts,
sum(num_students) as num_students,
sum(num_schools) as num_schools,
count(case when locale in ('Urban', 'Suburban') then esh_id end) as num_urb_suburb_schools,
count(case when locale in ('Rural', 'Town') then esh_id end) as num_rural_town_schools,
sum(case when locale in ('Urban', 'Suburban') then num_schools end) as num_urb_suburb_schools,
sum(case when locale in ('Rural', 'Town') then num_schools end) as num_rural_town_school,
sum(case when locale in ('Urban', 'Suburban') then num_students end) as num_urb_suburb_students,
sum(case when locale in ('Rural', 'Town') then num_students end) as num_rural_town_students,
sum(case when district_size in ('Tiny') then num_students end) as num_tiny_students,
sum(case when district_size in ('Small') then num_students end) as num_small_students,
sum(case when district_size in ('Medium') then num_students end) as num_medium_students,
sum(case when district_size in ('Large') then num_students end) as num_large_students,
sum(case when district_size in ('Mega') then num_students end) as num_mega_students
from special_fiber_districts
*/
select *
from special_fiber_districts