with districts_2017 as (
  select *,
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
    end as district_size_number
  from fy2017_districts_deluxe_matr
  where include_in_universe_of_districts
  and district_type = 'Traditional'
), 

extrapolated_students_not_meeting as (
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
  from districts_2017

), 

-- from https://github.com/educationsuperhighway/ecto/blob/master/db_ecto/material_girl/endpoint/fy2017/fy2017_scalable_line_items_v01.sql
-- scalable_ia: 
scalable_ia_temp as (
  select 
    recipient_id,
    recipient_postal_cd,
    dd.ulocal as recipient_ulocal,
    dd.district_size_number as recipient_district_size_number,
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
  join districts_2017 dd
  on sr.recipient_id = dd.esh_id
  where recipient_include_in_universe_of_districts = TRUE
  and recipient_exclude_from_ia_analysis = FALSE
  and inclusion_status = 'clean_with_cost'
  and connect_category in ('Lit Fiber', 'Dark Fiber')
  and purpose in ('Internet', 'Upstream')),

districts_peer as (
  select dd.esh_id, 
    count(distinct round(ia_cost_per_mbps_scalable::numeric,2)) as num_prices_to_meet_goals_with_same_budget,
    count(distinct recipient_id) as num_districts_w_prices_to_meet_goals_with_same_budget,
    count(distinct line_item_id_scalable_ia) as num_line_items_to_meet_goals_with_same_budget,
    array_agg(distinct recipient_id) as districts_w_prices_to_meet_goals_with_same_budget,
    array_agg(distinct round(ia_cost_per_mbps_scalable::numeric,2)) as prices_to_meet_goals_with_same_budget,
    array_agg(distinct line_item_id_scalable_ia) as line_items_to_meet_goals_with_same_budget,
    count(distinct  case
                      when abs(dd.ulocal::numeric - scalable_ia_temp.recipient_ulocal::numeric) < 15
                      and abs(dd.district_size_number::numeric - scalable_ia_temp.recipient_district_size_number::numeric) < 15
                        then round(ia_cost_per_mbps_scalable::numeric,2)
                    end) as num_prices_to_meet_goals_with_same_budget_demog_constraint
  from districts_2017 dd
  join scalable_ia_temp
--in the same state
  on dd.postal_cd = scalable_ia_temp.recipient_postal_cd
--costs less than or equal to what the district is spending
  and dd.ia_monthly_cost_total >= scalable_ia_temp.monthly_circuit_cost_recurring_scalable_ia
--bw is more than or equal to what the district needs to meet 100 kbps/student
  and dd.num_students * .1 <= scalable_ia_temp.bandwidth_in_mbps_scalable_ia
  where dd.exclude_from_ia_analysis= false
  and dd.meeting_2014_goal_no_oversub = false
  group by 1
),

districts_categorized as (
  select 
    dd.*, 
    districts_peer.num_prices_to_meet_goals_with_same_budget,
    districts_peer.num_districts_w_prices_to_meet_goals_with_same_budget,
    districts_peer.num_line_items_to_meet_goals_with_same_budget,
    districts_peer.num_prices_to_meet_goals_with_same_budget_demog_constraint,
    array_to_string(districts_peer.districts_w_prices_to_meet_goals_with_same_budget,';') as districts_w_prices_to_meet_goals_with_same_budget,
    array_to_string(districts_peer.prices_to_meet_goals_with_same_budget,';') as prices_to_meet_goals_with_same_budget,
    array_to_string(districts_peer.line_items_to_meet_goals_with_same_budget,';') as line_items_to_meet_goals_with_same_budget,
    (dd.num_students*.1) as bandwidth_needed,
    case
      when ia_monthly_cost_total > 0
        then (ia_bw_mbps_total / (dd.num_students*.1)::numeric) - 1
    end as pct_price_decrease_til_bw_needed,
    case
      when dd.num_students < 500
        then 14*dd.num_students*.1
      else knapsack_budget((dd.num_students*.1)::integer)
    end*(1-discount_rate_c1_matrix) as knapsack_budget_oop,
    case
      when dd.num_students < 500
        then 14*dd.num_students*.1
      else knapsack_budget((dd.num_students*.1)::integer)
    end*(1-discount_rate_c1_matrix)/dd.num_students as oop_per_student_future,
    ia_monthly_cost_total*(1-discount_rate_c1_matrix)/dd.num_students as oop_per_student_curr,
    (case
      when dd.num_students < 500
        then 14*dd.num_students*.1
      else knapsack_budget((dd.num_students*.1)::integer)
    end - ia_monthly_cost_total)*(1-discount_rate_c1_matrix)/dd.num_students as oop_per_student_incr,
    ceil((most_recent_ia_contract_end_date - DATE '2017-06-30')/365) as contract_end_time,
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
  sum(1) as num_districts_sample,
  round((sum(num_students::numeric)/extrapolate_pct)/1000000,1) as num_students_extrap_mill,
  sum(1)/extrapolate_pct_district as num_districts_extrap,
  case
    when diagnosis in ('meet benchmark prices', 'meet the prices available in your state')
      then median(pct_price_decrease_til_bw_needed)
  end as median_pct_price_decrease_til_bw_needed,
  case
    when diagnosis = 'meet the prices available in your state'
      then median(num_prices_to_meet_goals_with_same_budget)
  end as median_num_prices_to_meet_goals_with_same_budget,
  case
    when diagnosis = 'meet the prices available in your state'
      then sum(case
                when not(num_prices_to_meet_goals_with_same_budget_demog_constraint > 0)
                  then num_students::numeric
                else 0
              end)
  end as num_students_sample_no_prices_demog_constraint,
  case
    when diagnosis = 'meet the prices available in your state'
      then sum(case
                when num_prices_to_meet_goals_with_same_budget_demog_constraint > 0
                and num_prices_to_meet_goals_with_same_budget_demog_constraint <= 2
                  then num_students::numeric
                else 0
              end)
  end as num_students_sample_12_prices_demog_constraint,
  case
    when diagnosis = 'meet the prices available in your state'
      then sum(case
                when num_prices_to_meet_goals_with_same_budget_demog_constraint > 0
                and num_prices_to_meet_goals_with_same_budget_demog_constraint <= 2
                  then 1
                else 0
              end)
  end as num_districts_sample_12_prices_demog_constraint,
  case
    when diagnosis = 'spend more money'
      then median(oop_per_student_incr)
  end as median_oop_per_student_incr,
  case
    when diagnosis = 'spend more money'
      then median(oop_per_student_future)
  end as median_oop_per_student_future,
  sum(num_students::numeric) as num_students_sample
from districts_categorized
join extrapolated_students_not_meeting 
on true
group by 1, extrapolate_pct, extrapolate_pct_district
order by 3 desc