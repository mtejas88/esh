select distinct li.application_number,
li.frn_complete,
li.connect_type,
li.connect_category,
sr.purpose,
sr.bandwidth_in_mbps,
li.num_lines,
sr.line_item_recurring_elig_cost

from fy2016.line_items li

left join public.fy2016_services_received_matr sr
on sr.line_item_id = li.id


where sr.recipient_id in (
    select esh_id
    from public.fy2016_districts_deluxe_matr
    where district_type = 'Traditional'
    and include_in_universe_of_districts
)
and sr.inclusion_status != 'dqs_excluded'
and sr.recipient_exclude_from_ia_analysis = false  
