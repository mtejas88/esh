with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
  /*union
  select esh_id, district_esh_id, postal_cd
  from other_locations
  where district_esh_id is not null*/ -- Removed to match districts table because we decided not to look at services allocated to Other Locations
),

ad as (
  select district_esh_id, a.*
    from allocations a
  join district_lookup dl
  on dl.esh_id = a.recipient_id
),

ad_fiberIA_LI as 
(select * 
  from ad 
inner join 
(select id from line_items 
where 
(internet_conditions_met = TRUE or upstream_conditions_met=TRUE) 
and (connect_category in ('Fiber', 'Fixed Wireless') or connect_type = 'Cable Modem')
and exclude = FALSE 
/*and report_private = true
and report_app_type = true
and (not('consortium_shared' = any(open_flags)) or not('consortium_shared_manual' = any(open_flags)) or open_flags is null) */ 
  and broadband = TRUE) as FiberIA_LineItems
on ad.line_item_id = FiberIA_LineItems.id
where 
(ad.district_esh_id in (select esh_id from districts where num_students != 'No data' and num_students::numeric > 100)
and ad.line_item_id not in (select id from line_items where connect_type = 'Cable Modem'))
or 
(ad.district_esh_id in (select esh_id from districts where num_students != 'No data' and num_students::numeric <= 100)
and ad.line_item_id in (select id from line_items where (connect_type = 'Cable Modem' or connect_category in ('Fiber', 'Fixed Wireless'))))
),
-- ad_FiberIA_LI is ad table for Fiber IA services only, with joined id from line items


ad_IA_LI as 
(select * 
  from ad 
inner join 
(select id, connect_category, connect_type, internet_conditions_met, ISP_conditions_met, upstream_conditions_met, service_provider_name from line_items 
where 
(internet_conditions_met = TRUE or upstream_conditions_met=TRUE) 
/*and report_private = true
and report_app_type = true */and exclude = FALSE
and broadband = TRUE) as IA_LineItems
on ad.line_item_id = IA_LineItems.id
),
-- ad_IA_LI is ad table for IA services only (internet + upstream), with joined fields from line items

ad_WAN_ISP_LI as 
(select * 
  from ad 
inner join 
(select id, WAN_conditions_met,ISP_conditions_met, service_provider_name from line_items 
where 
(ISP_conditions_met = TRUE or WAN_conditions_met=TRUE) 
and report_private = true
and report_app_type = true and exclude = FALSE 
and broadband = TRUE) as WAN_ISP_LineItems
on ad.line_item_id = WAN_ISP_LineItems.id
),
-- ad_WAN_ISP_LI is ad table for WAN & ISP services, with joined fields from line items


-- Fiber Query
cd as (
  select district_esh_id,
  line_item_id,
  c.connect_category,
  c.connect_type,
  c.wan_conditions_met,
  num_lines,
  exclude,
  count(*) as allocation_lines
  
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join district_lookup dl
  on entity_id = dl.esh_id
  left join line_items li
  on c.line_item_id = li.id
  where entity_type in ('School', 'District')
  and exclude_from_reporting = false
  
  group by  district_esh_id,
  line_item_id,
  c.connect_category,
  c.connect_type,
  c.wan_conditions_met,
  num_lines,
  exclude
),

cdd as (
  select cd.district_esh_id,
  districts.num_students::numeric,
  districts.num_schools::numeric,
  districts.locale,
  sum(case when cd.connect_category in ('Fiber', 'Fixed Wireless') 
      then case when allocation_lines < num_lines 
      then allocation_lines
      else num_lines 
      end
      else 0
      end) as fiber_equiv_lines,
  sum(case when cd.connect_type = 'Cable Modem' 
      then case when allocation_lines < num_lines 
      then allocation_lines
      else num_lines 
      end
      else 0
      end) as cable_lines,
  sum(case when cd.connect_type != 'Cable Modem' and cd.connect_category in ('Copper', 'Cable / DSL') 
      then case when allocation_lines < num_lines 
      then allocation_lines
      else num_lines 
      end
      else 0
      end) as copper_dsl_lines,
  sum(case when wan_conditions_met = true and exclude = false
      then case when allocation_lines < num_lines 
      then allocation_lines
      else num_lines 
      end
      else 0
      end) as wan_lines,
  /*(   select count(distinct case when charter=false and max_grade_level != 'PK' then case when address = 'M' then school_nces_cd else address end end)
        from schools
        where schools.district_esh_id = cd.district_esh_id
  ) as num_campuses*/
    districts.num_campuses
  
  from cd
  left join districts
  on cd.district_esh_id = districts.esh_id
  where include_in_universe_of_districts = true
  --and (districts.postal_cd = 'IL') 
  and ia_cost_per_mbps::numeric > 0 
  and ia_cost_per_mbps != 'Insufficient data'
  and ia_cost_per_mbps != 'Infinity'
  
  
  group by district_esh_id, num_students, num_schools, locale, num_campuses
),

cdd_calc as (
  select *,
  case
  when num_campuses < fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
  then num_campuses 
  else fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
  end as known_scalable_campuses,
  case 
  when num_schools > 5 and wan_lines = 0 
  then 
  case 
  when num_campuses > fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
  then num_campuses - fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
  else 0
  end
  else 0
  end as assumed_scalable_campuses,
  case
  when num_students < 100 and copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
  then 
  case
  when num_campuses < (fiber_equiv_lines + cable_lines)
  then 0
  when num_campuses - (fiber_equiv_lines + cable_lines) < copper_dsl_lines
  then num_campuses - (fiber_equiv_lines + cable_lines)
  else copper_dsl_lines
  end
  when num_students >= 100 and (copper_dsl_lines + cable_lines)> 0  and not(num_schools > 5 and wan_lines = 0 ) 
  then
  case
  when num_campuses < (fiber_equiv_lines)
  then 0
  when num_campuses - (fiber_equiv_lines ) < copper_dsl_lines + cable_lines
  then num_campuses - (fiber_equiv_lines)
  else copper_dsl_lines + cable_lines
  end
  else 0
  end as known_unscalable_campuses,
  case 
  when num_schools > 5 and wan_lines = 0 
  then 0 
  else 
    case
  when num_campuses < (fiber_equiv_lines + copper_dsl_lines + cable_lines)
  then 0
  else num_campuses - (fiber_equiv_lines + copper_dsl_lines + cable_lines)
  end
  end as assumed_unscalable_campuses
  
  from cdd
),


-- End Fiber Query


-- Justine's query for circuit breakouts
adli as (
select districts.postal_cd,
line_item_id,
district_esh_id,
num_lines,
connect_category,
bandwidth_in_mbps,
wan_conditions_met,
ia_conditions_met,
internet_conditions_met,
upstream_conditions_met,
isp_conditions_met,
service_provider_name,
connect_type,
sum(num_lines_to_allocate) as allocation_lines

from ad
left join line_items
on ad.line_item_id = line_items.id
left join districts
on ad.district_esh_id = districts.esh_id

where exclude = false
and ad.broadband = true
and include_in_universe_of_districts = TRUE
and districts.postal_cd != 'AK'
and districts.district_size in ('Tiny', 'Small', 'Medium', 'Large', 'Mega')
and districts.locale in ('Urban', 'Suburban', 'Small Town', 'Rural')
and districts.num_students != 'No data'
and ia_bandwidth_per_student != 'Insufficient data'
and ia_cost_per_mbps != 'Insufficient data' 
and ia_cost_per_mbps != 'Infinity'
and exclude_from_analysis = false


group by districts.postal_cd,
line_item_id,
num_lines,
district_esh_id,
connect_category,
bandwidth_in_mbps,
wan_conditions_met,
ia_conditions_met,
internet_conditions_met,
upstream_conditions_met,
isp_conditions_met,
service_provider_name,
connect_type
),
d_adli as (
select postal_cd,
district_esh_id,
sum(case when bandwidth_in_mbps >= 1000 and wan_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as gt_1g_wan_lines,
sum(case when bandwidth_in_mbps < 1000 and connect_category = 'Fiber' and wan_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as lt_1g_fiber_wan_lines,
sum(case when bandwidth_in_mbps < 1000 and connect_category != 'Fiber' and wan_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as lt_1g_nonfiber_wan_lines,
sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Fiber' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as fiber_internet_upstream_lines,
sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Fixed Wireless' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as fixed_wireless_internet_upstream_lines,
sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Cable / DSL' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as cable_dsl_internet_upstream_lines,
sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Copper' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as copper_internet_upstream_lines,
sum(case when internet_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end*bandwidth_in_mbps
else 0 end) as internet_bandwidth_mbps,
sum(case when isp_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end*bandwidth_in_mbps
else 0 end) as isp_bandwidth_mbps,
sum(case when upstream_conditions_met = true then
case when allocation_lines < num_lines then allocation_lines
else num_lines end*bandwidth_in_mbps
else 0 end) as upstream_bandwidth_mbps,
sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and service_provider_name ilike '%centurylink%' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as internet_upstream_centurylink_lines,
sum(case when wan_conditions_met = true and service_provider_name ilike '%centurylink%' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as wan_centurylink_lines,
sum(case when service_provider_name ilike '%verizon%' then
case when allocation_lines < num_lines then allocation_lines
else num_lines end
else 0 end) as verizon_lines,
sum(case when connect_category in ('Fiber') 
then case when allocation_lines < num_lines 
then allocation_lines
else num_lines 
end
else 0
end) as fiber_lines,
sum(case when connect_type in ('Cable Modem') 
then case when allocation_lines < num_lines 
then allocation_lines
else num_lines 
end
else 0
end) as cable_lines,
sum(case when connect_category in ('Fixed Wireless') 
then case when allocation_lines < num_lines 
then allocation_lines
else num_lines 
end
else 0
end) as fixed_wireless_lines

from adli
group by postal_cd, district_esh_id
),
-- End Justine's query for circuit breakouts


-- Justine's query for totally verified districts
av as (
select distinct district_esh_id, a.line_item_id
from allocations a
join district_lookup dl
on dl.esh_id = a.recipient_id
where broadband = true
),

version_order as (
select fy2015_item21_services_and_cost_id,
case when contacted is null or contacted = false then 'false' 
when contacted = true then 'true'
end as contacted,
version_id,
row_number() over (
partition by fy2015_item21_services_and_cost_id 
order by version_id desc
) as row_num

from line_item_notes
where note not like '%little magician%'
),
most_recent as (
select av.line_item_id,
version_order.contacted,
av.district_esh_id,
case when 'assumed_ia' = any(open_flags)
or 'assumed_wan' = any(open_flags)
or 'assumed_fiber' = any(open_flags)
then true else false end as assumed_flags

from av
left join version_order
on av.line_item_id = version_order.fy2015_item21_services_and_cost_id
left join line_items
on av.line_item_id = line_items.id

where row_num = 1
or row_num is null
),

district_counts as (
select district_esh_id,
count(case when contacted = 'true' then 1 end) as true_count,
count(case when contacted = 'false' then 1 end) as false_count,
count(case when contacted is null and assumed_flags = true then 1 end) as null_assumed_count,
count(case when contacted is null and assumed_flags = false then 1 end) as null_untouched_count

from most_recent

group by district_esh_id
),

district_contacted as (
select district_esh_id,
case when true_count >= 1 then 'verified'
when true_count = 0 and false_count >= 1 then 'inferred'
when true_count = 0 and false_count = 0 and null_assumed_count >= 1 then 'interpreted'
when true_count = 0 and false_count = 0 and null_assumed_count = 0 and null_untouched_count >= 1 then 'assumed'
end as clean_categorization,
case when true_count >= 1 and false_count = 0 and null_assumed_count = 0 and null_untouched_count = 0
then true else false end as totally_verified


from district_counts
)

-- End Justine's query for totally verified districts

select *,
(ia_bandwidth_per_student::numeric/1000) * num_students::numeric as total_ia_bw_mbps, 
(ia_bandwidth_per_student::numeric/1000) * num_students::numeric * ia_cost_per_mbps::numeric/12 as total_ia_monthly_cost,
case when ia_bandwidth_per_student::numeric >= 100 then true
else false end as meeting_2014_goal_no_oversub,
case when ia_bandwidth_per_student::numeric * ia_oversub_ratio >= 100 then true
else false end as meeting_2014_goal_oversub,
case when ia_bandwidth_per_student::numeric >= 1000 then true
else false end as meeting_2018_goal_no_oversub,
case when ia_bandwidth_per_student::numeric * ia_oversub_ratio >= 1000 then true
else false end as meeting_2018_goal_oversub,
case when monthly_ia_cost_per_mbps<=3 then true else false end as meeting_$3_per_mbps_affordability_target,
case when esh_id in (select district_esh_id from ad_fiberIA_LI) then 'Fiber IA'
else 'Non-Fiber IA' end as "IA is Fiber or Equiv?", -- TRUE if at least one line is Fiber or Equiv
COALESCE (
  case when (esh_id in (select district_esh_id from ad_fiberIA_LI) and sub.all_IA_connectcat in('{Fiber}', '{"Fixed Wireless"}', '{Fiber,"Fixed Wireless"}')) then 'All Scaleable IA' else NULL end, -- Scalable refers to fiber or fixed wireless or cable for districts <=100 students
  case when (esh_id in (select district_esh_id from ad_fiberIA_LI) and num_students != 'No data' and num_students::numeric <= 100 and sub.all_IA_connectcat in('{Fiber}', '{"Fixed Wireless"}', '{"Cable / DSL"}', '{Fiber,"Fixed Wireless"}', '{"Cable / DSL","Fixed Wireless"}', '{"Cable / DSL",Fiber}', '{"Cable / DSL",Fiber,"Fixed Wireless"}')) then 'All Scaleable IA' else NULL end,
  case when esh_id not in (select district_esh_id from ad_fiberIA_LI) then 'No Scaleable IA' else 'Some Scaleable IA' end
) as percent_scalable_IA, 
COALESCE (
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%Fiber%') then 'Fiber' else NULL end,
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%Fixed Wireless%') then 'Fixed Wireless' else NULL end,
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%Cable%' and sub.all_IA_connecttype ILIKE '%Cable%') then 'Cable' else NULL end,
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%DSL%' and sub.all_IA_connecttype ILIKE '%DSL%') then 'DSL' else NULL end,
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%Copper%') then 'Copper' else NULL end,
  case when (/*select sub.all_connect_categories from sub where*/ sub.all_IA_connectcat ILIKE '%Other%') then 'Other/Uncategorized' else 'None - Error' end
) as hierarchy_connect_category 

from 
(
select 
districts.esh_id,
districts.nces_cd,
districts.name,
ag121a."ULOCAL",
districts.locale,
districts.district_size,
districts.exclude_from_analysis,
districts.consortium_member,
districts.district_type,
districts.num_schools,
districts.num_campuses,
districts.num_students,
districts.num_students_and_staff,
districts.address,
districts.city,
districts.zip,
districts.postal_cd,
districts.latitude,
districts.longitude,
districts.num_flags,
districts.num_open_dirty_flags,
districts.ia_bandwidth_per_student,
districts.wan_bandwidth_per_student,
districts.ia_cost_per_mbps,
districts.ia_cost_per_mbps::numeric/12 as "monthly_ia_cost_per_mbps",
districts.wan_cost_per_connection,
districts.wan_bandwidth_low,
districts.wan_bandwidth_high,
districts.percentage_fiber,
districts.highest_connect_type,
ad_recipients.ALL_IA_CONNECTCAT,
ad_recipients.ALL_IA_CONNECTTYPE,
ad_recipients.INTERNET_SP,
ad_recipients.INTERNET_SP_COUNT,
ad_recipients.UPSTREAM_SP,
ad_recipients2.WAN_SP, ad_recipients2.ISP_SP, district_contacted.clean_categorization, district_contacted.totally_verified, (sc121a_frl.num_frl_students::numeric / sc121a_frl.num_tot_students::numeric) as FRL_Percent,
case when district_size in ('Tiny', 'Small') then 1
when district_size = 'Medium' then 1.5
when district_size = 'Large' then 1.75
when district_size = 'Mega' then 2.25
end as ia_oversub_ratio,
cdd_calc.fiber_equiv_lines, 
cdd_calc.cable_lines,
cdd_calc.copper_dsl_lines,
cdd_calc.num_campuses,
cdd_calc.known_scalable_campuses,
cdd_calc.assumed_scalable_campuses,
cdd_calc.known_unscalable_campuses,
cdd_calc.assumed_unscalable_campuses,
cdd_calc.wan_lines,
d_adli.fiber_internet_upstream_lines,
d_adli.fixed_wireless_internet_upstream_lines,
d_adli.cable_DSL_internet_upstream_lines,
d_adli.copper_internet_upstream_lines,
d_adli.gt_1g_wan_lines,
d_adli.lt_1g_fiber_wan_lines,
d_adli.lt_1g_nonfiber_wan_lines
from  districts
left join 
(select district_esh_id, 
cast(array_agg(distinct connect_category order by connect_category) as text) as all_IA_connectcat, 
cast(array_agg(distinct connect_type order by connect_type) as text) as all_IA_connecttype,
cast(array_agg(distinct case when internet_conditions_met = TRUE then service_provider_name else NULL end) as text) as Internet_SP,
count(distinct case when internet_conditions_met = TRUE then service_provider_name end) as Internet_SP_Count,
cast(array_agg(distinct case when upstream_conditions_met = TRUE then service_provider_name else NULL end) as text) as Upstream_SP,
count(distinct case when upstream_conditions_met = TRUE then service_provider_name end) as Uptream_SP_Count
from ad_IA_LI group by district_esh_id) as ad_recipients 
on districts.esh_id = ad_recipients.district_esh_id
left join 
(select district_esh_id, 
cast(array_agg(distinct case when WAN_conditions_met = TRUE then service_provider_name else NULL end) as text) as WAN_SP,
count(distinct case when WAN_conditions_met = TRUE then service_provider_name end) as WAN_SP_Count,
cast(array_agg(distinct case when ISP_conditions_met = TRUE then service_provider_name else NULL end) as text) as ISP_SP,
count(distinct case when ISP_conditions_met = TRUE then service_provider_name end) as ISP_SP_Count
from ad_WAN_ISP_LI group by district_esh_id) as ad_recipients2
on districts.esh_id = ad_recipients2.district_esh_id
left join district_contacted on district_contacted.district_esh_id = districts.esh_id
left join sc121a_frl on sc121a_frl.nces_cd = districts.nces_cd
left join ag121a on districts.nces_cd = ag121a.nces_cd
left join d_adli on districts.esh_id = d_adli.district_esh_id
left join cdd_calc on cdd_calc.district_esh_id = districts.esh_id
where districts.include_in_universe_of_districts = TRUE
--and exclude_from_analysis = false
--and (districts.postal_cd = 'IL') 
--and districts.district_size in ('Tiny', 'Small', 'Medium', 'Large', 'Mega')
--and districts.locale in ('Urban', 'Suburban', 'Small Town', 'Rural')
--and num_students != 'No data'
and ia_bandwidth_per_student != 'Insufficient data'
and ia_cost_per_mbps != 'Insufficient data' 
and ia_cost_per_mbps != 'Infinity'
and (exclude_from_analysis::varchar='false' OR 'All'='false')
) as sub
