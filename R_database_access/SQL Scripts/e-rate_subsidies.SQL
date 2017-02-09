
with all_line_items as (

select li.id,
li.total_cost,
dl.district_esh_id,
d.num_students,
case  when li.isp_conditions_met = true then 'ISP'
      when li.backbone_conditions_met = true then 'Backbone'
      when li.internet_conditions_met = true then 'Internet'
      when li.upstream_conditions_met = true then 'Upstream'
      when li.wan_conditions_met = true then 'WAN'
      else 'Voice' end as purpose

from fy2016.line_items li

left join fy2016.allocations a
on a.line_item_id = li.id

join public.fy2016_district_lookup_matr dl
on a.recipient_id = dl.esh_id::integer

left join public.fy2016_districts_deluxe_matr d
on dl.district_esh_id = d.esh_id

where service_category in ('1', '1.0')
and not('exclude' = any(open_flag_labels))
and not('canceled' = any(open_flag_labels))
and include_in_universe_of_districts
and d.num_students > 0
and a.num_lines_to_allocate > 0

group by 1,2,3,4

),

line_items_student_count_step_1 as (

select li.id,
d.esh_id,
d.num_students

from fy2016.line_items li

left join fy2016.allocations a
on a.line_item_id = li.id

join public.fy2016_district_lookup_matr dl
on a.recipient_id = dl.esh_id::integer

left join public.fy2016_districts_deluxe_matr d
on dl.district_esh_id = d.esh_id

where service_category in ('1', '1.0')
and not('exclude' = any(open_flag_labels))
and not('canceled' = any(open_flag_labels))
and include_in_universe_of_districts
and d.num_students > 0
and a.num_lines_to_allocate > 0

group by 1,2,3

),

line_items_student_count_final as (

select id,
sum(num_students) as total_students

from line_items_student_count_step_1

group by 1

),

all_line_items_cost as (

select l.id,
l.district_esh_id,
l.num_students,
s.total_students,
l.purpose,
(l.num_students / s.total_students) * l.total_cost as district_cost

from all_line_items l

left join line_items_student_count_final s
on l.id = s.id

)

select d.esh_id,
d.name,
d.locale,
d.district_size,
d.num_students,
sum(a.district_cost) as total_cost,
sum(case when a.purpose in ('ISP', 'Backbone', 'Upstream', 'Internet')
          then a.district_cost end) as internet_cost,
sum(case when a.purpose in ('WAN')
          then a.district_cost end) as wan_cost,
sum(case when a.purpose in ('Voice')
          then a.district_cost end) as voice_cost

from public.fy2016_districts_deluxe_matr d

left join all_line_items_cost a
on d.esh_id = a.district_esh_id

where d.include_in_universe_of_districts
and d.district_type = 'Traditional'
and d.num_students::numeric > 0

group by 1,2,3,4,5
