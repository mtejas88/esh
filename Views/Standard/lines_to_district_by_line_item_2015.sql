select dl.district_esh_id,
         c.line_item_id,
         count(distinct circuit_id) as allocation_lines
        
from public.entity_circuits ec
join public.circuits c
on ec.circuit_id = c.id
join district_lookup_2015 dl
on ec.entity_id = dl.esh_id

group by  district_esh_id,
          line_item_id

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date:           06/02/2016
Name of QAing Analyst(s):  
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2015)
*/
