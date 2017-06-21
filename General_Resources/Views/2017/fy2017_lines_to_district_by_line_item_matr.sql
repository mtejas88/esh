with li_lookup as (

    select
      dl.district_esh_id,
      a.line_item_id,
      --li.num_lines::numeric,
      li.num_lines as li_lookup_num_lines,
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
      when li_lookup_num_lines::numeric > sum_lines_to_allocate
        then sum_lines_to_allocate
      else li_lookup_num_lines
    end as allocation_lines
  
  from
    li_lookup
  where
    li_lookup_num_lines != -1 and
    (case 
      when li_lookup_num_lines::numeric > sum_lines_to_allocate
        then sum_lines_to_allocate
      else li_lookup_num_lines end) > 0
    





/*

Author:                       Justine Schott

Created On Date:              06/16/2016

Last Modified Date: 		  6/13/2017 - JH updated methodology to remove cases when num_lines = -1 or the sum_allocations = 0.
This is how the old circuits to EBC query worked.

Name of QAing Analyst(s):

Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using allocations table (instead of esh_entity_ben_circuits) to count lines
received by district
*/
