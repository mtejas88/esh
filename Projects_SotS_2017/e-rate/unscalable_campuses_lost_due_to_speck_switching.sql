with dist_2016 as (
  select dd.*,
    current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses
  from fy2016_districts_deluxe_matr dd
  where include_in_universe_of_districts
  and district_type = 'Traditional'
),

spec_k_2017 as (
  select 
    sr.recipient_id, 
    array_to_string(array_agg(distinct sr.reporting_name),';') as spec_k_provider_2017, 
    array_to_string(array_agg(distinct sr.applicant_name),';') as spec_k_applicant_2017
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
  group by 1
),

dist_2017 as (
  select dd.*,
    current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
    case
      when spec_k_2017.recipient_id is not null
        then true
      else false
    end as spec_k_2017,
    spec_k_provider_2017,
    spec_k_applicant_2017
  from fy2017_districts_deluxe_matr dd
  left join spec_k_2017
  on dd.esh_id = spec_k_2017.recipient_id
  where include_in_universe_of_districts
  and district_type = 'Traditional'
),

comparison as (
  select
    dist_2017.esh_id,
    dist_2017.name,
    dist_2017.postal_cd,
    dist_2016.locale,
    dist_2017.num_students,
    dist_2017.num_campuses,
    dist_2017.num_schools,
    dist_2017.exclude_from_ia_analysis,
    dist_2016.service_provider_assignment as service_provider_assignment_2016,
    case
      when dist_2017.spec_k_2017 is null
        then false
      else dist_2017.spec_k_2017
    end as spec_k_2017,
    spec_k_provider_2017,
    spec_k_applicant_2017,
    dist_2016.fiber_target_status as fiber_target_status_2016,
    dist_2017.fiber_target_status as fiber_target_status_2017,
    case
      when dist_2017.unscalable_campuses is null 
        then dist_2016.unscalable_campuses
      when dist_2016.unscalable_campuses is null 
        then -dist_2017.unscalable_campuses
      else dist_2016.unscalable_campuses - dist_2017.unscalable_campuses
    end as lost_unscalable_campuses,  
    case
      when dist_2017.num_campuses is null 
        then dist_2016.num_campuses
      when dist_2016.num_campuses is null or dist_2016.num_campuses - dist_2017.num_campuses < 0 
        then 0
      else dist_2016.num_campuses - dist_2017.num_campuses
    end as lost_campuses
  from dist_2016
  full outer join dist_2017
  on dist_2016.esh_id = dist_2017.esh_id
)


select
  esh_id,
  name,
  postal_cd,
  locale,
  num_students,
  num_schools,
  num_campuses,
  case
    when exclude_from_ia_analysis = true
      then 'exclude - dirty district' 
    when fiber_target_status_2017 != 'Not Target' 
      then 'exclude - 2017 target status'
    when fiber_target_status_2016 != 'Target' 
      then 'exclude - 2016 target status'
    when service_provider_assignment_2016 is null
      then 'exclude - no 2016 sp assignment'
    when spec_k_provider_2017 is null
      then 'exclude - no special construction'
    else 'include'
  end as calc_inclusion,
  
  spec_k_2017,
  spec_k_applicant_2017,
  spec_k_provider_2017,
  service_provider_assignment_2016,
  not(spec_k_provider_2017 = service_provider_assignment_2016) as spec_k_switcher,
      
  lost_unscalable_campuses as lost_unscalable_campuses,
  case
    when lost_unscalable_campuses < 0
      then 0
    when lost_campuses > lost_unscalable_campuses
      then lost_unscalable_campuses
    else lost_campuses
  end as lost_unscalable_campuses_due_to_lost_campuses,
  case
    when lost_unscalable_campuses < 0
      then lost_unscalable_campuses
    when lost_campuses > lost_unscalable_campuses
      then 0
    else lost_unscalable_campuses - lost_campuses
  end as lost_unscalable_campuses_due_to_reason

from comparison
where lost_unscalable_campuses != 0