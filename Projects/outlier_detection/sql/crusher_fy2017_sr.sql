select erate, applicant_postal_cd, bandwidth_in_mbps, connect_category,
CASE
              WHEN li.isp_conditions_met
                THEN 'ISP'
              WHEN li.internet_conditions_met
                THEN 'Internet'
              WHEN li.wan_conditions_met
                THEN 'WAN'
              WHEN li.upstream_conditions_met
                THEN 'Upstream'
              WHEN li.backbone_conditions_met
                THEN 'Backbone'
              ELSE 'Not broadband'
            END AS purpose,
rec_elig_cost as line_item_recurring_elig_cost,
case when num_lines = 'Unknown' then null else num_lines::integer end as line_item_total_num_lines,
id as line_item_id
from public.fy2017_esh_line_items_v li
/*select sr.*, district_type 
from public.fy2017_services_received_matr sr
left join public.fy2017_districts_deluxe_matr dd
on sr.recipient_id=dd.esh_id
where district_type='Traditional'*/
