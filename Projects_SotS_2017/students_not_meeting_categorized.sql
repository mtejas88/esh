with districts_broadband_applications as (
  select
    district_applicants.esh_id,
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
              end as zero_bids
    from fy2017.form470s 
    left join fy2017.frns 
    on form470s."470 Number" = frns.establishing_fcc_form470::int
    where "Service Type" = 'Internet Access and/or Telecommunications'
    and "Function" not ilike '%voice%'
    and "Function" not ilike '%cellular%'
    and "Function" != 'Other'
  ) broadband_470_applicants
  on district_applicants.applicant_ben = broadband_470_applicants.applicant_ben  
  group by 1
),
extrapolated_students_not_meeting as (
	select sum(	case
					when exclude_from_ia_analysis= false
						then num_students
					else 0
				end)/sum(num_students)::numeric as extrapolate_pct
	from fy2017_districts_deluxe_matr
	where include_in_universe_of_districts
	and district_type = 'Traditional'

)


select
  case
    when current_assumed_unscalable_campuses+current_known_unscalable_campuses > 0
    or hierarchy_ia_connect_category != 'Fiber'
      then 'non-fiber'
    when (case
            when ia_monthly_cost_total < 14*50 and ia_monthly_cost_total > 0
              then ia_monthly_cost_total/14
            else knapsack_bandwidth(ia_monthly_cost_total)
          end*1000/dd.num_students) >= 100
      then 'affordability'
    when meeting_2014_goal_oversub = true
      then 'concurrency'
    when dd.postal_cd in ('AK', 'NE', 'TN', 'KY', 'FL', 'HI', 'SD')
      then 'no governor commitment'
    when procurement != 'District-procured'
      then 'state or regional network'
    when broadband_470_from_current_applicant > 0
      then 'filed 470 for broadband'
    when district_size in ('Large', 'Mega')
      then 'more internet bw needed per WAN' 
    when ia_bw_mbps_total < 1000 and (1000000*dd.fiber_internet_upstream_lines)/num_students::numeric >= 100
      then 'upgrade fiber to 1G'
    when (upstream_bandwidth > 0 and isp_bandwidth > 0 and upstream_bandwidth != isp_bandwidth)
    and (((upstream_bandwidth+internet_bandwidth)*1000)/num_students::numeric >= 100 or ((isp_bandwidth+internet_bandwidth)*1000)/num_students::numeric >= 100)
      then 'mismatched ISP/upstream'
    else 'unknown'
  end as diagnosis,
  sum(dd.num_students::numeric) as num_students_sample,
  round((sum(dd.num_students::numeric)/extrapolate_pct)/1000000,1) as num_students_extrap_mill
from public.fy2017_districts_deluxe_matr dd
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
group by 1, extrapolate_pct
order by 3 desc