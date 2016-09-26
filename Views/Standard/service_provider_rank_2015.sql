select  dsp.recipient_id,
        dsp.reporting_name,
        dsp.service_provider_name
from (select  recipient_id,
        reporting_name,
        svcs.service_provider_name,
        row_number() over (partition by recipient_id order by sum(line_item_district_monthly_cost) desc) as rank_order
        
	from public.services_received_2015 svcs
	join line_items
	on svcs.line_item_id = line_items.id
	where shared_service = 'District-dedicated'
	and svcs.dqs_excluded = false
	and erate = true

	group by recipient_id,
	         reporting_name, 
	         svcs.service_provider_name        
	order by recipient_id ) dsp
where dsp.rank_order = 1
