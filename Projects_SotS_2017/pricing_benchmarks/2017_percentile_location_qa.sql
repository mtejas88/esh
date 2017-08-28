/*

Author: Jamie Barnes
Date: 8/28/2017
Purpose: To QA the benchmark percentile location to each circuit size in 2016 PINK Frozen

*/

with a as (select s.*,
 case 
 when s.monthly_circuit_cost_recurring = 0
 then s.monthly_circuit_cost_total
 else s.monthly_circuit_cost_recurring
 end as monthly_circuit_cost_mrc_unless_null
 from public.fy2017_services_received_matr s
 join public.fy2017_districts_deluxe_matr sd
 on sd.esh_id = s.recipient_id
 where sd.district_type = 'Traditional' 
 and sd.include_in_universe_of_districts = true 
 and sd.exclude_from_ia_analysis = false 
 and s.erate = true
 and s.consortium_shared = false
 and s.purpose in ('Internet','WAN')
 and s.inclusion_status = 'clean_with_cost'
 and (not 'special_construction_tag' = any(s.open_tags) or s.open_tags is null)
 and monthly_circuit_cost_total != 0
 and postal_cd != 'AK'
 and connect_category = 'Lit Fiber'),
 sr as (select line_item_id,
 purpose,
 connect_category,
 bandwidth_in_mbps,
 monthly_circuit_cost_mrc_unless_null,
 (monthly_circuit_cost_mrc_unless_null/bandwidth_in_mbps) as mrc_unless_null_per_mbps
 from a
 group by line_item_id,
 purpose,
 connect_category,
 bandwidth_in_mbps,
 recipient_postal_cd,
 monthly_circuit_cost_mrc_unless_null)
 
 select 
 sr.bandwidth_in_mbps,
 case when bandwidth_in_mbps = 50
  then 700
  when bandwidth_in_mbps = 100
  then 1200
  when bandwidth_in_mbps = 200
  then 1800
  when bandwidth_in_mbps = 500
  then 2750
  when bandwidth_in_mbps = 1000
  then 3000
  when bandwidth_in_mbps = 10000
  then 7500
end as benchmarks,
/*Monthly Cost Per Circuit*/
PERCENTILE_CONT (0.43) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "43rd_percentile_mrc_unless_null",
PERCENTILE_CONT (0.45) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "45th_percentile_mrc_unless_null",
PERCENTILE_CONT (0.47) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "47th_percentile_mrc_unless_null",
PERCENTILE_CONT (0.50) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "50th_percentile_mrc_unless_null",
median(monthly_circuit_cost_mrc_unless_null) as median_mrc_unless_null,
PERCENTILE_CONT (0.51) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "51st_percentile_mrc_unless_null"


 from sr 
 
 where purpose = 'Internet' and bandwidth_in_mbps in (50,100,200,500,1000,10000)
 
 group by 
 sr.bandwidth_in_mbps