/* Request: Looking for stats on number of districts who have upgraded over the past year, 
and those who upgraded at little-to-no cost.
Request Modified: Looking for stats on number of districts who have upgraded over the past year, 
and those who upgraded paying the same or less than previous year. */


/* Upgraders are defined as those districts that increased its bandwidth more than 11% since the previous year. */

SELECT distinct count (*)
FROM public.fy2017_districts_deluxe_matr fy2017
WHERE fy2017.include_in_universe_of_districts = 'True'
    AND fy2017.district_type = 'Traditional'
    AND fy2017.upgrade_indicator = 'True'
    AND fy2017.exclude_from_ia_analysis = 'False'
    AND fy2017.exclude_from_ia_cost_analysis = 'False'

/* Upgraders are defined as those districts that increased its bandwidth more than 11% since the previous year.
Only looking at districts that paid the same or less than previous year (for little-to-no cost increase) */

SELECT count(fy2017.esh_id)
FROM public.fy2017_districts_deluxe_matr fy2017
LEFT JOIN public.fy2016_districts_deluxe_matr fy2016
  ON fy2017.esh_id = fy2016.esh_id
  WHERE fy2017.include_in_universe_of_districts = 'True'
    AND fy2017.district_type = 'Traditional'
    AND fy2017.upgrade_indicator = 'True'
    AND fy2017.exclude_from_ia_analysis = 'False'
    AND fy2017.exclude_from_ia_cost_analysis = 'False'
    AND fy2017.ia_bw_mbps_total > fy2016.ia_bw_mbps_total
    AND fy2017. ia_monthly_cost_total <= fy2016.ia_monthly_cost_total

