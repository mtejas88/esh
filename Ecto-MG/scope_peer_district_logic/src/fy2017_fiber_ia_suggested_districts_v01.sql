-- Define Fiber IA Comparable Districts
-----------------------------------------------------------------------

-- Define Scalable Line Items for each District
-- Temp tables for Scalable IA and WAN line items:
-- scalable_ia
with scalable_ia_temp as (select recipient_id,
line_item_id as line_item_id_scalable_ia,
bandwidth_in_mbps as bandwidth_in_mbps_scalable_ia,
case
  when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total
  else monthly_circuit_cost_recurring
end as monthly_circuit_cost_recurring_scalable_ia,
case
  when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total / bandwidth_in_mbps
  else monthly_circuit_cost_recurring / bandwidth_in_mbps
end as ia_cost_per_mbps_scalable,
connect_category as connect_category_scalable_ia,
connect_category || ' (Fiber)' as connect_category_scalable_ia_formatted,
service_provider_name as service_provider_name_scalable_ia,
reporting_name as reporting_name_scalable_ia
from endpoint.fy2017_services_received
where recipient_include_in_universe_of_districts = TRUE
and recipient_exclude_from_ia_analysis = FALSE
and inclusion_status like 'clean%'
-- take out Dark Fiber
--and connect_category in ('Lit Fiber', 'Dark Fiber')
and connect_category = 'Lit Fiber'
and purpose in ('Internet', 'Upstream')),
-- with ranking
scalable_ia_temp_with_ranking as (select *,
row_number() over (partition by recipient_id order by ia_cost_per_mbps_scalable asc) as scalable_ia_rank
from scalable_ia_temp
where ia_cost_per_mbps_scalable != 0),
-- final temp table for scalable_ia
scalable_ia as (select *
from scalable_ia_temp_with_ranking
where scalable_ia_rank = 1),

-- scalable_wan
scalable_wan_temp as (select recipient_id,
line_item_id as line_item_id_scalable_wan,
bandwidth_in_mbps as bandwidth_in_mbps_scalable_wan,
case
  when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total
  else monthly_circuit_cost_recurring
end as monthly_circuit_cost_recurring_scalable_wan,
connect_category as connect_category_scalable_wan,
connect_category || ' (Fiber)' as connect_category_scalable_wan_formatted,
service_provider_name as service_provider_name_scalable_wan,
reporting_name as reporting_name_scalable_wan
from endpoint.fy2017_services_received
where recipient_include_in_universe_of_districts = TRUE
and recipient_exclude_from_ia_analysis = FALSE
and inclusion_status like 'clean%'
-- take out Dark Fiber
--and connect_category in ('Lit Fiber', 'Dark Fiber')
and connect_category = 'Lit Fiber'
and purpose = 'WAN'),
-- with ranking
scalable_wan_temp_with_ranking as (select *,
row_number() over (partition by recipient_id) as scalable_wan_rank
from scalable_wan_temp),
-- final temp table for scalable_wan
scalable_wan as (select *
from scalable_wan_temp_with_ranking
where scalable_wan_rank = 1),

-- merge both, store as endpoint together
fy2017_scalable_line_items as (select dd.esh_id,
line_item_id_scalable_ia,
bandwidth_in_mbps_scalable_ia,
monthly_circuit_cost_recurring_scalable_ia,
ia_cost_per_mbps_scalable,
connect_category_scalable_ia,
connect_category_scalable_ia_formatted,
service_provider_name_scalable_ia,
reporting_name_scalable_ia,
line_item_id_scalable_wan,
bandwidth_in_mbps_scalable_wan,
monthly_circuit_cost_recurring_scalable_wan,
connect_category_scalable_wan,
connect_category_scalable_wan_formatted,
service_provider_name_scalable_wan,
reporting_name_scalable_wan
from endpoint.fy2017_districts_deluxe dd
left join scalable_ia ia
on dd.esh_id = ia.recipient_id
left join scalable_wan wan
on dd.esh_id = wan.recipient_id
where ia.line_item_id_scalable_ia is not null
or wan.line_item_id_scalable_wan is not null),


-------------------------------------------------------------------------------------------------------


-- temp tables to enable finding comparisons for each district:
-- limit to the locale and district_size options: plus or minus 1 locale and district size
lookup as (
select locale,
district_size,
postal_cd,
case
  when locale = 'Rural' then 0
  when locale = 'Town' then 1
  when locale = 'Suburban' then 2
  when locale = 'Urban' then 3
end as locale_score,
case
  when district_size = 'Tiny' then 0
  when district_size = 'Small' then 1
  when district_size = 'Medium' then 2
  when district_size = 'Large' then 3
  when district_size = 'Mega' then 4
end as district_size_score,
array_agg(esh_id) as districts
from endpoint.fy2017_districts_deluxe dd
where include_in_universe_of_districts = true
group by 1,2,3,4,5),

-- aggregate the locale, district_size options
agg_lookup as (select l2.district_size as l2district,
l2.locale as l2locale,
l.postal_cd,
l.locale,
l.district_size,
l2.districts
from lookup l
join lookup l2
on (l.locale_score = l2.locale_score - 1
or l.locale_score = l2.locale_score + 1
or l.locale_score = l2.locale_score)
and
(l.district_size_score = l2.district_size_score - 1
or l.district_size_score = l2.district_size_score + 1
or l.district_size_score = l2.district_size_score)
and (l.postal_cd = l2.postal_cd)
order by 3,4,5),

-- unwrap locale, district_size options to allow to reaggregate
unagg_lookup as (select postal_cd,
locale,
district_size,
unnest(districts) as districts
from agg_lookup),

-- reaggregate
all_comps as (select postal_cd,
locale,
district_size,
array_agg(districts) as comparable_districts
from unagg_lookup
group by postal_cd, locale, district_size),

-- merge all districts by postal_cd, locale, district_size
all_comps_merged as (select dd.esh_id,
ac.comparable_districts
from endpoint.fy2017_districts_deluxe as dd
left join all_comps as ac
on ac.postal_cd = dd.postal_cd
and ac.locale = dd.locale
and ac.district_size = dd.district_size
where dd.include_in_universe_of_districts = true),

-- unaggregate so can merge in district details for district pairs
all_comps_unagg as (select esh_id,
unnest(comparable_districts) as comparable_districts
from all_comps_merged),

-- filter to comparable districts for Fiber IA
-- merge in scalable and unscalable info so can filter comparable districts
-- calculate distance
fiber_ia_comparable as (select ac.esh_id,
un.ia_cost_per_mbps_unscalable as primary_ia_cost_per_mbps_unscalable,
un.reporting_name_unscalable_ia as primary_reporting_name_unscalable,
ac.comparable_districts,
sc.ia_cost_per_mbps_scalable as match_ia_cost_per_mbps_scalable,
sc.reporting_name_scalable_ia as match_reporting_name_scalable,
case
  when un.reporting_name_unscalable_ia = sc.reporting_name_scalable_ia then 1
  else 0
end as same_reporting_name_ia,
ST_Distance(geography(dd.geom),geography(dd2.geom)) as distance,
row_number() over (partition by ac.esh_id order by ST_Distance(geography(dd.geom),geography(dd2.geom)) asc) as district_distance_rank
from all_comps_unagg ac
left join endpoint.fy2017_unscalable_line_items as un
on un.esh_id = ac.esh_id
left join fy2017_scalable_line_items as sc
on sc.esh_id = ac.comparable_districts
left join endpoint.fy2017_districts_deluxe as dd
on ac.esh_id = dd.esh_id
left join endpoint.fy2017_districts_deluxe as dd2
on sc.esh_id = dd2.esh_id
where ac.esh_id != ac.comparable_districts
and un.ia_cost_per_mbps_unscalable is not null
and sc.ia_cost_per_mbps_scalable is not null
and sc.ia_cost_per_mbps_scalable != 0
order by 1, 8),

-- limit districts by distance: select top 10
-- also order by esh_id, match_ia_cost_per_mbps_scalable, same_reporting_name, and district_distance_rank
limit_fiber_ia as (select *
from fiber_ia_comparable
where district_distance_rank <= 10
order by 1, 5 asc, 7 desc, 9 asc),

-- order top 10 districts by methodology: lowest cost_per_mbps_ia, prioritize same SP, prioritize closest district if tie
order_fiber_ia as (select *,
row_number() over (partition by esh_id order by match_ia_cost_per_mbps_scalable asc, same_reporting_name_ia desc, district_distance_rank asc) as district_rank
from limit_fiber_ia),

-- reaggregate
final_fiber_ia as (select esh_id,
array_agg(comparable_districts order by match_ia_cost_per_mbps_scalable, same_reporting_name_ia desc, district_distance_rank asc) as fiber_ia_suggested_districts
from order_fiber_ia
where district_rank <= 3
group by esh_id)

select esh_id,
unnest(fiber_ia_suggested_districts) as fiber_ia_suggested_districts
from final_fiber_ia


/*
Author: Adrianna Boghozian
Created On Date: 08/16/2017
Last Modified Date:
Name of QAing Analyst(s):
Purpose: To define the comparable districts for a district that has an unscalable IA connection.
Methodology: For each district with an unscalable IA connection:
             Define all suggested districts with the following criteria:
             1) Same postal_cd
             2) Within plus or minus one locale as the selected district
             3) Within plus or minus one district_size as the selected district
             4) Has at least one scalable connection.
             5) Cost per mbps IA is not 0.
             Limit to 3 selected districts. Subset first to 10 closest distance, then order by ascending cost_per_mbps_ia and prioritize same SP if tie.
Dependencies: [endpoint.fy2017_districts_deluxe, endpoint.fy2017_unscalable_line_items, endpoint.fy2017_scalable_line_items]
*/

