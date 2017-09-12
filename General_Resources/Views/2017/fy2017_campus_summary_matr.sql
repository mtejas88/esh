with campus_level as (

  select d.esh_id,
  c.campus_id,
  c.campus_nonfiber_lines_w_dirty,
  case 
    when campus_nonfiber_lines_alloc = campus_nonfiber_lines_w_dirty
      then true
    else false
  end as all_non_fiber_allocated_correctly,
  case
    when campus_nonfiber_lines_alloc != campus_nonfiber_lines_w_dirty
      then True
    else False
  end as has_incorrect_alloc_nonfiber,
  case
    when campus_fiber_lines_alloc != campus_fiber_lines_w_dirty
      then True
    else False
  end as has_incorrect_alloc_fiber,
  
  case
    when campus_nonfiber_lines_alloc > 0
      then True
    else False
  end as has_correct_alloc_nonfiber,
  
  case
    when campus_fiber_lines_alloc > 0
      then True
    else False
  end as has_correct_alloc_fiber,
  
  case
    when campus_nonfiber_lines_w_dirty + campus_fiber_lines_w_dirty = 0
      then True
    else False
  end as no_lines_received
  
  from public.fy2017_districts_fiberpredeluxe_matr d
  
  join public.fy2017_campus_services_matr c
  on c.district_esh_id = d.esh_id
  
  where d.include_in_universe_of_districts = true

)

select s.district_esh_id,
s.campus_id,
d.exclude_from_wan_analysis,
d.fiber_target_status,
d.non_fiber_lines_w_dirty,
c.campus_nonfiber_lines_w_dirty,
has_incorrect_alloc_nonfiber,
has_incorrect_alloc_fiber,
has_correct_alloc_nonfiber,
has_correct_alloc_fiber,
no_lines_received,
case
  when has_incorrect_alloc_nonfiber = true
    then 'Incorrect Non-fiber'
  when has_correct_alloc_nonfiber = true
   and has_incorrect_alloc_fiber = true
    then 'Correct Non-fiber and Incorrect Fiber'
  when has_incorrect_alloc_fiber = true
    then 'Incorrect Fiber'
  when has_correct_alloc_fiber = true
    then 'Correct Fiber'
  when has_correct_alloc_nonfiber = true
    then 'Correct Non-fiber'
  when no_lines_received = true
    then 'No lines received'
end as category

from public.fy2017_schools_demog_matr s

left join campus_level c
on c.esh_id = s.district_esh_id
and c.campus_id = s.campus_id

left join public.fy2017_districts_fiberpredeluxe_matr d
on s.district_esh_id = d.esh_id

where d.include_in_universe_of_districts = true


/*
Author: Jeremy Holtzman
Created On Date: 9/8/2017
Name of QAing Analyst(s):
Purpose: aggregate the services each campus receives as an intermediate step to determine if the campus is fit for campus analysis
Methodology:
*/
