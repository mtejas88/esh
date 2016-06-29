select  svcs.recipient_id,
        svcs.recipient_postal_cd,
        bandwidth_in_mbps,
        internet_conditions_met,
        upstream_conditions_met,
        service_provider_name,
        min(line_item_total_monthly_cost / (line_item_total_num_lines * bandwidth_in_mbps)) 
        as best_cost_per_mbps       
from public.services_received_2015 svcs
where shared_service = 'District-dedicated'
and dirty_status = 'include clean'
and exclude = false
and (internet_conditions_met = true or upstream_conditions_met = true)
and not (internet_conditions_met = true and upstream_conditions_met = true)
and connect_category = 'Fiber'  
and connect_type != 'Dark Fiber Service'
group by  svcs.recipient_id,
        svcs.recipient_postal_cd,
        bandwidth_in_mbps,
        internet_conditions_met,
        upstream_conditions_met,
        service_provider_name      
order by svcs.recipient_id 