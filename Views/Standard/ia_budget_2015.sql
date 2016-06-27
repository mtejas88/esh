/*
Date Created: Spring 2016
Date Last Modified : 06/27/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: For each district, get national percentage of districts that are getting more bandwidth for the budget, compared to the district.
*/

with districts_formatted as (
          select  *,
                  d.ia_cost_per_mbps::numeric * (d.ia_bandwidth_per_student::numeric/1000) * d.num_students::numeric as ia_annual_cost,
                  (d.ia_bandwidth_per_student::numeric/1000)*d.num_students::numeric as ia_bandwidth
          from public.districts d
          where include_in_universe_of_districts = true
          and exclude_from_analysis = false
          and ia_cost_per_mbps != 'Insufficient data'
)

select  esh_id,
        case
          when (   select count(*)
                    from districts_formatted d_all
                    where d.esh_id != d_all.esh_id
                    /*
                    if district A has an IA budget that falls within 20% threshold of district B's IA budget,
                    district A and district B are effectively treates as having the same budget
                    */ 
                    and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
                    and d.ia_annual_cost > d_all.ia_annual_cost*.8

          ) = 0 then 0
            else
                (   select count(*)
                    from districts_formatted d_all
                    where d.esh_id != d_all.esh_id
                    and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
                    and d.ia_annual_cost> d_all.ia_annual_cost*.8
                    /*
                    as of 6/27/2016 based on conversation between Justine and Jess,
                    added an additional condition on ia_cost_per_mbps
                    i.e. similar budget, and district B is paying lower or same IA cost per mbps yet getting more bandwidth
                    than district A, then district B is included in pct_districts_more_ia_bw_for_ia_budget
                    */
                    and d.ia_cost_per_mbps >= d_all.ia_cost_per_mbps
                    and d.ia_bandwidth < d_all.ia_bandwidth
                )/(   select count(*)
                    from districts_formatted d_all
                    where d.esh_id != d_all.esh_id
                    and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
                    and d.ia_annual_cost> d_all.ia_annual_cost*.8
                )::numeric
        end as pct_dists_more_ia_bw_for_ia_budget
        
from districts_formatted d