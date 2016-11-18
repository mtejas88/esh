select ec.entity_id as school_esh_id,
       c.line_item_id,
       count(distinct circuit_id) as allocation_lines
        
from fy2016.entity_circuits ec
join fy2016.circuits c
on ec.circuit_id = c.id

group by  school_esh_id,
          line_item_id

/*
Author: Jess Seok
Created On Date: 11/18/2016
Last Modified Date: 
Name of QAing Analyst(s):Justine Schott
*/