select 	s.school_esh_id,
				flag_array,
				tag_array,
       	count(distinct 	case
													when	li.connect_category ilike '%fiber%'
													and li.isp_conditions_met = false								
													and	li.num_open_flags	=	0
													and li.consortium_shared = false
													and li.backbone_conditions_met = false	
														then s.school_esh_id
												end) as fiber_wan_indicator,
       	count(distinct 	case
													when	li.connect_category ilike '%fiber%'
													and (li.internet_conditions_met = true or li.upstream_conditions_met = true)								
													and	li.num_open_flags	=	0
													and li.consortium_shared = false
													and li.backbone_conditions_met = false	
														then s.school_esh_id
												end) as fiber_internet_upstream_indicator
        
from fy2016.entity_circuits ec
join fy2016.circuits c
on ec.circuit_id = c.id
join fy2016.line_items li
on c.line_item_id = li.id
right join schools_demog_2016 s
on ec.entity_id::varchar = s.school_esh_id
full outer join (
		select	flaggable_id,
						array_agg(distinct label) as flag_array									
													
		from fy2016.flags
		where status = 'open'
		and flaggable_type = 'School'										
													
		group	by	flaggable_id	
) flag_info									
on	flag_info.flaggable_id::varchar	=	s.school_esh_id	
full outer join (
		select	taggable_id,
						array_agg(distinct label) as tag_array									
													
		from fy2016.tags
		where deleted_at is null
		and taggable_type = 'School'											
													
		group	by	taggable_id	
) tag_info									
on	tag_info.taggable_id::varchar	=	s.school_esh_id			

group by  s.school_esh_id,
					flag_array,
					tag_array

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  
Name of QAing Analyst(s):  
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)
*/
