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

)

select sum(knapsack_budget_to_meet_1_mbps_oversub_rounded_annual) as total_ia_cost
from knapsack_ia