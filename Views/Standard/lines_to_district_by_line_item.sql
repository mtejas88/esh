select dl.district_esh_id,
         c.line_item_id,
         count(distinct circuit_id) as allocation_lines
        
from entity_circuits ec
join circuits c
on ec.circuit_id = c.id
join district_lookup dl
on ec.entity_id = dl.esh_id

where entity_type in ('School', 'District')
and exclude_from_reporting = false

group by  district_esh_id,
          line_item_id

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date: 
Name of QAing Analyst(s):  
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district; excludes dirty line items
                              and normal line item exclusions, such as consortium_shared line items
*/