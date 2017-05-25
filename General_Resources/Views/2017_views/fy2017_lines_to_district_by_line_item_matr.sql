select dl.district_esh_id,
         c.line_item_id,
         count(distinct circuit_id) as allocation_lines
from public.esh_entity_ben_circuits ec
join public.esh_circuits c
on ec.circuit_id = c.id
left join entity_bens eb
on ec.ben = eb.ben
join fy2017_district_lookup_matr dl
on eb.entity_id::varchar = dl.esh_id
where funding_year = 2017 --public.esh_circuits to be filtered by funding year
group by  district_esh_id,
          line_item_id




/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  08/26/2016
Name of QAing Analyst(s):
Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)
Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
usage of public.esh_entity_ben_circuits and
public.esh_circuits and filtering the funding year with 2017
*/
