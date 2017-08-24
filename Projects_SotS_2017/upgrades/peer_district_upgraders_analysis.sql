-- temp tables to enable finding comparisons for each district:
-- limit to the locale and district_size options: plus or minus 1 locale and district size
WITH lookup AS (
SELECT locale,
district_size,
postal_cd,

CASE
 WHEN locale = 'Rural' THEN 0
 WHEN locale = 'Town' THEN 1
 WHEN locale = 'Suburban' THEN 2
 WHEN locale = 'Urban' THEN 3
END AS locale_score,
CASE
 WHEN district_size = 'Tiny' THEN 0
 WHEN district_size = 'Small' THEN 1
 WHEN district_size = 'Medium' THEN 2
 WHEN district_size = 'Large' THEN 3
 --WHEN district_size = 'Mega' THEN 4
END AS district_size_score,
array_agg(esh_id) AS districts
FROM public.fy2017_districts_deluxe_matr dd
WHERE include_in_universe_of_districts = TRUE
GROUP BY 1,2,3,4,5),

-- aggregate the locale, district_size options
agg_lookup AS (SELECT l2.district_size AS l2district,
l2.locale AS l2locale,
l.postal_cd,
l.locale,
l.district_size,
l2.districts
FROM lookup l
JOIN lookup l2
ON (l.locale_score = l2.locale_score - 1
OR l.locale_score = l2.locale_score + 1
OR l.locale_score = l2.locale_score)
AND
(l.district_size_score = l2.district_size_score - 1
OR l.district_size_score = l2.district_size_score + 1
OR l.district_size_score = l2.district_size_score)
AND (l.postal_cd = l2.postal_cd)
ORDER BY 3,4,5),

-- unwrap locale, district_size options to allow to reaggregate
unagg_lookup AS (SELECT postal_cd,
locale,
district_size,
unnest(districts) AS districts
FROM agg_lookup),

-- reaggregate
all_comps AS (SELECT postal_cd,
locale,
district_size,
array_agg(districts) AS comparable_districts
FROM unagg_lookup
GROUP BY postal_cd, locale, district_size),

-- merge all districts by postal_cd, locale, district_size
all_comps_merged AS (SELECT dd.esh_id,
ac.comparable_districts
FROM public.fy2017_districts_deluxe_matr AS dd
LEFT JOIN all_comps AS ac
ON ac.postal_cd = dd.postal_cd
AND ac.locale = dd.locale
AND ac.district_size = dd.district_size
WHERE dd.include_in_universe_of_districts = true),

-- unaggregate so can merge in district details for district pairs
all_comps_unagg AS (SELECT esh_id,
unnest(comparable_districts) AS comparable_districts
FROM all_comps_merged),

-- merge in district info so can filter comparable districts
-- subset to districts in universe for both primary and matches
-- and clean districts for matches (and matches don't have cost/mbps = 0)
bandwidth_comparable AS (
  SELECT
ac.esh_id AS primary_districts,
dd.ia_bw_mbps_total AS primary_bandwidth,
dd.ia_monthly_cost_total AS primary_cost,
ac.comparable_districts AS sec_districts,
dd2.ia_bw_mbps_total AS sec_bandwidth,
dd2.ia_monthly_cost_total AS sec_cost
FROM all_comps_unagg ac
LEFT JOIN public.fy2017_districts_deluxe_matr AS dd
ON ac.esh_id = dd.esh_id
LEFT JOIN public.fy2017_districts_deluxe_matr AS dd2
ON ac.comparable_districts = dd2.esh_id
WHERE ac.esh_id != ac.comparable_districts
AND dd.include_in_universe_of_districts = TRUE
AND dd.exclude_from_ia_analysis = FALSE
AND dd2.include_in_universe_of_districts = TRUE
AND dd2.exclude_from_ia_analysis = FALSE
AND dd.district_type = 'Traditional'
AND dd2.district_type = 'Traditional'

)

SELECT count(distinct primary_districts) from
bandwidth_comparable a
left join fy2017_districts_deluxe_matr b
on a.primary_districts = b.esh_id
left join fy2016_districts_deluxe_matr c
on b.esh_id = c.esh_id
where
b.district_type = 'Traditional'
and c.district_type = 'Traditional'
and b.exclude_from_ia_analysis = false
and c.exclude_from_ia_analysis = false
and b.include_in_universe_of_districts
and c.include_in_universe_of_districts
and b.ia_monthly_cost_total > c.ia_monthly_cost_total
and b.upgrade_indicator
