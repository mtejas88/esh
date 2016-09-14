select esh_id, esh_id as district_esh_id
from fy2016_districts_demog_m
  union
select school_esh_id as esh_id, district_esh_id
from fy2016.schools
where max_grade_level != 'PK'
and charter = false --note: TEMPORARILY (materialized only) using the set of schools ENG is using in order to be aligned on services received

/*
Author:                       Justine Schott
Created On Date:              06/16/2016
Last Modified Date: 		  09/14/2016 
Name of QAing Analyst(s):  
Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id 
                              in order to aggregate services received by all these to the appropriate district (2016)
*/
