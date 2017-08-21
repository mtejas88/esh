with lookup as (

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
											end)/100)*100 as rounded_bw_meet_1_mbps_oversub

from public.fy2017_districts_deluxe_matr d17

where include_in_universe_of_districts = true
and district_type = 'Traditional'

),

knapsack_ia as (

select *,
case
  --the knapsack_budget does not take into account circuit sizes less than 50 mbps
  --so for districts with less than 50 students, they will be at $14/mbps to meet 1mbps 
  --(no oversub needed for these districts)
  when num_students < 50
    then 14 * num_students
  else knapsack_budget(rounded_bw_meet_1_mbps_oversub::integer)
end as knapsack_budget_to_meet_1_mbps_oversub_rounded,
12*case
  --the knapsack_budget does not take into account circuit sizes less than 50 mbps
  --so for districts with less than 50 students, they will be at $14/mbps to meet 1mbps 
  --(no oversub needed for these districts)
  when num_students < 50
    then 14 * num_students
  else knapsack_budget(rounded_bw_meet_1_mbps_oversub::integer)
end as knapsack_budget_to_meet_1_mbps_oversub_rounded_annual

from lookup

),

wan_total as (
  select 
    d.esh_id,
    s.campus_id,
    d.num_campuses,
    sum(s.num_students) as num_students,
    sum(s.num_students) * 1.5 as wan_bw_needed,
    case
      when d.num_campuses = 1
        then 0
      when sum(s.num_students) * 1.5 <= 1000
        then 750
      when sum(s.num_students) * 1.5 <= 10000
        then 1000
      --there is one district that needs 11.4Gbps of WAN so giving them 2 10gbps
      else 2000
    end as wan_cost
  from public.fy2017_schools_demog_matr s
  join public.fy2017_districts_deluxe_matr d
  on s.district_esh_id = d.esh_id

  where d.include_in_universe_of_districts = true
  and d.district_type = 'Traditional'

  group by 
    d.esh_id,
    s.campus_id,
    d.num_campuses
)

select 'Total IA Cost' as category,
sum(knapsack_budget_to_meet_1_mbps_oversub_rounded_annual) as total_cost
from knapsack_ia
group by 1

union

select 'Total WAN Cost' as category,
round(sum(wan_cost) * 12,0) as total_cost
from wan_total
group by 1


/*METHODOLOGY
Internet:
Determining the bandwidth a district should receive based on meeting 1 Mbps with concurrency (using SETDA)
Using the knapsack pricing to see how much it would cost for this bandwidth
WAN:
Keep the assumption of $750 for a 1 Gbps circuit and $1,000 for a 10 Gbps circuit
Keep the assumption that all single-campus districts don't need a WAN
Assume 1 WAN line per campus for multi-campus districts
Keep the assumption that every campus needs 1.5 mbps / student for WAN and assign them either a 1 Gbps WAN or 10 Gbps WAN based on their student count
except for the one district that needs two 10gbps wans 
*/