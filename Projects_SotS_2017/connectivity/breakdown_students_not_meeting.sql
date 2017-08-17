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
--one update from source to remove $0 cost line items
  and inclusion_status = 'clean_with_cost'
  and connect_category in ('Lit Fiber', 'Dark Fiber')
  and purpose in ('Internet', 'Upstream')),

districts_peer as (
  select dd.esh_id, 
    count(distinct ia_cost_per_mbps_scalable) as num_prices_to_meet_goals_with_same_budget
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
  sum(num_students::numeric) as num_students_sample,
  sum(1) as num_districts_sample,
  round((sum(num_students::numeric)/extrapolate_pct)/1000000,1) as num_students_extrap_mill,
  sum(1)/extrapolate_pct_district as num_districts_extrap
from districts_categorized
join extrapolated_students_not_meeting 
on true
group by 1, extrapolate_pct, extrapolate_pct_district
order by 3 desc