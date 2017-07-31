with li_lookup as (

    select
      sd.campus_id,
      sd.district_esh_id,
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

    join fy2017_schools_demog_matr sd
    on eb.entity_id::varchar = sd.school_esh_id

    where
      li.funding_year = 2017
      and li.broadband = true

    group by
      sd.campus_id,
      sd.district_esh_id,
      a.line_item_id,
      li.num_lines

  )

  select
    campus_id,
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

Last Modified Date: 		      7/31/2017 - JS copied logic from fy2017_lines_to_district_by_line_item_matr

Name of QAing Analyst(s):

Purpose:                      To aggregate services received by all instructional facilities to the appropriate district. (2016)
*/
