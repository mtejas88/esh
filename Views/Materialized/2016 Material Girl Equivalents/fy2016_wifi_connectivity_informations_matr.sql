select 	ci.postal_cd,
		ci.parent_entity_name,
		eb_parent.entity_id as parent_entity_id,
		sum(case
				when t.label = 'sufficient_wifi' 
				  then 0
				when t.label = 'insufficient_wifi' 
				  then 1
				when child_wifi in ('Sometimes','Never')
					then 1
				else 0
			end) as count_wifi_needed

from fy2016.connectivity_informations ci

left join public.entity_bens eb_parent
on ci.parent_entity_number = eb_parent.ben
left join public.fy2016_districts_demog_matr dd
on eb_parent.entity_id = dd.esh_id::text::int
left join fy2016.tags t
on dd.esh_id::text::int = t.taggable_id
and t.label in ('sufficient_wifi', 'insufficient_wifi') 

left join public.entity_bens eb_child
on ci.child_entity_number = eb_child.ben
left join public.fy2016_schools_demog_matr sd
on eb_child.entity_id = sd.school_esh_id::text::int

where dd.esh_id is not null
and sd.school_esh_id is not null

group by 	ci.postal_cd,
			ci.parent_entity_name,
			eb_parent.entity_id

/*
Author: Justine Schott
Created On Date:
Last Modified Date: 1/26/2017 - added appropriate tage names so dqt can override a district's 471 response, used fy2016.tags table to check for tags (JH)
Name of QAing Analyst(s):
Purpose: Determine how a district responded to WiFi connectivity questions
Methodology: JOIN parent to districts and child to schools separately
Dependencies: [public.fy2016_districts_demog_matr, public.fy2016_schools_demog_matr, fy2016.tags]
 */