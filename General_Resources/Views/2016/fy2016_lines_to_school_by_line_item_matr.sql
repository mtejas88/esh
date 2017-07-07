select sd.campus_id,
	   sd.district_esh_id,
       c.line_item_id,
       count(distinct circuit_id) as allocation_lines
        
from fy2016.entity_circuits ec
join fy2016.circuits c
on ec.circuit_id = c.id
join public.fy2016_schools_demog_matr sd
on ec.entity_id::varchar = sd.school_esh_id

group by  campus_id,
	   	  district_esh_id,
          line_item_id

/*
Author: Jess Seok
Created On Date: 11/18/2016
Last Modified Date: 
Name of QAing Analyst(s):Justine Schott
*/