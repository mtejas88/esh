select esh_id, esh_id as district_esh_id
from fy2016_districts_demog
  union
select esh_id, district_esh_id
from fy2016_schools_demog

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  09/23/2016 
Name of QAing Analyst(s):  
Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id 
                              in order to aggregate services received by all these to the appropriate district (2016)
*/
