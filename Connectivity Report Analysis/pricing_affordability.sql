select 
postal_cd,
-- overall median and counts for ia and wan
median (case when internet_conditions_met = true then cost_per_mbps end) as median_ia_cost_per_mbps,
count (case when internet_conditions_met = true then cost_per_mbps end) as count_ia_cost_per_mbps,
median (case when wan_conditions_met = true then cost_per_circuit end) as median_wan_cost_per_circuit,
count (case when wan_conditions_met = true then cost_per_circuit end) as count_wan_cost_per_circuit,
-- median and counts for Fiber ia at 100 Mbps, 1 Gbps, and 10 Gbps
median (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as median_ia_100_fiber_cost_per_circuit,
avg (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as avg_ia_100_fiber_cost_per_circuit,
count (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as count_ia_100_fiber_cost_per_circuit,
median (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as median_ia_1gb_fiber_cost_per_circuit,
avg (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as avg_ia_1000_fiber_cost_per_circuit,
count (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as count_ia_1gb_fiber_cost_per_circuit,
median (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as median_ia_10gb_fiber_cost_per_circuit,
avg (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as avg_ia_10000_fiber_cost_per_circuit,
count (case when (internet_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as count_ia_10gb_fiber_cost_per_circuit,
median (case when (internet_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as median_ia_fiber_cost_per_circuit,
min (case when (internet_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as min_ia_fiber_cost_per_circuit,
max (case when (internet_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as max_ia_fiber_cost_per_circuit,
count (case when (internet_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as count_ia_fiber_cost_per_circuit,
-- median and counts for Fiber WAN at 100 Mbps, 1 Gbps, and 10 Gbps
median (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as median_wan_100_fiber_cost_per_circuit,
avg (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as avg_wan_100_fiber_cost_per_circuit,
count (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 100) then cost_per_circuit end) as count_wan_100_fiber_cost_per_circuit,
median (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as median_wan_1gb_fiber_cost_per_circuit,
avg (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as avg_wan_1000_fiber_cost_per_circuit,
count (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 1000) then cost_per_circuit end) as count_wan_1gb_fiber_cost_per_circuit,
median (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as median_wan_10gb_fiber_cost_per_circuit,
avg (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as avg_wan_10000_fiber_cost_per_circuit,
count (case when (wan_conditions_met = true and connect_category in ('Fiber') and bandwidth_in_mbps = 10000) then cost_per_circuit end) as count_wan_10gb_fiber_cost_per_circuit,
median (case when (wan_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as median_wan_fiber_cost_per_circuit,
min (case when (wan_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as min_wan_fiber_cost_per_circuit,
max (case when (wan_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as max_wan_fiber_cost_per_circuit,
count (case when (wan_conditions_met = true and connect_category in ('Fiber')) then cost_per_circuit end) as count_wan_fiber_cost_per_circuit

from (

	select 
		*,
		total_cost / (num_lines * bandwidth_in_mbps) / 12 as cost_per_mbps,
		total_cost / num_lines / 12 as cost_per_circuit

	from public.fy2015_line_items

  where postal_cd = '{{two_letter_state}}'
   
  	and broadband = true
  	--and exclude = false
  	and (not('consortium_shared' = any(open_flags)) or not('consortium_shared_manual' = any(open_flags)) or open_flags is null)
    and num_lines > 0
  	and bandwidth_in_mbps > 0
  	and report_private = true
  	and report_app_type = true
{% if all_data_or_clean_only == 'clean only data' %}
  and exclude = false
{% endif %}

	) sub

group by postal_cd
order by postal_cd

{% form %}

two_letter_state:
  type: text
  default: 'VT'
  
all_data_or_clean_only:
  type: select
  options: [['all data'],
            ['clean only data']]
  default: 'clean only data'  
  
  
{% endform %}