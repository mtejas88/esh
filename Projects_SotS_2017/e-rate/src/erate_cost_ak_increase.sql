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

ia_lines_ak as (
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
  and bandwidth_in_mbps in (100, 500, 1000)
  and sr.erate = true
  and (not 'special_construction_tag' = any(sr.open_tags) or sr.open_tags is null)
  and sr.monthly_circuit_cost_total != 0
  and d.postal_cd = 'AK'
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

ia_costs_ak as (

select 
  bandwidth_in_mbps,
  median(monthly_circuit_cost_mrc_unless_null) as median_circuit_cost_rec,
  round(avg(monthly_circuit_cost_mrc_unless_null),0) as avg_circuit_cost_rec,
  count(line_item_id) as num_lines
  
from 
  ia_lines_ak

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

union

select --distinct rounded_bw_meet_1_mbps_oversub
  bw.*,
  --using median in AK because the average is way too high and the sample size is pretty small so it's skewed
  round(ia.median_circuit_cost_rec::numeric,0) as avg_circuit_cost_rec
from bw_lookup bw
left join ia_costs_ak ia
on bw.rounded_bw_meet_1_mbps_oversub = ia.bandwidth_in_mbps
where bw.postal_cd = 'AK'

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
  
  union

  select esh_id,
  num_students,
  district_size,
  postal_cd,
  rounded_bw_meet_1_mbps_oversub,
  case 
    when avg_circuit_cost_rec is null and rounded_bw_meet_1_mbps_oversub < 500
      then (select distinct avg_circuit_cost_rec from ia_costs_ak where bandwidth_in_mbps = 500)
    when avg_circuit_cost_rec is null and rounded_bw_meet_1_mbps_oversub > 1000
      then rounded_bw_meet_1_mbps_oversub / 1000 * (select distinct avg_circuit_cost_rec from ia_costs_ak where bandwidth_in_mbps = 1000)
    else avg_circuit_cost_rec
  end as avg_circuit_cost_rec,
  case 
    when avg_circuit_cost_rec is null and rounded_bw_meet_1_mbps_oversub < 500
      then 12 * (select distinct avg_circuit_cost_rec from ia_costs_ak where bandwidth_in_mbps = 500)
    when avg_circuit_cost_rec is null and rounded_bw_meet_1_mbps_oversub > 1000
      then 12 * rounded_bw_meet_1_mbps_oversub / 1000 * (select distinct avg_circuit_cost_rec from ia_costs_ak where bandwidth_in_mbps = 1000)
    else 12 * avg_circuit_cost_rec
  end as avg_circuit_cost_total

  from ia_temp
  
  where postal_cd = 'AK'

),

li_lookup as (
  select line_item_id, 
  recipient_id,
  case 
    when purpose = 'WAN' 
      then 'WAN' 
    else 'Internet' 
  end as purpose_adj,
  line_item_district_mrc_unless_null
  
  from public.fy2017_services_received_matr sr
  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  
  where dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'
  and dd.exclude_from_ia_analysis = false
  and dd.exclude_from_ia_cost_analysis = false
  and inclusion_status != 'dqs_excluded'
  and erate = true
  and broadband = true
  --and the district doesn't have any restricted cost line items
  and sr.recipient_id not in (
    select distinct recipient_id
    from public.fy2017_services_received_matr sr
    where inclusion_status != 'dqs_excluded'
    and ('exclude_for_cost_only_restricted' = any(sr.open_tags)
          or 'exclude_for_cost_only_unknown' = any(sr.open_tags))
  )

),

perc_lookup as (

  select distinct
    purpose_adj,
    sum(line_item_district_mrc_unless_null) over (partition by purpose_adj) as monthly_cost,
    sum(line_item_district_mrc_unless_null) over (partition by purpose_adj)::numeric / 
      sum(line_item_district_mrc_unless_null) over ()::numeric as perc_monthly_cost


  from li_lookup

),

lines_no_ak as (

  select line_item_id,
    recipient_id,
    line_item_district_mrc_unless_null

  from public.fy2017_services_received_matr sr

  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id

  where inclusion_status != 'dqs_excluded'
  and dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'
  and dd.postal_cd != 'AK'

),

cost_no_ak as (
  select round(sum(line_item_district_mrc_unless_null * 12),0) as total_costs
  from lines_no_ak
),


final_costs_no_ak as (
  select
    purpose_adj,
    round(perc_monthly_cost * total_costs,0) as extrap_total_cost

  from cost_no_ak
  join perc_lookup
  on true
),

bw_no_ak as (
  select distinct recipient_id,
  dd.num_students,
  dd.ia_bw_mbps_total
  
  from li_lookup
  
  left join public.fy2017_districts_deluxe_matr dd
  on li_lookup.recipient_id = dd.esh_id
  
  where dd.postal_cd != 'AK'
),

bw_no_ak_total as (
  select sum(ia_bw_mbps_total)::numeric / sum(num_students)::numeric as wtd_avg
  from bw_no_ak
),

comparison as (


select 'Total IA Cost (No AK) 1 Mbps' as category,
sum(avg_circuit_cost_total) as total_cost,
round(sum(rounded_bw_meet_1_mbps_oversub) / sum(num_students), 4) as wtd_avg_bw_student_no_concurrency
from ia_total
where postal_cd != 'AK'
group by 1

union 

select 'Total IA Cost (No AK) Current' as category,
extrap_total_cost as total_cost,
round(wtd_avg, 4) as wtd_avg_bw_student_no_concurrency

from final_costs_no_ak
join bw_no_ak_total
on true

where purpose_adj = 'Internet'

),

bw_cost_inc as (

select ((max(total_cost) - min(total_cost) )/ min(total_cost)) /
  ((max(wtd_avg_bw_student_no_concurrency) - min(wtd_avg_bw_student_no_concurrency) )/ min(wtd_avg_bw_student_no_concurrency)) as cost_inc_over_bw_inc

from comparison

),

lines_ak as (

  select line_item_id,
    recipient_id,
    line_item_district_mrc_unless_null

  from public.fy2017_services_received_matr sr

  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id

  where inclusion_status != 'dqs_excluded'
  and dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'
  and dd.postal_cd = 'AK'

),

cost_ak as (
  select round(sum(line_item_district_mrc_unless_null * 12),0) as total_costs
  from lines_ak
),


final_costs_ak as (
  select
    purpose_adj,
    round(perc_monthly_cost * total_costs,0) as extrap_total_cost

  from cost_ak
  join perc_lookup
  on true
),

bw_ak as (
  select distinct recipient_id,
  dd.num_students,
  dd.ia_bw_mbps_total
  
  from li_lookup
  
  left join public.fy2017_districts_deluxe_matr dd
  on li_lookup.recipient_id = dd.esh_id
  
  where dd.postal_cd = 'AK'
),

bw_ak_total as (
  select sum(ia_bw_mbps_total)::numeric / sum(num_students)::numeric as wtd_avg
  from bw_ak
),

new_ak_cost as (
  select round((1 + cost_inc_over_bw_inc ) * extrap_total_cost,0) as total_cost
  from bw_cost_inc
  join final_costs_ak
  on true
  and purpose_adj = 'Internet'

)

select 'Total IA Cost (AK) Current' as category,
extrap_total_cost as total_cost,
round(wtd_avg, 4) as wtd_avg_bw_student_no_concurrency

from final_costs_ak
join bw_ak_total
on true

where purpose_adj = 'Internet'

union 

select *
from comparison

union

select 'Total IA Cost (AK) 1 Mbps' as category,
(select total_cost from new_ak_cost) as total_cost,
round(sum(rounded_bw_meet_1_mbps_oversub) / sum(num_students), 4) as wtd_avg_bw_student_no_concurrency
from ia_total
--join new_ak_cost
--on true
where postal_cd = 'AK'
group by 1,2


/* Methodology 
0. Find % clean SR $ that are IA in AK
1. Find % clean SR $ that are IA not in AK
2. Find total $ in SR
3. Find total $ in SR in AK
4. Find extrap $ IA in AK (0 * 3)
5. Find total $ in SR not in AK (2 - 3)
6. Find extrap $ IA not in AK (5 * 1)
7. Find wtd avg bw/student in AK
8. Find wtd avg bw/student not in AK
9. Find 1 Mbps cost, bw/student not in AK
10. Find 1 Mbps bw/student in AK
11. Find change in cost, change in BW not in AK (6,8,9)
12. Find change in BW in AK (7, 10)
13. Find 1 Mbps cost in AK (4, 11, 12)
14. Find WAN for everyone
*/