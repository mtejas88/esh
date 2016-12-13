select campus_id,
	   district_esh_id,
       line_item_id,
       count(distinct circuit_id) as allocation_lines

from public.entity_circuits ec
join public.circuits c
on ec.circuit_id = c.id
join public.fy2016_schools_demog_matr sd
on ec.entity_id::varchar = sd.school_esh_id

group by   campus_id,
		   district_esh_id,
	       line_item_id
/*
Author: Justine Schott
Created On Date: 12/8/2016
Last Modified Date:
Name of QAing Analyst(s):
*/