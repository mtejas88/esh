/* STEPS 
9. Find 1 Mbps cost, bw/student not in AK
10. Find 1 Mbps bw/student in AK
*/

with ia_lines as (
  select 
    distinct sr.line_item_id,
    sr.bandwidth_in_mbps,
    case 
      when sr.monthly_circuit_cost_recurring = 0
        then sr.monthly_circuit_cost_total * fy2017.frns.discount_rate::numeric/100
      else sr.monthly_circuit_cost_recurring * fy2017.frns.discount_rate::numeric/100
    end as monthly_circuit_cost_mrc_unless_null 
    
  from public.fy2017_services_received_matr sr

  left join public.esh_line_items eli
  on sr.line_item_id = eli.id
  and eli.funding_year = 2017

  left join fy2017.frn_line_items fli
  on eli.frn_complete = fli.line_item

  left join fy2017.frns
  on fli.frn = fy2017.frns.frn

  join public.fy2017_districts_deluxe_matr d
  on sr.recipient_id = d.esh_id
  where d.include_in_universe_of_districts = true
  and d.district_type = 'Traditional'
  and sr.purpose = 'Internet'
  and sr.inclusion_status = 'clean_with_cost'
  and sr.connect_category = 'Lit Fiber'
  and sr.bandwidth_in_mbps in (50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000)
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
postal_cd,
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
where bw.postal_cd != 'AK'

),

ia_total as (

  select esh_id,
  num_students,
  district_size,
  postal_cd,
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
  
  where postal_cd != 'AK'

),

ia_total_ak as (

  select esh_id,
  num_students,
  district_size,
  postal_cd,
  rounded_bw_meet_1_mbps_oversub

  from bw_lookup
  
  where postal_cd = 'AK'

)

select 'Total IA Cost (No AK) 1 Mbps' as category,
(postal_cd = 'AK') as postal_cd_AK,
sum(avg_circuit_cost_total) as total_cost,
round(sum(rounded_bw_meet_1_mbps_oversub) / sum(num_students), 4) as wtd_avg_bw_student_no_concurrency
from ia_total
where postal_cd != 'AK'
group by 1, 2

union

select 'Total IA Cost (AK) 1 Mbps' as category,
(postal_cd = 'AK') as postal_cd_AK,
null as total_cost,
round(sum(rounded_bw_meet_1_mbps_oversub) / sum(num_students), 4) as wtd_avg_bw_student_no_concurrency
from ia_total_ak
group by 1, 2

/* Methodology 
0. Find % clean SR $ that are IA in AK
1. Find % clean SR $ that are IA not in AK
2. Find total $ in SR
3. Find total $ in SR in AK
4. Find extrap $ IA in AK (0 * 3)
5. Find total $ in SR not in AK (2 - 3)
6. Find extrap $ IA not in AK (5 * 1)
7. Find wtd avg bw/student in AK in 0
8. Find wtd avg bw/student not in AK in 1
9. Find 1 Mbps cost, bw/student not in AK
10. Find 1 Mbps bw/student in AK
11. Find change in cost, change in BW not in AK (6,8,9)
12. Find change in BW in AK (7, 10)
13. Find 1 Mbps cost in AK (4, 11, 12)
14. Find WAN for everyone
*/