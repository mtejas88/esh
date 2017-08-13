select
(select (sum(round(ia_bw_mbps_total)))
from
public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False') as "total_bw_mbps_2017",

(select
sum((round(ia_monthly_cost_total)))
from
public.fy2017_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False') as "total_monthly_cost_mbps_2017",

(select (sum(round(ia_bw_mbps_total)))
from
public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False') as "total_bw_mbps_2016",

(select
sum((round(ia_monthly_cost_total)))
from
public.fy2016_districts_deluxe_matr
where
include_in_universe_of_districts = 'True'
and district_type = 'Traditional'
and upgrade_indicator = 'True'
and exclude_from_ia_analysis = 'False'
and exclude_from_ia_cost_analysis = 'False') as "total_monthly_cost_mbps_2016"
