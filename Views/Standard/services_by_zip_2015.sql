select  "LZIP",
        count(distinct reporting_name) as service_providers_in_zip,
        count(distinct concat(svcs.connect_category,
                              svcs.internet_conditions_met,
                              svcs.upstream_conditions_met,
                              svcs.wan_conditions_met,
                              svcs.isp_conditions_met,
                              svcs.bandwidth_in_mbps)) as services_in_zip
        
from public.services_received_2015 svcs
join ( select distinct entity_id, nces_code
            from public.entity_nces_codes 
            where entity_type = 'District' ) eim
on svcs.recipient_id = eim.entity_id 
join ag131a  
on left(eim.nces_code,7) = ag131a."LEAID"
join line_items
on svcs.line_item_id = line_items.id
where shared_service = 'District-dedicated'
and svcs.dqs_excluded = false
and erate = true
and svcs.exclude = false

group by "LZIP"