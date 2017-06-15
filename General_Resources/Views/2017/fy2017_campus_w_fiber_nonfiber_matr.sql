with li_lookup as (

  select 
    dl.district_esh_id,
    c.campus_id,
    a.line_item_id,
    li.num_lines::numeric,
    case 
      when f.num_open_flags is null
        then 0
      else f.num_open_flags
    end as num_open_flags,
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

  left join (
    select 
      flaggable_id,
      array_agg(label) as open_flag_labels,
      count(label) as num_open_flags
    
    from 
      public.flags f

    where f.status = 'open'
    and f.flaggable_type = 'LineItem'
    
    group by
      flaggable_id
  ) f
  on li.id = f.flaggable_id
  
  left join entity_bens eb
  on a.recipient_ben = eb.ben
  
  join fy2017_district_lookup_matr dl
  on eb.entity_id::varchar = dl.esh_id

  left join public.fy2017_schools_demog_matr c
  on eb.entity_id::varchar = c.school_esh_id
  
  where li.funding_year = 2017
    and li.broadband = true
    and li.isp_conditions_met = false
    and li.backbone_conditions_met = false
    and li.consortium_shared = false
    and li.num_lines != -1
    and (not('canceled' = any(f.open_flag_labels) or
             'video_conferencing' = any(f.open_flag_labels) or
             'exclude' = any(f.open_flag_labels)) 
        or f.open_flag_labels is null)
  
  group by 
    dl.district_esh_id,
    c.campus_id,
    a.line_item_id,
    li.num_lines,
    f.num_open_flags
  
),

temp as (

  select d.esh_id as district_esh_id,
  case when ds.campus_id = 'Unknown' then ds.address else ds.campus_id end as campus_id,
  li.id,

  --counting non fiber circuits to specific campus
  (case --need to adjust so do not use sum
    when not(li.connect_category ilike '%Fiber%')
      then ac.allocation_lines 
    else 0
  end) as campus_nonfiber_lines_w_dirty,

  --counting clean non fiber circuits to specific campus
  (case
    when not(li.connect_category ilike '%Fiber%')
    and ac.num_open_flags = 0
      then ac.allocation_lines 
    else 0
  end) as campus_nonfiber_lines,

  --counting correctly allocated non fiber circuits to specific campus
  (case
    when not(li.connect_category ilike '%Fiber%')
    and li.num_lines != -1
    and ( li.num_lines >= alloc.recipients or --num lines >= num recipients
        li.num_lines >= alloc.alloc or --num lines >= sum of the allocations
        li.num_lines >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
      then ac.allocation_lines
    else 0
  end) as campus_nonfiber_lines_alloc_w_dirty,

  --counting clean correctly allocated non fiber circuits to specific campus
  (case
    when not(li.connect_category ilike '%Fiber%')
    and li.num_lines != -1
    and ac.num_open_flags = 0
    and ( li.num_lines >= alloc.recipients or --num lines >= num recipients
        li.num_lines >= alloc.alloc or --num lines >= sum of the allocations
        li.num_lines >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
      then ac.allocation_lines
    else 0
  end) as campus_nonfiber_lines_alloc,

  --counting fiber circuits to specific campus
  (case 
    when li.connect_category ilike '%Fiber%'
  		then ac.allocation_lines 
    else 0
  end) as campus_fiber_lines_w_dirty,

  --counting clean fiber circuits to specific campus
  (case 
    when li.connect_category ilike '%Fiber%'
    and ac.num_open_flags = 0
  		then ac.allocation_lines 
    else 0
  end) as campus_fiber_lines,

  --counting number of correctly allocated fiber circuits to specific campus
  (case
  	when li.connect_category ilike '%Fiber%'
  	and li.num_lines != -1
  	and ( li.num_lines >= alloc.recipients or --num lines >= num recipients
        li.num_lines >= alloc.alloc or --num lines >= sum of the allocations
        li.num_lines >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
  		then ac.allocation_lines
    else 0
  end) as campus_fiber_lines_alloc_w_dirty,

  --counting number of clean correctly allocated fiber circuits to specific campus
  (case
  	when li.connect_category ilike '%Fiber%'
  	and li.num_lines != -1
  	and ac.num_open_flags = 0
  	and ( li.num_lines >= alloc.recipients or --num lines >= num recipients
        li.num_lines >= alloc.alloc or --num lines >= sum of the allocations
        li.num_lines >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
  		then ac.allocation_lines
    else 0
  end) as campus_fiber_lines_alloc

  from public.fy2017_districts_predeluxe_matr d

  left join public.fy2017_district_lookup_matr dl
  on d.esh_id = dl.district_esh_id

  left join public.entity_bens eb
  on dl.esh_id = eb.entity_id::varchar

  join public.fy2017_schools_demog_matr ds -- used join so wouldn't have district BENs
  on dl.esh_id::varchar = ds.school_esh_id::varchar


  left join (
    select 
      lil.district_esh_id,
      lil.campus_id,
      lil.line_item_id,
      lil.num_open_flags,
      case
        when lil.num_lines > lil.sum_lines_to_allocate
          then lil.sum_lines_to_allocate
        else lil.num_lines
      end as allocation_lines
    
    from 
      li_lookup lil
  ) ac
  on ds.campus_id = ac.campus_id

  left join public.esh_line_items li
  on ac.line_item_id = li.id
  and li.broadband = true
  and li.funding_year = 2017

  left join (
  	select 	line_item_id,
  		sum(a.num_lines_to_allocate) as alloc,
  		count(distinct a.recipient_ben) as recipients,
  		count(distinct c.campus_id) + sum(case when c.campus_id is null then 1
                                        else 0 end) as num_campuses_and_others
  	from public.esh_allocations a

  	join public.esh_line_items li
    on a.line_item_id = li.id
    and li.funding_year = 2017

    left join public.entity_bens eb
    on a.recipient_ben = eb.ben

    left join public.fy2017_schools_demog_matr c
    on eb.entity_id::varchar = c.school_esh_id

  	where li.broadband = true
  	group by line_item_id
  ) alloc
  on ac.line_item_id = alloc.line_item_id

  where d.include_in_universe_of_districts_all_charters
  and li.funding_year = 2017

  group by 1,2,3,4,5,6,7,8,9,10,11

  order by 1, 2

)

select 
  district_esh_id,
  campus_id,
  sum(campus_nonfiber_lines_w_dirty) as campus_nonfiber_lines_w_dirty,
  sum(campus_nonfiber_lines) as campus_nonfiber_lines,
  sum(campus_nonfiber_lines_alloc_w_dirty) as campus_nonfiber_lines_alloc_w_dirty,
  sum(campus_nonfiber_lines_alloc) as campus_nonfiber_lines_alloc,
  sum(campus_fiber_lines_w_dirty) as campus_fiber_lines_w_dirty,
  sum(campus_fiber_lines) as campus_fiber_lines,
  sum(campus_fiber_lines_alloc_w_dirty) as campus_fiber_lines_alloc_w_dirty,
  sum(campus_fiber_lines_alloc) as campus_fiber_lines_alloc

from
  temp

where campus_id is not null
and campus_id != ''

group by
  district_esh_id,
  campus_id

/*
Author: Jeremy Holtzman
Created On Date: 4/27/2017
Last Modified Date: 6/15/2017 - changed how to remove null campuses

Name of QAing Analyst(s):
Purpose: To make a campus table that captures what specific services are allocated to the campus
Methodology: Uses the fy2017_schools_demog_matr to identify all campuses in all districts, and then joins
the relevant line item and allocation tables to determine which services they receive. Good allocations
are defined by:
1. num lines >= num recips
2. num lines >= num campuses + other recips
3. num lines >= sum allocations
Dependencies: [public.fy2017_districts_predeluxe_matr, public.fy2017_district_lookup_matr, public.fy2017_schools_demog_matr]
*/
