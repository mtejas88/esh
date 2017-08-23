with ia_lines as (
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
  and sr.purpose = 'Internet'
  and sr.inclusion_status = 'clean_with_cost'
  and connect_category = 'Lit Fiber'
  and bandwidth_in_mbps in (50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000)
  and sr.erate = true
  and (not 'special_construction_tag' = any(sr.open_tags) or sr.open_tags is null)
  and sr.monthly_circuit_cost_total != 0
  and d.postal_cd != 'AK'
  and d.exclude_from_ia_analysis = false

),

ia_costs as (

select 
  bandwidth_in_mbps,
  median(monthly_circuit_cost_mrc_unless_null) as median_circuit_cost_rec,
  round(avg(monthly_circuit_cost_mrc_unless_null),0) as avg_circuit_cost_rec,
  count(line_item_id) as num_lines
  
from 
  ia_lines

where bandwidth_in_mbps <= 10000
group by 1
order by 1

),

bw_lookup as (

select esh_id,
num_students,
district_size,
case 
  when district_size in ('Medium','Large','Mega') 
    then 0.7
  else 1 
end as setda_concurrency_factor,
num_students * case 
          when district_size in ('Medium','Large','Mega') 
            then 0.7
          else 1 
        end as bw_meet_1_mbps_oversub,
ceil((num_students * case 
                        when district_size in ('Medium','Large','Mega') 
                          then 0.7
                        else 1 
                      end)/100)*100 as rounded_hundred_bw_meet_1_mbps_oversub,
case
  when (num_students *  case 
                          when district_size in ('Medium','Large','Mega') 
                            then 0.7
                          else 1 
                        end) < 500
      --round up to nearest hundred if bw need is less than 500
      then ceil((num_students * case 
                                  when district_size in ('Medium','Large','Mega') 
                                    then 0.7
                                  else 1 
                                end)/100)*100
  when (num_students *  case 
                          when district_size in ('Medium','Large','Mega') 
                            then 0.7
                          else 1 
                        end) < 5000
  --round up to nearest thousand if bw need is < 5000
      then ceil((num_students * case 
                              when district_size in ('Medium','Large','Mega') 
                                then 0.7
                              else 1 
                            end)/1000)*1000
  --round to nearest ten thouand
  else ceil((num_students * case 
                              when district_size in ('Medium','Large','Mega') 
                                then 0.7
                              else 1 
                            end)/10000)*10000
end as rounded_bw_meet_1_mbps_oversub

from public.fy2017_districts_deluxe_matr d17

where include_in_universe_of_districts = true
and district_type = 'Traditional'

),

ia_temp as (

select --distinct rounded_bw_meet_1_mbps_oversub
  bw.*,
  ia.avg_circuit_cost_rec
from bw_lookup bw
left join ia_costs ia
on bw.rounded_bw_meet_1_mbps_oversub = ia.bandwidth_in_mbps

),

ia_total as (

  select esh_id,
  num_students,
  district_size,
  rounded_bw_meet_1_mbps_oversub,
  case 
    when avg_circuit_cost_rec is null
      then rounded_bw_meet_1_mbps_oversub / 10000 * (select max(avg_circuit_cost_rec) from ia_costs)
    else avg_circuit_cost_rec
  end as avg_circuit_cost_rec,
  case 
    when avg_circuit_cost_rec is null
      then 12*rounded_bw_meet_1_mbps_oversub / 10000 * (select max(avg_circuit_cost_rec) from ia_costs)
    else 12*avg_circuit_cost_rec
  end as avg_circuit_cost_total

  from ia_temp

),

wan_lines as (
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

select 'Total IA Cost' as category,
sum(avg_circuit_cost_total) as total_cost
from ia_total
group by 1

union

select 'Total WAN Cost' as category,
round(sum(wan_cost_total),0) as total_cost
from wan_total
group by 1


/*METHODOLOGY 
Internet:
Determining the bandwidth a district should receive based on meeting 1 Mbps with concurrency (using SETDA)
Using the average pricing to see how much it would cost for this bandwidth
WAN:
Use the average price of a 1 Gbps circuit and $a 10 Gbps circuit
Keep the assumption that all single-campus districts don't need a WAN
Assume 1 WAN line per campus for multi-campus districts (except for the one district that needs 2 10gbps)
Keep the assumption that every campus needs 1.5 mbps / student for WAN and assign them either a 1 Gbps WAN or 10 Gbps WAN based on their student count
except for the one district that needs two 10gbps wans 
*/