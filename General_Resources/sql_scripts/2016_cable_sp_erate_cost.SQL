select distinct recipient_id,
sr.line_item_id,
line_item_district_monthly_cost_total + line_item_district_one_time_cost as line_item_district_cost,
sr.reporting_name,
sr.connect_category,
dd.discount_rate_c1_matrix
from public.fy2016_services_received_matr sr
left join public.fy2016_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
left join public.service_provider_categories sp
on sp.reporting_name = sr.reporting_name
where category = 'Cable' or sr.reporting_name = 'Mediacom' or sr.reporting_name = 'Spectrum' or sr.reporting_name = 'RCN' or sr.reporting_name = 'Wow Technologies Inc' or sr.reporting_name = 'Suddenlink Communications' 
and dd.include_in_universe_of_districts = TRUE
and sr.inclusion_status = 'clean_with_cost'
