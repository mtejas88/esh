select 	s.esh_id,
       	count(distinct 	case
													when	connect_category ilike '%fiber%'
													and isp_conditions_met = false								
													and	num_open_flags	=	0
													and consortium_shared = false
													and backbone_conditions_met = false	
														then s.esh_id
												end) as fiber_wan_indicator,
       	count(distinct 	case
													when	connect_category ilike '%fiber%'
													and (internet_conditions_met = true or upstream_conditions_met = true)								
													and	num_open_flags	=	0
													and consortium_shared = false
													and backbone_conditions_met = false	
														then s.esh_id
												end) as fiber_internet_upstream_indicator
        
from fy2016.entity_circuits ec
join fy2016.circuits c
on ec.circuit_id = c.id
join fy2016.line_items
on c.line_item_id = line_items.id
right join schools s
on ec.entity_id::varchar = s.esh_id

group by  d.esh_id

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  
Name of QAing Analyst(s):  
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)
*/
