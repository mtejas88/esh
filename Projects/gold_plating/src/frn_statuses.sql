select distinct recipient_id, li.frn, frn_status, num_bids_received
from public.fy2016_services_received_matr sr
left join fy2016.line_items li
on sr.line_item_id = li.id
left join fy2016.frns
on li.frn = frns.frn
left join public.funding_requests_2016_and_later fr
on li.frn = fr.frn