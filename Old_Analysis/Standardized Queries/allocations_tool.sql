/*
Author: Greg Kurzhals
Created On Date: 11/02/2015
Last Modified Date: 02/27/2016
Name of QAing Analyst(s): Justine Schott
Purpose: Returns the list of recipients (including name, id, type, and district_esh_id) of a specified line item
Methodology: Subquery creates a universal list of entities (i.e. all districts, schools, and other locations), and joins this list to the allocations table - Liquid parameter 
template allows user to limit results to a single line item
Dependencies: N/A
*/


select a.id,
a.line_item_id,
a.recipient_id,
a.recipient_type,
a.recipient_ben,
a.recipient_name,
a.num_lines_to_allocate,
district_lookup_incl_noned.district_esh_id,
d.name,
d.num_schools,
d.num_students,
d.include_in_universe_of_districts

from allocations a

--commonly used sub-query that returns list of all entities with associated district_esh_id and postal_cd
left join lateral (select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
  union
  select esh_id, district_esh_id, postal_cd
  from other_locations
  where district_esh_id is not null) district_lookup_incl_noned
on a.recipient_id=district_lookup_incl_noned.esh_id

left join districts d
on district_lookup_incl_noned.district_esh_id=d.esh_id

--where statement limits results to user-entered line_item_id or postal_cd
where (a.line_item_id::varchar='{{line_item_id}}' or 'All' = '{{line_item_id}}')
and (d.postal_cd='{{state}}' or 'All' = '{{state}}')
ORDER BY district_lookup_incl_noned.district_esh_id, d.include_in_universe_of_districts

{% form %}

state:
  type: text
  default: 'All' 

line_item_id:
  type: text
  default: '377986' 
  
{% endform %}
