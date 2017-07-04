WITH dd_2015 AS 
(SELECT esh_id, total_ia_bw_mbps,
CASE WHEN (monthly_ia_cost_per_mbps = 'Insufficient data' OR monthly_ia_cost_per_mbps = 'Infinity') THEN NULL ELSE monthly_ia_cost_per_mbps END AS monthly_ia_cost_per_mbps, exclude_from_analysis
FROM public.fy2015_districts_deluxe_m),
dd_2016 AS (SELECT * FROM public.fy2016_districts_deluxe_matr)

SELECT dd_2016.*,
CASE WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
THEN (dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps) END AS change_in_bw_tot,

CASE WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
AND (dd_2015.total_ia_bw_mbps=0) AND (dd_2016.ia_bw_mbps_total > 0) THEN 1
WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
AND (dd_2015.total_ia_bw_mbps=0) AND (dd_2016.ia_bw_mbps_total = 0) THEN 0
WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE
THEN (dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps)/dd_2015.total_ia_bw_mbps END AS change_in_bw_pct,

CASE WHEN dd_2015.exclude_from_analysis = FALSE AND
dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
AND (dd_2015.monthly_ia_cost_per_mbps IS NOT null) THEN
(dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float) 
END AS change_in_cost_tot,

CASE WHEN dd_2015.exclude_from_analysis = FALSE AND
dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
AND (dd_2015.monthly_ia_cost_per_mbps::float=0) AND (dd_2016.ia_monthly_cost_per_mbps > 0) THEN 1
WHEN dd_2015.exclude_from_analysis = FALSE AND
dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
AND (dd_2015.monthly_ia_cost_per_mbps::float=0) AND (dd_2016.ia_monthly_cost_per_mbps = 0) THEN 0
WHEN dd_2015.exclude_from_analysis = FALSE AND
dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
AND (dd_2015.monthly_ia_cost_per_mbps IS NOT null) THEN
(dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float)/dd_2015.monthly_ia_cost_per_mbps::FLOAT 
END AS change_in_cost_pct

FROM dd_2016 LEFT JOIN dd_2015 ON dd_2016.esh_id::integer=dd_2015.esh_id::integer