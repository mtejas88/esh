with li_lookup as (

  select 
    dl.district_esh_id,
    a.line_item_id,
    li.num_lines::numeric,
    sum(  case 
            when a.num_lines_to_allocate is null 
              then 0
            else a.num_lines_to_allocate
          end
        )::numeric as sum_lines_to_allocate
  
  
  from 
    public.esh_allocations a
  
  join public.esh_line_items li
  on a.line_item_id = li.id
  
  left join entity_bens eb
  on a.recipient_ben = eb.ben
  
  join fy2017_district_lookup_matr dl
  on eb.entity_id::varchar = dl.esh_id
  
  where 
    li.funding_year = 2017
    and li.broadband = true
  
  group by 
    dl.district_esh_id,
    a.line_item_id,
    li.num_lines
  
)

select 
  district_esh_id,
  line_item_id,
  case
    when num_lines > sum_lines_to_allocate
      then sum_lines_to_allocate
    else num_lines
  end as allocation_lines
  
from 
  li_lookup




/*

Author:                       Justine Schott

Created On Date:              06/16/2016

Last Modified Date: 		  6/13/2017 - JH updated methodology to use allocations to count lines received by district

Name of QAing Analyst(s):

Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using allocations table (instead of esh_entity_ben_circuits) to count lines
received by district
*/
