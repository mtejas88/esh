
select (sum("Total Cost")/1000000000)* 1.2 as
"extrap_funding_2014_$_B"
from
public.fy2015_item21_services_and_costs
where "FRN Service Type" ilike 'VOICE SERVICES'

/*using 2015 item 21 to extrapolate 2014 voice total cost*/
