/*

Author: Jamie Barnes
Date: 8/9/2017
Purpose: Calculates 2017 price dispersion for Internet & WAN Lit fiber circuits at common circuit sizes. 

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
 
 select count(sr.line_item_id) as line_items_in_sample,
 sr.purpose,
 sr.connect_category,
 sr.bandwidth_in_mbps,
/*Monthly Cost Per Circuit*/
PERCENTILE_CONT (0.10) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "10th_percentile_mrc_unless_null",
PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "25th_percentile_mrc_unless_null",
median(sr.monthly_circuit_cost_mrc_unless_null) as "median_mrc_unless_null",
PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "75th_percentile_mrc_unless_null",
PERCENTILE_CONT (0.90) WITHIN GROUP (ORDER BY sr.monthly_circuit_cost_mrc_unless_null) AS "90th_percentile_mrc_unless_null",
case
  when purpose = 'WAN'
  then null
  when bandwidth_in_mbps = 50
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
  else null
end as mrc_benchmarks,
/*$ Mbps*/
PERCENTILE_CONT (0.10) WITHIN GROUP (ORDER BY sr.mrc_unless_null_per_mbps) AS "10th_percentile_mrc_unless_null_per_mbps",
PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY sr.mrc_unless_null_per_mbps) AS "25th_percentile_mrc_unless_null_per_mbps",
median(sr.mrc_unless_null_per_mbps) as "median_mrc_unless_null_per_mbps",
PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY sr.mrc_unless_null_per_mbps) AS "75th_percentile_mrc_unless_null_per_mbps",
PERCENTILE_CONT (0.90) WITHIN GROUP (ORDER BY sr.mrc_unless_null_per_mbps) AS "90th_percentile_mrc_unless_null_per_mbps"

 
 from sr 
 
 where (purpose = 'Internet' and bandwidth_in_mbps in (50,100,200,500,1000,10000)) /*limiting to only look at BWs we have historically graphed in sots*/
 or (purpose = 'WAN' and bandwidth_in_mbps in (1000,10000,100))
 
 group by sr.purpose,
 sr.connect_category,
 sr.bandwidth_in_mbps