with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
),
ad as (
  select district_esh_id, a.*
  from allocations a
  join district_lookup dl
  on dl.esh_id = a.recipient_id
),
ae as (
select district_esh_id,
line_item_id,
sum(num_lines_to_allocate) as "district_num_lines_received"
from ad
GROUP BY district_esh_id,line_item_id
),
af as (
select ae.district_esh_id,
x.name,
x.postal_cd,
ae.line_item_id,
li.consortium_shared,
case when li.consortium_shared=true and ia_conditions_met=true
then 'Shared IA'
when li.consortium_shared=true and 'backbone'=any(open_flags)
then 'Backbone'
else 'District-dedicated' end as "shared_service",
case when li.consortium_shared=false and ae.district_num_lines_received>=li.num_lines 
then li.num_lines::varchar
when li.consortium_shared=true OR 'backbone'=any(open_flags)
then 'Shared Circuit'
else ae.district_num_lines_received::varchar end as "quantity_of_lines_received_by_district",
li.bandwidth_in_mbps,
li.connect_type,
li.purpose,
li.wan,

case when li.rec_elig_cost!='No data' and li.consortium_shared=false and ae.district_num_lines_received>=li.num_lines and li.total_cost::numeric>0 and li.num_lines!=0 and li.orig_r_months_of_service is not null
and li.orig_r_months_of_service!=0 
then li.total_cost::numeric/li.orig_r_months_of_service 
when li.consortium_shared=false and ae.district_num_lines_received<li.num_lines and li.num_lines!=0 and li.total_cost::numeric>0 
and li.orig_r_months_of_service is not null and li.orig_r_months_of_service!=0 
then (ae.district_num_lines_received/li.num_lines)*
(li.total_cost::numeric/li.orig_r_months_of_service)
when li.consortium_shared=true OR 'backbone'=any(li.open_flags) then (x.num_students::numeric/z.num_students_served)*(li.total_cost::numeric/li.orig_r_months_of_service)  
else 0 end as "district_monthly_cost",

case when li.orig_r_months_of_service is not null and li.rec_elig_cost!='No data'
and li.orig_r_months_of_service!=0 then li.total_cost::numeric/li.orig_r_months_of_service 
else li.total_cost::numeric/12 end as "line_item_total_monthly_cost",

ae.district_num_lines_received as "cat.1_allocations_to_district",
li.num_lines as "line_item_total_num_lines",
li.total_cost as "line_item_total_cost",
li.rec_elig_cost as "line_item_recurring_elig_cost",
li.one_time_eligible_cost as "line_item_one-time_cost",
li.orig_r_months_of_service,
li.applicant_name,
li.isp_conditions_met,
li.internet_conditions_met,
li.ia_conditions_met,
li.wan_conditions_met,
li.upstream_conditions_met,
li.broadband,
li.exclude,
array_to_string(li.open_flags,', ') as "open_flags",
case when 'exclude'=any(open_flags) then true else false end as "dqs_excluded",
case when x.ia_cost_per_mbps!='Insufficient data' and x.ia_cost_per_mbps!='Infinity' 
then x.ia_cost_per_mbps::numeric/12 else null end as "monthly_ia_cost_per_mbps",
case when x.ia_bandwidth_per_student!='Insufficient data' and x.num_students!='No data' then 
((x.ia_bandwidth_per_student::numeric*x.num_students::bigint)/1000)::int
else null end as "district_total_ia_rounded_to_nearest_mbps",
x.ia_bandwidth_per_student,
x.num_students,
x.num_students_and_staff,
x.num_schools,
x.locale,
x.district_size,
x.exclude_from_analysis,
x.consortium_member,
li.service_provider_name

from ae

left join line_items li
on ae.line_item_id=li.id

left join districts x
on ae.district_esh_id=x.esh_id

left join lateral (

select y.line_item_id,
y.num_students_served

from (

select a.line_item_id,
max(f.applicant_name) as "applicant_name",
max(f.applicant_id) as "applicant_id",
max(f.applicant_postal_cd) as "applicant_postal_cd",
array_agg(DISTINCT b.district_esh_id::varchar) as "district_esh_id",
count(DISTINCT b.district_esh_id) as "num_district_recipients",
sum(DISTINCT c.num_students::bigint) as "num_students_served",
array_agg(DISTINCT c.name) as "district_name",
array_agg(DISTINCT e.district_ben::varchar) as "district_ben"

from allocations a

left join lateral (select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
  union
  select esh_id, district_esh_id, postal_cd
  from other_locations
  where district_esh_id is not null) b
on a.recipient_id=b.esh_id

left join districts c
on b.district_esh_id=c.esh_id

left join lateral (
select array_agg(d.ben) as "district_ben",
d.entity_id
from esh_id_mappings d
GROUP BY d.entity_id) e
on c.esh_id=e.entity_id

left join line_items f
on a.line_item_id=f.id

where c.num_students!='No data'
GROUP BY a.line_item_id)y )z
on ae.line_item_id=z.line_item_id

where li.broadband=true and 
(li.consortium_shared=false OR li.ia_conditions_met=true OR 'backbone'=any(li.open_flags))  
and x.include_in_universe_of_districts=true 
and (case when 'exclude'=any(open_flags) then true else false end)=false)
  
select * 
from af

ORDER BY district_esh_id
