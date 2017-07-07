select sr.*
from public.fy2016_services_received_matr sr

left join fy2016.line_items li
on sr.line_item_id = li.id

left join fy2016.frns frn
on li.frn = frn.frn

where sr.recipient_include_in_universe_of_districts = TRUE
and sr.inclusion_status != 'dqs_excluded'
and sr.broadband = TRUE