with districts_broadband_applications as (
  select
    district_applicants.esh_id,broadband_470_applicants."Minimum Capacity",
    broadband_470_applicants."Maximum Capacity",
    sum(case
          when broadband_470_applicants.applicant_ben is not null
            then 1
          else 0
        end) as broadband_470_from_current_applicant,
    sum(case
          when zero_bids= true
            then 1
          else 0
        end) as broadband_470_from_current_applicant_zero_bids


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
              end as zero_bids,
              "Minimum Capacity",
              "Maximum Capacity"
    from fy2017.form470s
    left join fy2017.frns
    on form470s."470 Number" = frns.establishing_fcc_form470::int
    where "Service Type" = 'Internet Access and/or Telecommunications'
    and "Function" not ilike '%voice%'
    and "Function" not ilike '%cellular%'
    and "Function" != 'Other'

  ) broadband_470_applicants
  on district_applicants.applicant_ben = broadband_470_applicants.applicant_ben
  group by 1, 2, 3
),
extrapolated_students_not_meeting as (
	select sum(	case
					when exclude_from_ia_analysis= false
						then num_students
					else 0
				end)/sum(num_students)::numeric as extrapolate_pct,
sum(  case
          when exclude_from_ia_analysis= false
            then 1
          else 0
        end)/sum(1)::numeric as extrapolate_pct_district
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'

)

select
dd.esh_id,
dd.num_students,
dd.num_schools,
sra.recipient_ia_bw_mbps_total as "bw_received",
dba."Minimum Capacity" as "min_bw_requested",
dba."Maximum Capacity" as "max_bw_requested"

from public.fy2017_districts_deluxe_matr dd
left join public.fy2017_services_received_matr sra
on dd.esh_id = sra.recipient_id
join public.fy2017_districts_aggregation_matr da
on dd.esh_id = da.district_esh_id
left join districts_broadband_applications dba
on dd.esh_id = dba.esh_id
join public.states s
on dd.postal_cd = s.postal_cd
join extrapolated_students_not_meeting
on true
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and exclude_from_ia_analysis= false
and meeting_2014_goal_no_oversub = false
group by 1, 2, 3, 4, 5, 6
order by 1 desc
