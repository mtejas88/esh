select distinct on (esh_id) * from (
  
  select eb.entity_id::varchar as esh_id,
         eb2.entity_id::varchar as district_esh_id
  
  from fy2017.discount_calculations dc
  
  left join public.entity_bens eb
    on dc.child_entity_ben = eb.ben
  
  left join public.entity_bens eb2
    on dc.parent_entity_ben = eb2.ben
  
  
  union
  
  select distinct eb.entity_id::varchar as esh_id,
                  eb.entity_id::varchar as district_esh_id
  
  from fy2017.discount_calculations dc
  
  left join public.entity_bens eb
    on dc.parent_entity_ben = eb.ben
  
  union
  
  select  dl.esh_id,
          dl.district_esh_id
          
  from public.fy2017_district_lookup_matr dl) all_2017_ids

where not(esh_id is null and district_esh_id is null)

/*

Author:                       Jeremy Holtzman
Created On Date:              05/17/2017
Last Modified Date:
Name of QAing Analyst(s):
Purpose: To append a list of all facilities / NIFs and their associated district_esh_id
in order to aggregate services received by all these to the appropriate district (2017)

Methodology: Uses district_lookup for all instructional facilities. To add non_schools, uses
2017 discount_calculations (which is how fy2016.other_locations was created)

*/
