with districts_fiber_applications as (
  select
    district_applicants.esh_id,
    sum(case
          when fiber_470_applicants.applicant_ben is not null
            then 1
          else 0
        end) as fiber_470_from_current_applicant,
    sum(case
          when zero_bids = true
            then 1
          else 0
        end) as num_fiber_470s_with_0_bids
  from (
    select 
      distinct  dd.esh_id, 
                eb.ben as applicant_ben
    from fy2017_districts_deluxe_matr dd
    join fy2017_services_received_matr sr
    on dd.esh_id= sr.recipient_id
    join public.fy2017_esh_line_items_v li
    on sr.line_item_id = li.id
    join public.entity_bens eb
    on sr.applicant_id = eb.entity_id
    where dd.include_in_universe_of_districts
    and dd.district_type = 'Traditional'
  ) district_applicants
  left join (
    select  distinct 
              "BEN" as applicant_ben,
              case
                when frns.establishing_fcc_form470 is null or frns.num_bids_received::numeric > 0
                  then true
                else false
              end as zero_bids
    from fy2017.form470s 
    left join fy2017.frns 
    on form470s."470 Number" = frns.establishing_fcc_form470::int
    where "Service Type" = 'Internet Access and/or Telecommunications'
    and "Function" not in ( 'Internet Access: ISP Service Only', 'Other', 'Cellular Data Plan/Air Card Service', 
                            'Cellular Voice', 'Voice Service (Analog, Digital, Interconnected VOIP, etc)')
    and ("Function" ilike '%fiber%' 
        or left("Minimum Capacity",length("Minimum Capacity")-5)::numeric >= 200
        or right("Minimum Capacity",4)= 'Gbps')
  ) fiber_470_applicants
  on district_applicants.applicant_ben = fiber_470_applicants.applicant_ben  
  group by 1
),
extrapolated_unscalable_campuses as (
	select sum(	case
      					when exclude_from_ia_analysis= false and fiber_target_status in ('Target', 'Potential Target')
      						then current_assumed_unscalable_campuses + current_known_unscalable_campuses
      					else 0
      				end)/sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)::numeric as extrapolate_pct
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
)

select
  dfa.esh_id is not null as fiber_form_470,
  dfa.num_fiber_470s_with_0_bids = 0 or dfa.num_fiber_470s_with_0_bids is null as zero_bids,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses) as num_unscalable_campuses_sample,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)/extrapolate_pct 
    as num_unscalable_campuses_extrap
from public.fy2017_districts_deluxe_matr dd
left join districts_fiber_applications dfa
on dd.esh_id = dfa.esh_id
join extrapolated_unscalable_campuses 
on true
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and fiber_target_status = 'Target'
group by 1, 2, extrapolate_pct
order by 3 desc