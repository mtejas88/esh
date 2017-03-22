select distinct li.application_number,
li.frn_complete,
a.recipient_ben,
a.recipient_id,
a.original_num_lines_to_allocate,
a.num_lines_to_allocate

from fy2016.line_items li

left join public.fy2016_services_received_matr sr
on sr.line_item_id = li.id

left join fy2016.allocations a
on li.id = a.line_item_id

where sr.recipient_id in (
    select esh_id
    from public.fy2016_districts_deluxe_matr
    where district_type = 'Traditional'
    and include_in_universe_of_districts
)
and sr.inclusion_status != 'dqs_excluded'
and sr.recipient_exclude_from_ia_analysis = false  

