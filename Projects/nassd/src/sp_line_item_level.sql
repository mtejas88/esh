select 
2016 as year,
line_item_id,
reporting_name,
line_item_total_num_lines::numeric,
case
  when reporting_name in ('Connecticut Education Network', 'County of Clackamas', 'Douglas Sevices Inc', 'Eastern Suffolk', 'EDLINK12', 'ESA Region 20', 
        'ESC Region 1', 'ESC Region 11', 'ESC Region 17', 'ESC Region 2', 'ESC Region 6', 'ESC7Net', 'Illinois Century', 'King County', 'Lake Geauga', 'Lower Hudson', 
        'Metropolitan Dayton', 'Miami Valley', 'Midland Council', 'NC OH Comp Coop', 'NE OH Management', 'NE OH Network', 'NE Serv Coop', 'Norther OH Area CS', 'Northern Buckeye', 
        'Northern OH Ed Comp', 'OH Mid Eastern ESA', 'Region 16 ESC', 'Region 18 ESC', 'Region 19 ESC', 'Region 3 ESC', 'Region 4 ESC', 'Region 9 ESC', 'SC OH Comp', 'SE MN Network', 
        'South Dakota Network', 'Stark Portage', 'SW OH Comp Asso', 'W OH Computer Org', 'W Suffolk Boces', 'Wasioja Cooperative','NC Office','Dept of Admin Services, CT','State of Iowa')
  then 'Consortia'
  when reporting_name = 'District Owned'
  then 'District Owned'
  else 'Regular'
end as service_provider_assignment_type,
recipient_postal_cd,
monthly_circuit_cost_recurring,
monthly_circuit_cost_total,
contract_end_date,
connect_category,
bandwidth_in_mbps,
case
  when monthly_circuit_cost_total = 0
  then null
  when monthly_circuit_cost_recurring = 0 
  then monthly_circuit_cost_total/bandwidth_in_mbps
  else monthly_circuit_cost_recurring/bandwidth_in_mbps
end as monthly_circuit_cost_per_mbps

from public.fy2016_services_received_matr sr
inner join public.fy2016_districts_deluxe_matr dd
on dd.esh_id = sr.recipient_id

where sr.inclusion_status like 'clean%'
and dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true
and (purpose = 'Internet' or purpose = 'Upstream')
and reporting_name != ''
and bandwidth_in_mbps > 0

group by line_item_id,
reporting_name,
line_item_total_num_lines,
recipient_postal_cd,
monthly_circuit_cost_recurring,
monthly_circuit_cost_total,
contract_end_date,
bandwidth_in_mbps,
months_of_service,
connect_category

union

select 
2017 as year,
line_item_id,
reporting_name,
line_item_total_num_lines::numeric,
case
  when reporting_name in ('Connecticut Education Network', 'County of Clackamas', 'Douglas Sevices Inc', 'Eastern Suffolk', 'EDLINK12', 'ESA Region 20', 
        'ESC Region 1', 'ESC Region 11', 'ESC Region 17', 'ESC Region 2', 'ESC Region 6', 'ESC7Net', 'Illinois Century', 'King County', 'Lake Geauga', 'Lower Hudson', 
        'Metropolitan Dayton', 'Miami Valley', 'Midland Council', 'NC OH Comp Coop', 'NE OH Management', 'NE OH Network', 'NE Serv Coop', 'Norther OH Area CS', 'Northern Buckeye', 
        'Northern OH Ed Comp', 'OH Mid Eastern ESA', 'Region 16 ESC', 'Region 18 ESC', 'Region 19 ESC', 'Region 3 ESC', 'Region 4 ESC', 'Region 9 ESC', 'SC OH Comp', 'SE MN Network', 
        'South Dakota Network', 'Stark Portage', 'SW OH Comp Asso', 'W OH Computer Org', 'W Suffolk Boces', 'Wasioja Cooperative','NC Office','Dept of Admin Services, CT','State of Iowa')
  then 'Consortia'
  when reporting_name = 'District Owned'
  then 'District Owned'
  else 'Regular'
end as service_provider_assignment_type,
recipient_postal_cd,
monthly_circuit_cost_recurring,
monthly_circuit_cost_total,
contract_end_date,
connect_category,
bandwidth_in_mbps,
case
  when monthly_circuit_cost_total = 0
  then null
  when monthly_circuit_cost_recurring = 0 
  then monthly_circuit_cost_total/bandwidth_in_mbps
  else monthly_circuit_cost_recurring/bandwidth_in_mbps
end as monthly_circuit_cost_per_mbps

from public.fy2017_services_received_matr sr
inner join public.fy2017_districts_deluxe_matr dd
on dd.esh_id = sr.recipient_id

where sr.inclusion_status like 'clean%'
and dd.district_type = 'Traditional'
and dd.include_in_universe_of_districts = true
and (purpose = 'Internet' or purpose = 'Upstream')
and line_item_id != 873578 /* removing line item that goes to OK and TX districts */
and reporting_name != ''

group by line_item_id,
reporting_name,
recipient_postal_cd,
monthly_circuit_cost_recurring,
monthly_circuit_cost_total,
contract_end_date,
connect_category,
bandwidth_in_mbps,
months_of_service,
line_item_total_num_lines
