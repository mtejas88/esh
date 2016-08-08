select esh_id, esh_id as district_esh_id
from districts_demog_2016
  union
select school_esh_id as esh_id, district_esh_id
from schools_demog_2016

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		      
Name of QAing Analyst(s):  
Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id 
                              in order to aggregate services received by all these to the appropriate district (2016)
*/