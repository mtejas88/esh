select
  fiber_470_from_current_applicant > 0 as fiber_470_applied,
  fiber_470_from_current_applicant_zero_bids > 0 fiber_470_applied_zero_bids,
  sum(unscalable_campuses) as unscalable_campuses
from(
  select
    district_applicants.esh_id,
    district_applicants.unscalable_campuses,
    sum(case
          when fiber_470_applicants.applicant_ben is not null
            then 1
          else 0
        end) as fiber_470_from_current_applicant,
    sum(case
          when zero_bids= true
            then 1
          else 0
        end) as fiber_470_from_current_applicant_zero_bids
  from (
    select 
      distinct  dd.esh_id, 
                eb.ben as applicant_ben,
                dd.current_assumed_unscalable_campuses + dd.current_known_unscalable_campuses as unscalable_campuses
    from fy2017_districts_deluxe_matr dd
    join fy2017_services_received_matr sr
    on dd.esh_id= sr.recipient_id
    join public.entity_bens eb
    on sr.applicant_id = eb.entity_id
    where dd.include_in_universe_of_districts
    and dd.district_type = 'Traditional'
    and dd.fiber_target_status = 'Target'
  ) district_applicants
  left join (
    select  distinct 
              "BEN" as applicant_ben,
              case
                when frns.establishing_fcc_form470 is null
                  then true
                else false
              end as zero_bids
    from fy2017.form470s 
    left join fy2017.frns 
    on form470s."470 Number" = frns.establishing_fcc_form470::int
    where "Service Type" = 'Internet Access and/or Telecommunications'
    and "Function" not in ('Internet Access: ISP Service Only', 'Other')
    and ("Function" ilike '%fiber%' 
        or left("Minimum Capacity",length("Minimum Capacity")-5)::numeric >= 200)
  ) fiber_470_applicants
  on district_applicants.applicant_ben = fiber_470_applicants.applicant_ben  
  group by 1,2
) districts_fiber_applications
group by 1,2