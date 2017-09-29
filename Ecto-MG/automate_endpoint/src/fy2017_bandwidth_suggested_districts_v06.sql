-- Create Temp Data for Mark and Meghan to QA Suggested Districts Logic Changes

-- Define Bandwidth Suggested Districts
------------------------------------------------------------------------
-- temp tables to enable finding comparisons for each district:
-- limit to the locale and district_size options: plus or minus 1 locale and district size
with lookup as (
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
and l.postal_cd = l2.postal_cd
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
array_agg(districts) as suggested_districts
from unagg_lookup
group by postal_cd, locale, district_size),

-- merge all districts by postal_cd, locale, district_size
all_comps_merged as (select dd.esh_id,
ac.suggested_districts
from endpoint.fy2017_districts_deluxe as dd
left join all_comps as ac
on ac.postal_cd = dd.postal_cd
and ac.locale = dd.locale
and ac.district_size = dd.district_size
where dd.include_in_universe_of_districts = true),

-- unaggregate so can merge in district details for district pairs
all_comps_unagg as (select esh_id,
unnest(suggested_districts) as suggested_districts
from all_comps_merged),

-- filter to suggested districts for Bandwidth
-- merge in district info so can filter suggested districts
-- calculate distance
-- subset to districts in universe for both primary and matches
-- and clean districts for matches (and matches don't have cost/mbps = 0)
bandwidth_suggested as (select
ac.esh_id,
dd.include_in_universe_of_districts as primary_include_in_universe,
dd.hierarchy_ia_connect_category as primary_hierarchy_ia_connect_category,
dd.service_provider_assignment as primary_service_provider,
case
  when dd.exclude_from_ia_analysis = TRUE and dd.bw_target_status = 'Target' then FALSE
  else dd.meeting_2014_goal_no_oversub
end as primary_meeting_2014_goal_no_oversub,
dd.meeting_knapsack_affordability_target as primary_meeting_knapsack_affordability,
dd.ia_monthly_cost_total as primary_ia_monthly_cost_total,
dd.projected_bw_fy2014_cck12 as primary_projected_bw_fy2014_cck12,
case
  when dd.ia_monthly_cost_total >= 700 then knapsack_bandwidth(dd.ia_monthly_cost_total)
  else dd.ia_monthly_cost_total/14
end as primary_knapsack_bandwidth,
ac.suggested_districts,
dd2.include_in_universe_of_districts as match_include_in_universe,
dd2.exclude_from_ia_analysis as match_exclude_from_ia_analysis,
dd2.ia_bw_mbps_total as match_ia_bw_mbps_total,
dd2.hierarchy_ia_connect_category as match_hierarchy_ia_connect_category,
dd2.service_provider_assignment as match_service_provider,
dd2.meeting_2014_goal_no_oversub as match_meeting_2014_goal_no_oversub,
dd2.meeting_knapsack_affordability_target as match_meeting_knapsack_affordability,
dd2.ia_monthly_cost_total as match_ia_monthly_cost_total,
case
  when dd.service_provider_assignment = dd2.service_provider_assignment then 1
  else 0
end as same_service_provider,
case
  when dd2.hierarchy_ia_connect_category = 'Fiber' then 1
  else 0
end as fiber_indicator,
ST_Distance(geography(dd.geom),geography(dd2.geom)) as distance
from all_comps_unagg ac
left join endpoint.fy2017_districts_deluxe as dd
on ac.esh_id = dd.esh_id
left join endpoint.fy2017_districts_deluxe as dd2
on ac.suggested_districts = dd2.esh_id
-- do not allow districts to be their own option
where ac.esh_id != ac.suggested_districts
and dd.include_in_universe_of_districts = TRUE
and dd2.include_in_universe_of_districts = TRUE
-- the selected district must be clean, or they can be a dirty bw target (5 total)
and ((dd.exclude_from_ia_analysis = FALSE and dd.meeting_2014_goal_no_oversub = FALSE)
or (dd.exclude_from_ia_analysis = TRUE and dd.bw_target_status = 'Target')
or (dd.exclude_from_ia_cost_analysis = FALSE and dd.meeting_knapsack_affordability_target = FALSE))
-- the suggested districts must be clean for IA cost
and dd2.exclude_from_ia_cost_analysis = FALSE
and dd2.ia_monthly_cost_total != 0
-- require that suggested districts are paying less than or equal to the selected district
and dd2.ia_monthly_cost_total <= dd.ia_monthly_cost_total
-- also require that suggested districts have at least some Lit Fiber
and dd2.all_ia_connectcat ilike '%Lit Fiber%'
-- also take out district, city, county-owned for the suggested districts
and not(lower(dd2.service_provider_assignment) ilike '%owned%')
-- right now, going to still include NULL SPs since there are ~200 total with no dominant SP
and lower(dd2.service_provider_assignment) not in ('unknown','n/a','')),

-- subset matches to those that are meeting the goal that the selected district isn't
filter_matches as (select *
from bandwidth_suggested
where primary_meeting_2014_goal_no_oversub = FALSE and match_meeting_2014_goal_no_oversub = TRUE
-- require suggested districts have total BW greater than or equal to projected 2014 BW of selected district
and match_ia_bw_mbps_total >= primary_projected_bw_fy2014_cck12
union
select *
from bandwidth_suggested
where primary_meeting_2014_goal_no_oversub = TRUE and primary_meeting_knapsack_affordability = FALSE and match_meeting_knapsack_affordability = TRUE
-- require suggested districts have total BW greater than or equal to projected Knapsack BW of selected district
and match_ia_bw_mbps_total >= primary_knapsack_bandwidth
order by esh_id),

-- rank matches by distance
rank_matches as (select *,
row_number() over (partition by esh_id order by distance asc) as district_distance_rank
from filter_matches),

-- limit districts by distance: select top 10
-- also order by esh_id, match_ia_monthly_cost_total, fiber_indicator, same_service_provider, and district_distance_rank
limit_matches as (select *
from rank_matches
where district_distance_rank <= 10
order by esh_id, match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc),

-- order top 10 districts by methodology: lowest ia_monthly_cost_total, prioritize fiber if tie, prioritize same SP if tie, prioritize closest district if tie
order_bandwidth as (select *,
row_number() over (partition by esh_id order by match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc) as district_rank
from limit_matches),

-- reaggregate
final_bandwidth as (select esh_id,
array_agg(suggested_districts order by match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc) as bandwidth_suggested_districts
from order_bandwidth
where district_rank <= 3
group by esh_id),

-- combine with all suggested districts
all_bandwidth as (select esh_id,
array_agg(suggested_districts) as all_bandwidth_suggested_districts
from rank_matches
group by esh_id),

final_bandwidth_combined as (select fb.*,
ab.all_bandwidth_suggested_districts
from final_bandwidth fb
left join all_bandwidth ab
on fb.esh_id = ab.esh_id),



-- for the Megas that have NULL suggestions in their own state, expand to the rest of the states
-- aggregate the locale, district_size options
agg_lookup_megas as (select l2.district_size as l2district,
l2.locale as l2locale,
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
and (l.district_size = 'Mega' and l2.district_size = 'Mega')
order by 3,4,5),

-- unwrap locale, district_size options to allow to reaggregate
unagg_lookup_megas as (
select locale,
district_size,
unnest(districts) as districts
from agg_lookup_megas),

-- reaggregate
all_comps_megas as (
select locale,
district_size,
array_agg(districts) as suggested_districts
from unagg_lookup_megas
group by locale, district_size),

-- merge all districts by locale, district_size
all_comps_merged_megas as (select dd.esh_id,
ac.suggested_districts
from endpoint.fy2017_districts_deluxe as dd
left join all_comps_megas as ac
on ac.locale = dd.locale
and ac.district_size = dd.district_size
where dd.include_in_universe_of_districts = true),

-- unaggregate so can merge in district details for district pairs
all_comps_unagg_megas as (select esh_id,
unnest(suggested_districts) as suggested_districts
from all_comps_merged_megas),

-- take out megas that already have suggested districts or are meeting both goals
bandwidth_suggested_megas as (select ac.esh_id,
dd.include_in_universe_of_districts as primary_include_in_universe,
dd.hierarchy_ia_connect_category as primary_hierarchy_ia_connect_category,
dd.service_provider_assignment as primary_service_provider,
case
  when dd.exclude_from_ia_analysis = TRUE and dd.bw_target_status = 'Target' then FALSE
  else dd.meeting_2014_goal_no_oversub
end as primary_meeting_2014_goal_no_oversub,
dd.meeting_knapsack_affordability_target as primary_meeting_knapsack_affordability,
dd.ia_monthly_cost_total as primary_ia_monthly_cost_total,
dd.projected_bw_fy2014_cck12 as primary_projected_bw_fy2014_cck12,
case
  when dd.ia_monthly_cost_total >= 700 then knapsack_bandwidth(dd.ia_monthly_cost_total)
  else dd.ia_monthly_cost_total/14
end as primary_knapsack_bandwidth,
ac.suggested_districts,
dd2.include_in_universe_of_districts as match_include_in_universe,
dd2.exclude_from_ia_analysis as match_exclude_from_ia_analysis,
dd2.ia_bw_mbps_total as match_ia_bw_mbps_total,
dd2.hierarchy_ia_connect_category as match_hierarchy_ia_connect_category,
dd2.service_provider_assignment as match_service_provider,
dd2.meeting_2014_goal_no_oversub as match_meeting_2014_goal_no_oversub,
dd2.meeting_knapsack_affordability_target as match_meeting_knapsack_affordability,
dd2.ia_monthly_cost_total as match_ia_monthly_cost_total,
case
  when dd.service_provider_assignment = dd2.service_provider_assignment then 1
  else 0
end as same_service_provider,
case
  when dd2.hierarchy_ia_connect_category = 'Fiber' then 1
  else 0
end as fiber_indicator,
ST_Distance(geography(dd.geom),geography(dd2.geom)) as distance
from all_comps_unagg_megas ac
left join endpoint.fy2017_districts_deluxe dd
on dd.esh_id = ac.esh_id
left join final_bandwidth fb
on fb.esh_id = ac.esh_id
left join endpoint.fy2017_districts_deluxe as dd2
on ac.suggested_districts = dd2.esh_id
where fb.bandwidth_suggested_districts is null
and (dd.meeting_2014_goal_no_oversub = false or dd.meeting_knapsack_affordability_target = false)
and ac.esh_id != ac.suggested_districts
and dd.include_in_universe_of_districts = TRUE
and dd2.include_in_universe_of_districts = TRUE
-- the selected district must be clean, or they can be a dirty bw target (5 total)
and ((dd.exclude_from_ia_analysis = FALSE and dd.meeting_2014_goal_no_oversub = FALSE)
or (dd.exclude_from_ia_analysis = TRUE and dd.bw_target_status = 'Target')
or (dd.exclude_from_ia_cost_analysis = FALSE and dd.meeting_knapsack_affordability_target = FALSE))
-- the suggested districts must be clean for IA cost
and dd2.exclude_from_ia_cost_analysis = FALSE
and dd2.ia_monthly_cost_total != 0
-- require that suggested districts are paying less than or equal to the selected district
and dd2.ia_monthly_cost_total <= dd.ia_monthly_cost_total
-- also require that suggested districts have at least some Lit Fiber
and dd2.all_ia_connectcat ilike '%Lit Fiber%'
-- also take out district, city, county-owned for the suggested districts
and not(lower(dd2.service_provider_assignment) ilike '%owned%')
-- right now, going to still include NULL SPs since there are ~200 total with no dominant SP
and lower(dd2.service_provider_assignment) not in ('unknown','n/a','')),

-- subset matches to those that are meeting the goal that the selected district isn't
filter_matches_megas as (select *
from bandwidth_suggested_megas
where primary_meeting_2014_goal_no_oversub = FALSE and match_meeting_2014_goal_no_oversub = TRUE
-- require suggested districts have total BW greater than or equal to projected 2014 BW of selected district
and match_ia_bw_mbps_total >= primary_projected_bw_fy2014_cck12
union
select *
from bandwidth_suggested_megas
where primary_meeting_2014_goal_no_oversub = TRUE and primary_meeting_knapsack_affordability = FALSE and match_meeting_knapsack_affordability = TRUE
-- require suggested districts have total BW greater than or equal to projected Knapsack BW of selected district
and match_ia_bw_mbps_total >= primary_knapsack_bandwidth
order by esh_id),

-- rank matches by distance
rank_matches_megas as (select *,
row_number() over (partition by esh_id order by distance asc) as district_distance_rank
from filter_matches_megas),

-- limit districts by distance: select top 10
-- also order by esh_id, match_ia_monthly_cost_total, fiber_indicator, same_service_provider, and district_distance_rank
limit_matches_megas as (select *
from rank_matches_megas
where district_distance_rank <= 10
order by esh_id, match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc),

-- order top 10 districts by methodology: lowest ia_monthly_cost_total, prioritize fiber if tie, prioritize same SP if tie, prioritize closest district if tie
order_bandwidth_megas as (select *,
row_number() over (partition by esh_id order by match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc) as district_rank
from limit_matches_megas),

-- reaggregate
final_bandwidth_megas as (select esh_id,
array_agg(suggested_districts order by match_ia_monthly_cost_total asc, fiber_indicator desc, same_service_provider desc, district_distance_rank asc) as bandwidth_suggested_districts
from order_bandwidth_megas
where district_rank <= 3
group by esh_id),

-- combine with all suggested districts
all_bandwidth_megas as (select esh_id,
array_agg(suggested_districts) as all_bandwidth_suggested_districts
from rank_matches_megas
group by esh_id),

final_bandwidth_combined_megas as (select fb.*,
ab.all_bandwidth_suggested_districts
from final_bandwidth_megas fb
left join all_bandwidth_megas ab
on fb.esh_id = ab.esh_id),

all_suggestions as (select *
from final_bandwidth_combined
union
select *
from final_bandwidth_combined_megas),

unwrap_suggestions as (select esh_id,
unnest(bandwidth_suggested_districts) as bandwidth_suggested_districts
from all_suggestions)

select us.esh_id as selected_district_id,
dd.name as selected_district_name,
dd.ia_monthly_cost_total as selected_district_ia_monthly_cost_total,
dd.ia_bw_mbps_total as selected_district_ia_bw_mbps_total,
us.bandwidth_suggested_districts as suggested_district_id,
dd2.ia_monthly_cost_total as suggested_district_ia_monthly_cost_total,
dd2.ia_bw_mbps_total as suggested_district_ia_bw_mbps_total
from unwrap_suggestions us
left join endpoint.fy2017_districts_deluxe dd
on us.esh_id = dd.esh_id
left join endpoint.fy2017_districts_deluxe dd2
on us.bandwidth_suggested_districts = dd2.esh_id
order by selected_district_id

