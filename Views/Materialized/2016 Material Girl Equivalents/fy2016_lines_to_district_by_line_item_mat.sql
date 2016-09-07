select dl.district_esh_id,
         c.line_item_id,
         count(distinct circuit_id) as allocation_lines
        
from fy2016.entity_circuits ec
join fy2016.circuits c
on ec.circuit_id = c.id
join fy2016_district_lookup_mat dl
on ec.entity_id::varchar = dl.esh_id

group by  district_esh_id,
          line_item_id

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  09/06/2016
Name of QAing Analyst(s):  
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)
*/
