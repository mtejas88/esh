with extrapolated_students_not_meeting as (
  select sum( case
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

), 

-- from https://github.com/educationsuperhighway/ecto/blob/master/db_ecto/material_girl/endpoint/fy2017/fy2017_scalable_line_items_v01.sql
-- scalable_ia: 
scalable_ia_temp as (
  select 
    recipient_id,
    recipient_postal_cd,
    dd.ulocal as recipient_ulocal,
    case
      when district_size = 'Tiny'
        then 1
      when district_size = 'Small'
        then 2
      when district_size = 'Medium'
        then 3
      when district_size = 'Large'
        then 4
      when district_size = 'Mega'
        then 5
    end as recipient_district_size_number,
    line_item_id as line_item_id_scalable_ia,
    bandwidth_in_mbps as bandwidth_in_mbps_scalable_ia,
    case
      when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total
      else monthly_circuit_cost_recurring
    end as monthly_circuit_cost_recurring_scalable_ia,
    case
      when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total / bandwidth_in_mbps
      else monthly_circuit_cost_recurring / bandwidth_in_mbps
    end as ia_cost_per_mbps_scalable,
    connect_category as connect_category_scalable_ia,
    service_provider_name as service_provider_name_scalable_ia,
    reporting_name as reporting_name_scalable_ia
  from public.fy2017_services_received_matr sr
  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  where recipient_include_in_universe_of_districts = TRUE
  and recipient_exclude_from_ia_analysis = FALSE
  and inclusion_status = 'clean_with_cost'
  and connect_category in ('Lit Fiber', 'Dark Fiber')
  and purpose in ('Internet', 'Upstream')),

districts_peer as (
  select dd.esh_id, 
    count(distinct ia_cost_per_mbps_scalable) as num_prices_to_meet_goals_with_same_budget,
    count(distinct recipient_id) as num_districts_w_prices_to_meet_goals_with_same_budget,
    array_agg(distinct ia_cost_per_mbps_scalable) as prices_to_meet_goals_with_same_budget,
    array_agg(distinct line_item_id_scalable_ia) as line_items_to_meet_goals_with_same_budget,
    count(distinct  case
                      when abs(dd.ulocal::numeric - scalable_ia_temp.recipient_ulocal::numeric) < 15
                        then ia_cost_per_mbps_scalable
                    end) as num_prices_to_meet_goals_with_same_budget_locale_constraint
  from public.fy2017_districts_deluxe_matr dd
  join scalable_ia_temp
--in the same state
  on dd.postal_cd = scalable_ia_temp.recipient_postal_cd
--costs less than or equal to what the district is spending
  and dd.ia_monthly_cost_total >= scalable_ia_temp.monthly_circuit_cost_recurring_scalable_ia
--bw is more than or equal to what the district needs to meet 100 kbps/student
  and dd.num_students * .1 <= scalable_ia_temp.bandwidth_in_mbps_scalable_ia
  where dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
  and dd.exclude_from_ia_analysis= false
  and dd.meeting_2014_goal_no_oversub = false
  group by 1
),

districts_categorized as (
  select 
    dd.*, 
    districts_peer.num_prices_to_meet_goals_with_same_budget,
    districts_peer.num_districts_w_prices_to_meet_goals_with_same_budget,
    array_to_string(districts_peer.prices_to_meet_goals_with_same_budget,';') as prices_to_meet_goals_with_same_budget,
    array_to_string(districts_peer.line_items_to_meet_goals_with_same_budget,';') as line_items_to_meet_goals_with_same_budget,
    (dd.num_students*.1) as bandwidth_needed,
    case
      when ia_monthly_cost_total > 0
        then (ia_bw_mbps_total / (dd.num_students*.1)::numeric) - 1
    end as pct_price_decrease_til_bw_needed,
    case
      when hierarchy_ia_connect_category != 'Fiber'
        then 'get fiber internet'
      when (case
              when ia_monthly_cost_total < 14*50 and ia_monthly_cost_total > 0
                then ia_monthly_cost_total/14
              else knapsack_bandwidth(ia_monthly_cost_total)
            end*1000/dd.num_students) >= 100
        then 'meet benchmark prices'
      when districts_peer.num_prices_to_meet_goals_with_same_budget > 0
        then 'meet the prices available in your state' 
      else 'spend more money'
    end as diagnosis
  from public.fy2017_districts_deluxe_matr dd
  left join districts_peer
  on dd.esh_id = districts_peer.esh_id
  where dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
  and exclude_from_ia_analysis= false
  and meeting_2014_goal_no_oversub = false
)


select
  diagnosis,
  median(pct_price_decrease_til_bw_needed) as median_pct_price_decrease_til_bw_needed,
  median(num_prices_to_meet_goals_with_same_budget) as median_num_prices_to_meet_goals_with_same_budget,
  median(num_districts_w_prices_to_meet_goals_with_same_budget) as median_num_districts_w_prices_to_meet_goals_with_same_budget,
  sum(num_students::numeric) as num_students_sample,
  sum(1) as num_districts_sample,
  round((sum(num_students::numeric)/extrapolate_pct)/1000000,1) as num_students_extrap_mill,
  sum(1)/extrapolate_pct_district as num_districts_extrap
from districts_categorized
join extrapolated_students_not_meeting 
on true
group by 1, extrapolate_pct, extrapolate_pct_district
order by 3 desc

/*
districts_broadband_applications as (
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
)

    when current_assumed_unscalable_campuses+current_known_unscalable_campuses > 0
    or hierarchy_ia_connect_category != 'Fiber'
      then 'non-fiber'
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

join public.fy2017_districts_aggregation_matr da
on dd.esh_id = da.district_esh_id
left join districts_broadband_applications dba
on dd.esh_id = dba.esh_id
join public.states s
on dd.postal_cd = s.postal_cd


*/