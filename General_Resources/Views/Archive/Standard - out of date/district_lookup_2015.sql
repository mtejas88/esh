select esh_id, esh_id as district_esh_id
from public.districts
  union
select esh_id, district_esh_id
from public.schools

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date: 		  06/02/2016
Name of QAing Analyst(s):  
Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id 
                              in order to aggregate services received by all these to the appropriate district
*/