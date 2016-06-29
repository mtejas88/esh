select fpia.*,
     dsc.district_count,
     row_number() over (partition by recipient_id order by district_count desc) as rank_order
from public.district_fiber_ia_prices_2015 fpia
join public.district_service_count_2015 dsc
on concat(fpia.bandwidth_in_mbps,fpia.internet_conditions_met,fpia.recipient_postal_cd) = 
 concat(dsc.bandwidth_in_mbps,dsc.internet_conditions_met,dsc.recipient_postal_cd)
where best_cost_per_mbps is not null and best_cost_per_mbps != 0