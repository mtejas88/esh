/*

Author: Jamie Barnes
Date: 8/9/2017
Purpose: Calculates 2017 median prices for Internet & WAN Lit fiber circuits at common circuit sizes. 
Also includes hardcoded benchmarks for purposes of created viz in Tableau.

*/

with a as (select s.*,
    case 
          when s.monthly_circuit_cost_recurring = 0
          then s.monthly_circuit_cost_total
          else s.monthly_circuit_cost_recurring
    end as monthly_circuit_cost_mrc_unless_null
    from public.fy2017_services_received_matr  s
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
sr.purpose,
2017 as year,
sr.bandwidth_in_mbps,
/*Monthly Cost Per Circuit*/
median(sr.monthly_circuit_cost_mrc_unless_null) as "median_mrc_unless_null",
case
  when purpose = 'WAN'
  then null
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
end as benchmarks

from sr 

where (purpose = 'Internet' and bandwidth_in_mbps in (100,200,500,1000,10000))
or (purpose = 'WAN' and bandwidth_in_mbps in (100,1000,10000))

group by sr.purpose,
sr.connect_category,
sr.bandwidth_in_mbps

