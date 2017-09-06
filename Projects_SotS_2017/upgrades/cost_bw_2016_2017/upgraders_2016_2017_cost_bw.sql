/*run 2017 #s on 2017 frozen database*/

select
round(avg(ia_bw_mbps_total)) as "monthly_bandwidth_mbps_2017",
round(avg(ia_monthly_cost_total)) as "monthly_recurring_cost_IA_2017"
from
public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False'


/*run 2016 #s on 2016 frozen database*/

select
round(avg(ia_bw_mbps_total)) as "monthly_bandwidth_mbps_2016",
round(avg(ia_monthly_cost_total)) as "monthly_recurring_cost_IA_2016"
from
public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False'
