with lookup as (

select 
distinct
  d.esh_id,
  c.name


from public.fy2017_district_lookup_matr dl

left join public.entity_bens eb
on dl.esh_id::numeric = eb.entity_id

left join public.fy2017_districts_deluxe_matr d
on dl.district_esh_id = d.esh_id

join fy2017.consultants c
on eb.ben = c.ben

join fy2017.basic_informations b
on b.application_number = c.application_number
and b.category_of_service = '1.0'

join public.fy2017_esh_line_items_v li
on c.application_number = li.application_number

where d.include_in_universe_of_districts
and d.district_type = 'Traditional'

)

select esh_id,
array_to_string(array_agg(distinct name),';') as c1_consultants

from lookup

group by 1