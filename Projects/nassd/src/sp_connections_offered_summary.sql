with li as (select distinct
line_item_id,
line_item_total_num_lines,
case 
  when connect_category like '%Fiber%'
  then 'Fiber'
  else connect_category
end as connect_category,
reporting_name,
service_provider_name,
recipient_postal_cd as postal_cd

from public.fy2017_services_received_matr sr

left join public.fy2017_districts_deluxe_matr dd
on dd.esh_id = sr.recipient_id

where sr.inclusion_status like '%clean%'
and dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and (sr.purpose = 'Internet' or sr.purpose = 'Upstream')
and connect_category != 'Uncategorized'
and reporting_name != 'District Owned'
and reporting_name != ''),
agg_1 as (

select 
postal_cd,
reporting_name,
count(line_item_id) as total_li,
count(distinct line_item_id) as qa_li,
sum(case
  when connect_category = 'Fiber'
  then 1 end)
as fiber_li,
sum(case
  when connect_category = 'Cable'
  then 1 end)
as cable_li,
sum(case
  when connect_category = 'Fixed Wireless'
  then 1 end)
as wireless_li,
sum(case
  when connect_category = 'Satellite/LTE'
  then 1 end)
as satellite_li,
sum(case
  when connect_category = 'DSL'
  then 1 end)
as dsl_li,
sum(case
  when connect_category = 'Other Copper' or connect_category = 'T-1'
  then 1 end)
as t1_other_copper_li

from li 

group by postal_cd,
reporting_name

union 

select 
'National' as postal_cd,
reporting_name,
count(line_item_id) as total_li,
count(distinct line_item_id) as qa_li,
sum(case
  when connect_category = 'Fiber'
  then 1 end)
as fiber_li,
sum(case
  when connect_category = 'Cable'
  then 1 end)
as cable_li,
sum(case
  when connect_category = 'Fixed Wireless'
  then 1 end)
as wireless_li,
sum(case
  when connect_category = 'Satellite/LTE'
  then 1 end)
as satellite_li,
sum(case
  when connect_category = 'DSL'
  then 1 end)
as dsl_li,
sum(case
  when connect_category = 'Other Copper' or connect_category = 'T-1'
  then 1 end)
as t1_other_copper_li

from li 

group by 
reporting_name)

select *,
round(fiber_li::numeric/total_li::numeric,2) as fiber_li_p,
round(cable_li::numeric/total_li::numeric,2) as cable_li_p,
round(wireless_li::numeric/total_li::numeric,2) as wireless_li_p,
round(satellite_li::numeric/total_li::numeric,2) as satellite_li_p,
round(dsl_li::numeric/total_li::numeric,2) as dsl_li_p,
round(t1_other_copper_li::numeric/total_li::numeric,2) as t1_other_copper_li_p

from agg_1

order by postal_cd

/*

Author: Jamie Barnes
Date: 8/4/2017
Purpose: For NASSD Service Provider Dashboard - Calculates types of connections offered by all clean 2017 Internet & Upstream  SPs.
Calculations are done at National and State level using a union/group by.

*/