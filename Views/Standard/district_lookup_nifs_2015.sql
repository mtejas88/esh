select esh_id, esh_id as district_esh_id
from public.districts
  union
select esh_id, district_esh_id
from public.schools
  union
select esh_id, district_esh_id
from public.other_locations
where district_esh_id is not null

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date: 		  06/02/2016
Name of QAing Analyst(s):  
Purpose:                      To append a list of all facilities, including non-instructional and their associated district_esh_id 
                              in order to determine all possible line items received by a district for the purpose of aiding data cleaning
*/