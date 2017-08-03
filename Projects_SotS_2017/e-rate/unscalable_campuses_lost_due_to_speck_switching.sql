with spec_k_2017 as (
  select distinct sr.recipient_id, sr.reporting_name
  from fy2017.frns
  join (
    select *
    from public.fy2017_esh_line_items_v 
  ) li 
  on frns.frn = li.frn
  join public.fy2017_services_received_matr sr
  on li.id = sr.line_item_id
--new fiber was built  
  where fiber_sub_type = 'Special Construction'
  and fiber_type != 'Self Provisioned'
),

districts as (
  select 
    dd17.esh_id, 
    dd17.current_assumed_unscalable_campuses + dd17.current_known_unscalable_campuses as unscalable_campuses_2017,
    dd16.current_assumed_unscalable_campuses + dd16.current_known_unscalable_campuses as unscalable_campuses_2016,
    array_to_string(array_agg(distinct spec_k_2017.reporting_name),';') as spec_k_provider_2017,
    dd16.service_provider_assignment as service_provider_assignment_2016
  
  from fy2017_districts_deluxe_matr dd17
  left join fy2016_districts_deluxe_matr dd16
  on dd17.esh_id= dd16.esh_id
  join spec_k_2017
  on dd17.esh_id= spec_k_2017.recipient_id
  where dd17.include_in_universe_of_districts
  and dd17.district_type = 'Traditional'

  group by 1,2,3,5
)

select
  not(spec_k_provider_2017 = service_provider_assignment_2016) as switcher,
  sum(unscalable_campuses_2016-unscalable_campuses_2017) as unscalable_to_scalable_campuses
from districts
where service_provider_assignment_2016 is not null
group by 1