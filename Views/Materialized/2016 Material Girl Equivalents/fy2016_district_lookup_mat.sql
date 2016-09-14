select esh_id, esh_id as district_esh_id
from fy2016_districts_demog_m
  union
select esh_id::varchar, district_esh_id::varchar
from fy2016.schools sd
join fy2016_districts_demog_m dd
on sd.district_esh_id::varchar = dd.esh_id--note: TEMPORARILY (materialized only) using the set of schools ENG is using in order to be aligned on services received

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  09/14/2016 
Name of QAing Analyst(s):  
Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id 
                              in order to aggregate services received by all these to the appropriate district (2016)
*/
