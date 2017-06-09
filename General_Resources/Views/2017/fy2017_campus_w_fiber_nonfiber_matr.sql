select d.esh_id as district_esh_id,
case when (ds.campus_id = 'Unknown' or ds.campus_id is null) then ds.address else ds.campus_id end as campus_id,

--counting non fiber circuits to specific campus
count(distinct  case
                  when not(c.connect_category ilike '%Fiber%')
                    then ec.circuit_id end) as campus_nonfiber_lines_w_dirty,

--counting clean non fiber circuits to specific campus
count(distinct  case
                  when not(c.connect_category ilike '%Fiber%')
                  and c.num_open_flags = 0
                    then ec.circuit_id end) as campus_nonfiber_lines,

--counting correctly allocated non fiber circuits to specific campus
count(distinct  case
                  when not(c.connect_category ilike '%Fiber%')
                  and num_lines != 'Unknown'
                  and ( num_lines::numeric >= alloc.recipients or --num lines >= num recipients
                      num_lines::numeric >= alloc.alloc or --num lines >= sum of the allocations
                      num_lines::numeric >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
                    then ec.circuit_id
                end) as campus_nonfiber_lines_alloc_w_dirty,

--counting clean correctly allocated non fiber circuits to specific campus
count(distinct  case
                  when not(c.connect_category ilike '%Fiber%')
                  and num_lines != 'Unknown'
                  and c.num_open_flags = 0
                  and ( num_lines::numeric >= alloc.recipients or --num lines >= num recipients
                      num_lines::numeric >= alloc.alloc or --num lines >= sum of the allocations
                      num_lines::numeric >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
                    then ec.circuit_id
                end) as campus_nonfiber_lines_alloc,

--counting fiber circuits to specific campus
count(distinct  case when c.connect_category ilike '%Fiber%'
							      then ec.circuit_id end) as campus_fiber_lines_w_dirty,

--counting clean fiber circuits to specific campus
count(distinct  case when c.connect_category ilike '%Fiber%'
                     and c.num_open_flags = 0
							      then ec.circuit_id end) as campus_fiber_lines,

--counting number of correctly allocated fiber circuits to specific campus
count(distinct 	case
									when c.connect_category ilike '%Fiber%'
									and num_lines != 'Unknown'
									and ( num_lines::numeric >= alloc.recipients or --num lines >= num recipients
                      num_lines::numeric >= alloc.alloc or --num lines >= sum of the allocations
                      num_lines::numeric >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
										then ec.circuit_id
								end) as campus_fiber_lines_alloc_w_dirty,

--counting number of clean correctly allocated fiber circuits to specific campus
count(distinct 	case
									when c.connect_category ilike '%Fiber%'
									and num_lines != 'Unknown'
									and c.num_open_flags = 0
									and ( num_lines::numeric >= alloc.recipients or --num lines >= num recipients
                      num_lines::numeric >= alloc.alloc or --num lines >= sum of the allocations
                      num_lines::numeric >= alloc.num_campuses_and_others ) --num lines >= num campuses and other recips
										then ec.circuit_id
								end) as campus_fiber_lines_alloc

from public.fy2017_districts_predeluxe_matr d

left join public.fy2017_district_lookup_matr dl
on d.esh_id = dl.district_esh_id

left join public.entity_bens eb
on dl.esh_id = eb.entity_id::varchar

join public.fy2017_schools_demog_matr ds -- used join so wouldn't have district BENs
on dl.esh_id::varchar = ds.school_esh_id::varchar

left join public.esh_entity_ben_circuits  ec
on ec.ben = eb.ben

left join (
  select *
  from public.fy2017_esh_circuits_v c
  where c.isp_conditions_met = false
  and c.backbone_conditions_met = false
  and c.consortium_shared = false
  and not('canceled' = any(c.open_flag_labels) or
		     'video_conferencing' = any(c.open_flag_labels) or
		     'exclude' = any(c.open_flag_labels))
) c
on ec.circuit_id = c.id

left join public.fy2017_esh_line_items_v li
on c.line_item_id = li.id
and li.broadband = true

left join (
	select 	line_item_id,
		sum(a.num_lines_to_allocate) as alloc,
		count(distinct a.recipient_ben) as recipients,
		count(distinct c.campus_id) + sum(case when c.campus_id is null then 1
                                      else 0 end) as num_campuses_and_others
	from public.fy2017_esh_allocations_v a

	left join public.fy2017_esh_line_items_v li
  on a.line_item_id = li.id

  left join public.fy2017_schools_demog_matr c
  on a.recipient_id::varchar = c.school_esh_id::varchar

	where li.broadband = true
	group by line_item_id
) alloc
on c.line_item_id = alloc.line_item_id

where include_in_universe_of_districts_all_charters
and c.funding_year = 2017
and li.funding_year = 2017

group by 1,2

order by 1, 2

/*
Author: Jeremy Holtzman
Created On Date: 4/27/2017
Last Modified Date: 6/9/207
Modified by: Saaim Aslam
Modification: Adding funding year filter
Name of QAing Analyst(s):
Purpose: To make a campus table that captures what specific services are allocated to the campus
Methodology: Uses the fy2017_schools_demog_matr to identify all campuses in all districts, and then joins
the relevant line item and allocation tables to determine which services they receive. Good allocations
are defined by:
1. num lines >= num recips
2. num lines >= num campuses + other recips
3. num lines >= sum allocations
Dependencies: [public.fy2017_districts_predeluxe_matr, public.fy2017_district_lookup_matr, public.fy2017_schools_demog_matr, public.fy2017_schools_demog_matr, public.esh_entity_ben_circuits, public.fy2017_esh_circuits_v, public.fy2017_esh_allocations_v, public.fy2017_esh_line_items_v, ]
*/
