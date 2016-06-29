select bandwidth_in_mbps,
         internet_conditions_met,
         upstream_conditions_met,
         recipient_postal_cd,
         count(*) as district_count
from public.district_fiber_ia_prices_2015
where best_cost_per_mbps is not null and best_cost_per_mbps != 0
group by bandwidth_in_mbps,
         internet_conditions_met,
         upstream_conditions_met,
         recipient_postal_cd    