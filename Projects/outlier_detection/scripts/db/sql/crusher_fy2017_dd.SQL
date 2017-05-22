with dd_2017 as 
(select *
from public.fy2017_districts_deluxe_matr),
dd_2016 as (select*from public.fy2016_districts_deluxe_matr)

select dd_2017.*,
(dd_2017.ia_bw_mbps_total - dd_2016.ia_bw_mbps_total) as change_in_bw_tot,
case when (dd_2016.ia_bw_mbps_total=0) and (dd_2017.ia_bw_mbps_total > 0) then 1
when (dd_2016.ia_bw_mbps_total=0) and (dd_2017.ia_bw_mbps_total = 0) then 0
else (dd_2017.ia_bw_mbps_total - dd_2016.ia_bw_mbps_total)/dd_2016.ia_bw_mbps_total end as change_in_bw_pct,
case when (dd_2016.ia_monthly_cost_per_mbps is not null) then
(dd_2017.ia_monthly_cost_per_mbps - dd_2016.ia_monthly_cost_per_mbps) 
else null end as change_in_cost_tot,
case when (dd_2016.ia_monthly_cost_per_mbps=0) and (dd_2017.ia_monthly_cost_per_mbps > 0) then 1
when (dd_2016.ia_monthly_cost_per_mbps=0) and (dd_2017.ia_monthly_cost_per_mbps = 0) then 0
when (dd_2016.ia_monthly_cost_per_mbps is not null) then
(dd_2017.ia_monthly_cost_per_mbps - dd_2016.ia_monthly_cost_per_mbps)/dd_2016.ia_monthly_cost_per_mbps
else null end as change_in_cost_pct
from dd_2017 left join dd_2016 on dd_2017.esh_id::integer=dd_2016.esh_id::integer