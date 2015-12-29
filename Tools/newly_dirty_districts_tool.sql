/*
Author: Greg Kurzhals 
Created On Date: 12/23/2015 
Last Modified Date: 12/23/2015 
Name of QAing Analyst(s):  
Purpose: Identifies formerly clean/dirty districts that have changed status since the previous morning's 
flagging cycle.
Methodology: Each query begins with the sub-qury "sc", which isolates every change to an entity-level flag 
that occurred on the specified date(s). (Note that in most cases the user should enter the previous date in 
the field "date_of_last_dqs_cleaning", as this is required to identify "call_to_clarify" flags manually 
applied since the time of the previous automatic flagging cycle.) A district is identified as "newly cleaned"
if at least one of its entity-level flags was updated on the specified date(s), and if the district's
'exclude_from_analysis' field is 'false.  The reverse criteria identify a district as "newly dirty", provided 
that the total number of dirty entity-level flags opened or added on the specified date(s) match the number 
currently open.
*/

with sc as (

select ef.entity_id,
districts.exclude_from_analysis,
v.item_id,
case when object is null then 'created'
  when LENGTH(v.item_id::varchar)=5
  then 
  SUBSTRING(object,63,1)
  else SUBSTRING(object,64,1)
  end as "status_before_change",
  ef.status as "current_status",
  ef.label,
  ef.user_id as "updated_by",
  v.created_at
  
from versions v

left join lateral (
select max(ver.created_at) as "last_update",
ver.item_id
from versions ver
where item_type='EntityFlag'
GROUP BY ver.item_id) x
on v.item_id=x.item_id

left join entity_flags ef
on v.item_id=ef.id

left join districts
on ef.entity_id=districts.esh_id

where item_type='EntityFlag'
and ef.dirty=true
and v.created_at=x.last_update
and ((v.created_at::varchar LIKE '{{date_today}}%' and ef.label!='call_to_clarify')
OR (v.created_at::varchar LIKE '{{date_of_last_dqs_cleaning}}%' and ef.label='call_to_clarify'))
ORDER BY item_id),

nc as (select *,
case when exclude_from_analysis=true and (status_before_change='1' or status_before_change='created') 
then 'Yes' else 'No' end as "newly_dirty"
from sc)

select entity_id,
max(districts.name) as "name",
max(districts.postal_cd) as "postal_cd",
max(districts.num_open_dirty_flags) as "num_open_dirty_flags",
count(item_id) as "num_flags_opened/added",
array_agg(nc.label) as "flags",
array_agg(nc.updated_by) as "updated_by",
array_agg(CAST(nc.created_at AS DATE)) as "updated_at"
from nc

left join districts
on nc.entity_id=districts.esh_id
where "newly_dirty"='Yes' 
GROUP BY nc.entity_id
having max(districts.num_open_dirty_flags)=count(item_id)


{% form %}

date_today:
  type: text
  default: 2015-12-23
  
date_of_last_dqs_cleaning:
  type: text
  default: 2015-12-22
  
{% endform %}
