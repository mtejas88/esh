select *
from public.fy2017_districts_deluxe_matr dd
left join public.fy2017_services_received_matr sr
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