select ds.campus_id,
	   s.district_esh_id,
       c.line_item_id,
       count(distinct circuit_id) as allocation_lines

from public.entity_circuits ec
join public.circuits c
on ec.circuit_id = c.id
join public.schools s
on ec.entity_id = s.esh_id
join public.districts_schools ds
on ec.entity_id = ds.school_id


where sd.charter = false
and sd.max_grade_level != 'PK'

group by   ds.campus_id,
		   s.district_esh_id,
	       c.line_item_id

/*
Author: Justine Schott
Created On Date: 12/8/2016
Last Modified Date:
Name of QAing Analyst(s):
*/