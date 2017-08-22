with districts_fiber_applications as (
  select
    district_applicants.esh_id,
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
    and li.applicant_type in ('School', 'District')
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
    and "Function" not in ( 'Internet Access: ISP Service Only', 'Other', 'Cellular Data Plan/Air Card Service', 
                            'Cellular Voice', 'Voice Service (Analog, Digital, Interconnected VOIP, etc)')
    and ("Function" ilike '%fiber%' 
        or left("Minimum Capacity",length("Minimum Capacity")-5)::numeric >= 200
        or right("Minimum Capacity",4)= 'Gbps')
  ) fiber_470_applicants
  on district_applicants.applicant_ben = fiber_470_applicants.applicant_ben  
  group by 1
),
total_unscalable_campuses as (
	select sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses) as unscalable_campuses
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'
  and fiber_target_status = 'Target'
),
districts as (
select 
  dd.*, 
  dfa.fiber_470_from_current_applicant
from public.fy2017_districts_deluxe_matr dd
left join districts_fiber_applications dfa
on dd.esh_id = dfa.esh_id
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and fiber_target_status = 'Target'
)


select
  'state match fund pending approval' as category,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)/unscalable_campuses::numeric 
    as pct_campuses
from districts
join total_unscalable_campuses 
on true
where postal_cd in ('MT', 'MD', 'MA', 'MO', 'NH', 'TX')
group by 1, unscalable_campuses

UNION

select
  'state match fund' as category,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)/unscalable_campuses::numeric 
    as pct_campuses
from districts
join total_unscalable_campuses 
on true
where postal_cd in ('MT', 'ID', 'MN', 'KS', 'IL', 'MD', 'MA', 'MO', 'NH', 
                    'AZ', 'VA', 'NC', 'TX', 'CA', 'NM', 'NY', 'OK', 'FL', 'ME')
group by 1, unscalable_campuses

UNION

select
  'governor commitment' as category,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)/unscalable_campuses::numeric 
    as pct_campuses
from districts
join total_unscalable_campuses 
on true
where postal_cd not in ('AK', 'NE', 'TN', 'KY', 'FL', 'HI', 'SD')
group by 1, unscalable_campuses

UNION

select
  'filed 470 for fiber' as category,
  sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)/unscalable_campuses::numeric 
    as pct_campuses
from districts
join total_unscalable_campuses 
on true
where fiber_470_from_current_applicant > 0
group by 1, unscalable_campuses