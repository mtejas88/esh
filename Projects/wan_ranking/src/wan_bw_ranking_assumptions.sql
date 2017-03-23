with district_school_lookup as (

select d.esh_id,
ds.campus_id,
ds.school_id,
s.num_students

from public.fy2016_districts_deluxe_matr d

left join fy2016.districts_schools ds
on d.esh_id = ds.district_id::varchar

left join fy2016.schools s
on ds.school_id = s.esh_id

left join fy2016.flags f
on s.esh_id = f.flaggable_id

where d.include_in_universe_of_districts
and d.district_type = 'Traditional'
and d.exclude_from_wan_analysis = false
--TOOK OUT CLOSED, CHARTER, NON SCHOOL
and s.esh_id not in(
  select flaggable_id as school_id
  from fy2016.flags
  where status = 'open'
  and label in ('non_school','charter_school','closed_school')
  and flaggable_type = 'School'
)

),

campus_matching as (

select ds.esh_id::varchar,
ds.campus_id::varchar as campus_or_school_id,
sum(ds.num_students)::integer as num_students

from district_school_lookup ds

join public.fy2016_districts_deluxe_matr d
on ds.esh_id = d.esh_id

where d.wan_lines = d.num_campuses

group by  ds.esh_id,
          ds.campus_id

order by  ds.esh_id,
          sum(ds.num_students) desc
),

school_matching as (

select ds.esh_id::varchar,
ds.school_id::varchar as campus_or_school_id,
ds.num_students::integer as num_students

from district_school_lookup ds

join public.fy2016_districts_deluxe_matr d
on ds.esh_id = d.esh_id

where d.wan_lines = d.num_schools
and d.wan_lines != d.num_campuses

order by  ds.esh_id,
          ds.num_students desc

),

school_campus_summary as (

select *,
row_number() over (partition by esh_id order by num_students desc) as rank--dont want ties, so using row_number
from campus_matching

union

select *,
row_number() over (partition by esh_id order by num_students desc) as rank --dont want ties, so using row_number
from school_matching


order by  esh_id asc,
          num_students desc
          
),

wan_lookup as (

select s.recipient_id,
s.bandwidth_in_mbps,
s.quantity_of_line_items_received_by_district,
c.id,
row_number() over (partition by s.recipient_id order by s.bandwidth_in_mbps desc) as rank --dont want ties, so using row_number

from public.fy2016_services_received_matr s

left join public.fy2016_districts_deluxe_matr d
on s.recipient_id = d.esh_id

left join fy2016.circuits c
on s.line_item_id = c.line_item_id

left join fy2016.entity_circuits ec 
on c.id = ec.circuit_id 


where s.purpose = 'WAN'
and s.inclusion_status != 'dqs_excluded'
and d.exclude_from_wan_analysis = false
and ec.entity_id in (
  select esh_id::integer as entity_id
  from public.fy2016_district_lookup_matr
)

group by  s.recipient_id,
          s.bandwidth_in_mbps,
          s.quantity_of_line_items_received_by_district,
          c.id

order by  s.recipient_id,
          s.bandwidth_in_mbps desc
          
)

select s.esh_id,
s.campus_or_school_id,
s.num_students,
s.rank,
w.bandwidth_in_mbps,
w.quantity_of_line_items_received_by_district,
w.id,
1000 * w.bandwidth_in_mbps::integer / s.num_students::integer  as wan_bw_per_student_kbps,
d.postal_cd,
d.name,
d.lt_1g_fiber_wan_lines,
d.lt_1g_nonfiber_wan_lines

from school_campus_summary s

join wan_lookup w
on s.esh_id = w.recipient_id
and s.rank = w.rank

join public.fy2016_districts_deluxe_matr d
on s.esh_id = d.esh_id

where s.num_students::integer > 0
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'

/*
Author: Jeremy Holtzman
Created On Date: 3/6/2017
Last Modified Date: 3/6/2017
Name of QAing Analyst(s): Solomon
Purpose: The purpose is to determine if the WAN connections in a district are large enough to meet 2018 goals 
  (1 mbps / student), 2014 goals (100 kbps / student), or neither (less than 100 kbps / student). 
Methodology: Because we don't always know where the WAN connections go, we've just assumed that the largest WAN 
  connection in a district goes to the biggest school or campus.
*/