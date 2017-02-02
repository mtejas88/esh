select 	ci.postal_cd,
		parent_entity_name,
		eb_parent.entity_id as parent_entity_id,
		sum(case
				when child_wifi in ('Sometimes','Never')
					then 1
				else 0
			end) as count_wifi_needed

from fy2016.connectivity_informations ci

left join public.entity_bens eb_parent
on ci.parent_entity_number = eb_parent.ben
left join endpoint.fy2016_districts_demog dd
on eb_parent.entity_id = dd.esh_id::text::int

left join public.entity_bens eb_child
on ci.child_entity_number = eb_child.ben
left join endpoint.fy2016_schools_demog sd
on eb_child.entity_id = sd.school_esh_id::text::int

where dd.esh_id is not null
and sd.school_esh_id is not null

group by 	ci.postal_cd,
			parent_entity_name,
			eb_parent.entity_id

/*
Author: Justine Schott
Created On Date:
Last Modified Date: 10/12/2016 - remove mostly
Name of QAing Analyst(s):
Purpose: Determine how a district responded to WiFi connectivity questions
Methodology: JOIN parent to districts and child to schools separately
 */