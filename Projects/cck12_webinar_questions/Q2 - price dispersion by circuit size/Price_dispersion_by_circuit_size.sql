## Only selected fields from services recieved so that there are no duplicates.

SELECT DISTINCT line_item_id, applicant_name, recipient_postal_cd, reporting_name, monthly_circuit_cost_recurring, bandwidth_in_mbps
from public.fy2017_districts_deluxe_matr dd
join public.fy2017_services_received_matr sr
    ON dd.esh_id = sr.recipient_id
where sr.bandwidth_in_mbps in (100, 200, 300, 400, 500, 600, 700, 800, 900, 1000)
AND sr.bandwidth_in_mbps is not null
AND sr.bandwidth_in_mbps >= 100
AND dd.exclude_from_ia_analysis = false
AND dd.exclude_from_ia_cost_analysis = false
AND dd.include_in_universe_of_districts = true
AND dd.district_type = 'Traditional'
AND sr.purpose = 'Internet'
AND sr.connect_category = 'Lit Fiber'
AND sr.monthly_circuit_cost_recurring > 0
AND sr.inclusion_status = 'clean_with_cost'
AND postal_cd != 'AK'