

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




from fy2017.connectivity_informations ci




left join salesforce.account eb_parent

on ci.parent_entity_number::varchar = eb_child.ben__c::varchar --forcing data types to be varchar for seamless join

left join public.fy2017_districts_demog_matr dd

on eb_parent.esh_id__c::varchar = dd.esh_id::varchar

left join (select *
from public.tags
where t.label in ('sufficient_wifi', 'insufficient_wifi')
and t.deleted_at is null
and funding_year = 2017) t --adding sub query for public.tags table, per Justine

/*on dd.esh_id::text::int = t.taggable_id --esh id is not integer so doing conversion

and t.label in ('sufficient_wifi', 'insufficient_wifi')

and t.deleted_at is null
and funding_year = 2017

*/ --commenting out as already incorporated in the logic for public.tags



left join public.fy2017_schools_demog_matr sd

on eb_child.esh_id__c::varchar = sd.school_esh_id::varchar --esh id is not integer so doing conversion



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

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
usage of public.tags with funding year filter
no funding year column in public.entiy_bens tables
*/
 */
