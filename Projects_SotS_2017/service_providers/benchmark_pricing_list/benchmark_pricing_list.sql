/*
Author: Jamie Barnes
Date: 8/22/2017
Purpose: List of the primary service providers on districts that would be meeting the 100 kbps/student goal
if they received the bandwidth they are paying for based off of pricing benchmarks. 
*/

select service_provider_assignment,
count(esh_id) as districts,
sum(num_students) as students,
array_agg(distinct postal_cd) as states

from public.fy2017_districts_deluxe_matr 

where include_in_universe_of_districts = true
and district_type = 'Traditional'
and exclude_from_ia_analysis = false
and exclude_from_ia_cost_analysis = false
and service_provider_assignment is not null

and meeting_2014_goal_no_oversub = false 

/* limiting to districts that would be meeting if they received knapsack bandwidth*/
and (
      (ia_monthly_cost_total < 700 and ((ia_monthly_cost_total/14)*1000)/num_students >= 100) /* knapsack bandwidth function does not work for monthly costs below $700*/ 
  or  (ia_monthly_cost_total >= 700 and (knapsack_bandwidth(ia_monthly_cost_total)*1000/num_students) >= 100)
    )  

group by service_provider_assignment

order by sum(num_students) desc