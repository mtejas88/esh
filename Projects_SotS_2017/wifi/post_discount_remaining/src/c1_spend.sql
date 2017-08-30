select dd.esh_id,
dd.discount_rate_c1_matrix,
round(sum(line_item_district_monthly_cost_total * case when months_of_service is null or months_of_service = 0 then 12 else months_of_service end),2) as c1_costs,
round(sum(line_item_district_monthly_cost_total * case when months_of_service is null or months_of_service = 0 then 12 else months_of_service end),2) * dd.discount_rate_c1_matrix as erate_c1_costs
from public.fy2017_services_received_matr sr
left join public.fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_wan_cost_analysis = false
and dd.exclude_from_ia_cost_analysis = false
and sr.inclusion_status ilike '%clean%'

group by
	dd.esh_id,
	dd.discount_rate_c1_matrix