with consultants_to_districts as (

select distinct c.name as consultant_names,
c.consultant_registration_number as consultant_num,
d.esh_id,
d.num_schools,
d.num_students,
d.postal_cd

from public.fy2016_district_lookup_matr dl

left join public.entity_bens eb
on dl.esh_id::numeric = eb.entity_id

left join public.fy2016_districts_deluxe_matr d
on dl.district_esh_id = d.esh_id

join fy2016.consultants c
on eb.ben = c.applicant_ben

join fy2016.basic_informations b
on b.application_number = c.application_number
and b.category_of_service = '2'

join fy2016.line_items li
on c.application_number = li.application_number

where d.include_in_universe_of_districts

),

recipient_summaries as (

select consultant_names,
consultant_num,
count(distinct esh_id) as num_districts_served,
sum(num_schools) as num_schools_served,
sum(num_students) as num_students_served,
array_agg(distinct postal_cd) as states_served

from consultants_to_districts

group by 1, 2

)

select r.*, 
count(distinct c.application_number) as num_applications,
round(sum(li.total_cost)::numeric,2) as total_funding

from recipient_summaries r

left join fy2016.consultants c
on r.consultant_names = c.name
and r.consultant_num = c.consultant_registration_number

left join fy2016.basic_informations b
on b.application_number = c.application_number
and b.category_of_service = '2'

join fy2016.line_items li
on c.application_number = li.application_number

group by 1,2,3,4,5,6

order by 8 desc

--note, some applications have multiple consultants associated with the services, so they both get credit for serving the district and the full funding