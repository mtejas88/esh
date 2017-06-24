with dd_2015 as 
(select esh_id, total_ia_bw_mbps,
case when (monthly_ia_cost_per_mbps = 'Insufficient data' or monthly_ia_cost_per_mbps = 'Infinity') then null else monthly_ia_cost_per_mbps end as monthly_ia_cost_per_mbps
from public.fy2015_districts_deluxe_m),
dd_2016 as (select*from public.fy2016_districts_deluxe_matr)

select dd_2016.*,
(dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps) as change_in_bw_tot,
case when (dd_2015.total_ia_bw_mbps=0) and (dd_2016.ia_bw_mbps_total > 0) then 1
when (dd_2015.total_ia_bw_mbps=0) and (dd_2016.ia_bw_mbps_total = 0) then 0
else (dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps)/dd_2015.total_ia_bw_mbps end as change_in_bw_pct,
case when (dd_2015.monthly_ia_cost_per_mbps is not null) then
(dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float) 
else null end as change_in_cost_tot,
case when (dd_2015.monthly_ia_cost_per_mbps::float=0) and (dd_2016.ia_monthly_cost_per_mbps > 0) then 1
when (dd_2015.monthly_ia_cost_per_mbps::float=0) and (dd_2016.ia_monthly_cost_per_mbps = 0) then 0
when (dd_2015.monthly_ia_cost_per_mbps is not null) then
(dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float)/dd_2015.monthly_ia_cost_per_mbps::float 
else null end as change_in_cost_pct
from dd_2016 left join dd_2015 on dd_2016.esh_id::integer=dd_2015.esh_id::integer