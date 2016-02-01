/*
Author: Justine Schott
Created On Date: 12/30/2015
Last Modified Date: 01/04/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: To track district flags, line items, costs, and applicants as data comes in for 2016
Methodology:Using districts table, entity_flags, and line_items tables
*/

select  label,
		dirty,
		count(1) as count_of_districts,
		count(1)/(
					  select count(1)
					  from districts
					  where include_in_universe_of_districts=true
		)::numeric as percent_of_districts

from entity_flags
left join districts
on entity_flags.entity_id = districts.esh_id

where include_in_universe_of_districts=true
and status = 1

group by label, dirty
order by dirty, label