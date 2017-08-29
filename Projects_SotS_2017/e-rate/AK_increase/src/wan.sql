with wan_lines as (
  select 
    distinct line_item_id,
    bandwidth_in_mbps,
    case 
      when sr.monthly_circuit_cost_recurring = 0
        then sr.monthly_circuit_cost_total
      else sr.monthly_circuit_cost_recurring
    end as monthly_circuit_cost_mrc_unless_null
    
  from public.fy2017_services_received_matr sr
  join public.fy2017_districts_deluxe_matr d
  on sr.recipient_id = d.esh_id
  where d.include_in_universe_of_districts = true
  and d.district_type = 'Traditional'
  and sr.purpose = 'WAN'
  and sr.inclusion_status = 'clean_with_cost'
  and connect_category = 'Lit Fiber'
  and bandwidth_in_mbps in (1000, 10000)
  and sr.erate = true
  and (not 'special_construction_tag' = any(sr.open_tags) or sr.open_tags is null)
  and sr.monthly_circuit_cost_total != 0
  and d.postal_cd != 'AK'
  and d.exclude_from_ia_analysis = false

),

wan_costs as (

select 
  bandwidth_in_mbps,
  median(monthly_circuit_cost_mrc_unless_null) as median_circuit_cost_rec,
  round(avg(monthly_circuit_cost_mrc_unless_null),0) as avg_circuit_cost_rec
  
from 
  wan_lines
  
group by 1

),

campuses as (

select
  d.esh_id,
  s.campus_id,
  d.num_campuses,
  sum(s.num_students) as num_students,
  sum(s.num_students) * 1.5 as wan_bw_needed,
  case
    when d.num_campuses <= 1 then 0
    when sum(s.num_students) * 1.5 < 1000
      then 1000
    when sum(s.num_students) * 1.5 < 10000
      then 10000
    when sum(s.num_students) * 1.5 >= 10000
      then 20000
  end as wan_round_up_bw_needed
  
from public.fy2017_schools_demog_matr s
join public.fy2017_districts_deluxe_matr d
on s.district_esh_id = d.esh_id

where d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'

group by 
  d.esh_id,
  s.campus_id,
  d.num_campuses

),

wan_total as (

select 
  c.*,
  case
    when c.wan_round_up_bw_needed = 0
      then 0
    when c.wan_round_up_bw_needed > 10000
      then 2*(select max(avg_circuit_cost_rec) from wan_costs)
    else wc.avg_circuit_cost_rec
  end as wan_cost_rec,
  case
    when c.wan_round_up_bw_needed = 0
      then 0
    when c.wan_round_up_bw_needed > 10000
      then 2*(select max(avg_circuit_cost_rec) from wan_costs) * 12
    else wc.avg_circuit_cost_rec * 12
  end as wan_cost_total
  
from campuses c

left join wan_costs wc
on c.wan_round_up_bw_needed = wc.bandwidth_in_mbps
)


select 'Total WAN Cost' as category,
round(sum(wan_cost_total),0) as total_cost
from wan_total
group by 1