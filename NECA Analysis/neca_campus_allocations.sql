with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
),

ad as (
  select district_esh_id, a.*
  from allocations a
  join district_lookup dl
  on dl.esh_id = a.recipient_id
),

district_recipients as (
select x.esh_id as "district_esh_id",
a.*
from allocations a
join districts x 
on x.esh_id=a.recipient_id
where x.num_campuses=1),

district_dedicated_1 as (
select district_esh_id,
line_item_id,
connect_type,
connect_category,
case when 'neca' = any(line_items.open_flags) and internet_conditions_met = true then 1 else 0 end as "received_neca_internet",
case when 'possible_neca' = any(line_items.open_flags) and internet_conditions_met = true then 1 else 0 end as "possibly_received_neca_internet",
case when 'neca' = any(line_items.open_flags) and upstream_conditions_met = true then 1 else 0 end as "received_neca_upstream",
case when 'possible_neca' = any(line_items.open_flags) and upstream_conditions_met = true then 1 else 0 end as "possibly_received_neca_upstream"
from district_recipients
left join line_items /* join neca flags */
on district_recipients.line_item_id=line_items.id
where (internet_conditions_met=true or upstream_conditions_met=true) 
and consortium_shared=false and num_recipients<=num_lines),

/*NECA upstream/internet flags for single-campus districts*/
district_dedicated_2 as (
select district_esh_id,
case when sum(received_neca_internet) > 0 then true else false end as district_received_neca_internet,
case when sum(possibly_received_neca_internet) > 0 then true else false end as district_possibly_received_neca_internet,
case when sum(received_neca_upstream) > 0 then true else false end as district_received_neca_upstream,
case when sum(possibly_received_neca_upstream) > 0 then true else false end as district_possibly_received_neca_upstream
from district_dedicated_1
GROUP BY district_esh_id),


sch_dist as (

        select schools.esh_id,
               district_esh_id,
               school_nces_cd,
               schools.name,
               schools.num_students,
               schools.address
               
        from schools
        left join districts
        on schools.district_esh_id = districts.esh_id
        where charter!=true
        and max_grade_level != 'PK'
        and include_in_universe_of_districts = true

),

sch_final as (
select sch_dist.*,
campus_id,
district_id

from sch_dist
left join districts_schools
on sch_dist.esh_id=districts_schools.school_id
),

school_to_campus as (
select campus_id,
district_id,
num_students,
a.*
from allocations a
join sch_final
on sch_final.esh_id=a.recipient_id),

campus_dedicated_1 as (
select line_item_id,
count(distinct campus_id) as "campuses_served",
count(distinct district_id) as "districts_served",
array_agg(distinct district_id) as "recipient_districts"
from school_to_campus
GROUP BY line_item_id),

campus_dedicated as (
select cd1.*,
w."num_lines_to_allocate"
from campus_dedicated_1 cd1
left join lateral (
select line_item_id,
sum(num_lines_to_allocate) as "num_lines_to_allocate"
from allocations
GROUP BY line_item_id) w
on cd1.line_item_id=w.line_item_id),

campus_dedicated_circuits as (
select 
campus_id,
school_to_campus.line_item_id,
/*NECA*/
case when z.dedicated_circuits=true and z.internet_conditions_met=true and z.neca = true
  and school_to_campus.num_lines_to_allocate>0 then true else false end as "dedicated_neca_internet",
case when z.dedicated_circuits=true and z.internet_conditions_met=true and z.possible_neca = true
  and school_to_campus.num_lines_to_allocate>0 then true else false end as "possible_dedicated_neca_internet",
case when z.dedicated_circuits=true and z.upstream_conditions_met=true and z.neca = true
  and school_to_campus.num_lines_to_allocate>0 then true else false end as "dedicated_neca_upstream",
case when z.dedicated_circuits=true and z.upstream_conditions_met=true and z.possible_neca = true
  and school_to_campus.num_lines_to_allocate>0 then true else false end as "possible_dedicated_neca_upstream",
case when z.dedicated_circuits=true and z.wan_conditions_met=true and z.neca = true
    and school_to_campus.num_lines_to_allocate>0 then true else false end as "dedicated_neca_wan",
case when z.dedicated_circuits=true and z.wan_conditions_met=true and z.possible_neca = true
    and school_to_campus.num_lines_to_allocate>0 then true else false end as "possible_dedicated_neca_wan",
case when z.dedicated_circuits=true and z.connect_category='Fiber'
    and school_to_campus.num_lines_to_allocate>0 then 'Fiber' 
when z.dedicated_circuits=true and z.connect_category='Fixed Wireless'
    and school_to_campus.num_lines_to_allocate>0 then 'Fixed Wireless' 
when z.dedicated_circuits=true and z.connect_type='Cable Modem'
    and school_to_campus.num_lines_to_allocate>0 then 'Cable' 
else 'No Fiber' end as "dedicated_fiber",
case when z.dedicated_circuits=true and school_to_campus.num_lines_to_allocate>0 then true else false end as "dedicated_service"
from school_to_campus

left join lateral (
select line_items.*,
/*NECA flags*/
case when 'neca' = any(line_items.open_flags) then true else false end as neca,
case when 'possible_neca' = any(line_items.open_flags) then true else false end as possible_neca,
cd.*,
case when cd.campuses_served=1 OR 
cd.campuses_served=line_items.num_lines OR 
line_items.num_recipients<=line_items.num_lines
OR line_items.num_lines=cd.num_lines_to_allocate OR 
(wan_conditions_met=true and cd.campuses_served<=line_items.num_lines)
then true else false end as "dedicated_circuits"
from line_items

left join campus_dedicated cd
on line_items.id=cd.line_item_id
left join districts 
on line_items.applicant_id=districts.esh_id) z
on school_to_campus.line_item_id = z.id
where z.broadband = true

--added the following exclusionary rules
and not('exclude'=any(z.open_flags))
and not('charter_service'=any(z.open_flags))
and not('videoconferencing'=any(z.open_flags))
and not('new_line_item'=any(z.open_flags))          
),

allocations_campus as (
select campus_id,
/* NECA */
case when 'true'=any(array_agg(dedicated_service::varchar)) then true else false end as "dedicated_service_recipient",
case when 'true'=any(array_agg(dedicated_neca_internet::varchar)) then true else false end as "dedicated_neca_internet_recipient",
case when 'true'=any(array_agg(possible_dedicated_neca_internet::varchar)) then true else false end as "possible_dedicated_neca_internet_recipient",
case when 'true'=any(array_agg(dedicated_neca_upstream::varchar)) then true else false end as "dedicated_neca_upstream_recipient",
case when 'true'=any(array_agg(possible_dedicated_neca_upstream::varchar)) then true else false end as "possible_dedicated_neca_upstream_recipient",
case when 'true'=any(array_agg(dedicated_neca_wan::varchar)) then true else false end as "dedicated_neca_wan_recipient",
case when 'true'=any(array_agg(possible_dedicated_neca_wan::varchar)) then true else false end as "possible_dedicated_neca_wan_recipient",
case when sum(case when cdc.dedicated_service=true then 1 else 0 end)>0 and 'Fiber'=any(array_agg(dedicated_fiber)) then 'Fiber'
when sum(case when cdc.dedicated_service=true then 1 else 0 end)>0 and 'Fixed Wireless'=any(array_agg(dedicated_fiber)) then 'Fixed Wireless'
when sum(case when cdc.dedicated_service=true then 1 else 0 end)>0 and 'Cable'=any(array_agg(dedicated_fiber)) then 'Cable'
when sum(case when cdc.dedicated_service=true then 1 else 0 end)=0 then 'Unknown' else 'Other' end as "dedicated_fiber_status"
from campus_dedicated_circuits cdc

GROUP BY campus_id),

distinct_campus as (
select array_agg(name) as "school_names",
array_agg(esh_id) as "school_ids",
count(esh_id) as "num_schools_campus",
max(district_esh_id) as "district",
sum(distinct case when sch_final.num_students = 'No data' then 0 else sch_final.num_students::bigint end) as "num_students_campus",
campus_id
from sch_final
GROUP BY campus_id),


known_and_assumed as (

select y.campus_id,
x.esh_id,
x.name as "district_name",
x.postal_cd,
x.exclude_from_analysis,
x.locale,
x.district_size,
y.school_names,
y.school_ids,
y.num_schools_campus,
x.num_schools as "num_schools_district",
x.num_campuses as "num_campuses_district",
y.num_students_campus,

/*NECA */

case when y.dedicated_neca_internet_recipient is not null then y.dedicated_neca_internet_recipient
when y.dedicated_service_recipient is null and w.district_received_neca_internet is not null then true
else false end as "dedicated_neca_internet_recipient",

case when y.possible_dedicated_neca_internet_recipient is not null then y.possible_dedicated_neca_internet_recipient
when y.dedicated_service_recipient is null and w.district_possibly_received_neca_internet is not null then true
else false end as "possible_dedicated_neca_internet_recipient",

case when y.dedicated_neca_upstream_recipient is not null then y.dedicated_neca_upstream_recipient
when y.dedicated_service_recipient is null and w.district_received_neca_upstream is not null then true
else false end as "dedicated_neca_upstream_recipient",

case when y.possible_dedicated_neca_upstream_recipient is not null then y.possible_dedicated_neca_upstream_recipient
when y.dedicated_service_recipient is null and w.district_possibly_received_neca_upstream is not null then true
else false end as "possible_dedicated_neca_upstream_recipient",

case when y.dedicated_neca_wan_recipient is not null then y.dedicated_neca_wan_recipient
else false end as "dedicated_neca_wan_recipient",

case when y.possible_dedicated_neca_wan_recipient is not null then y.possible_dedicated_neca_wan_recipient
else false end as "possible_dedicated_neca_wan_recipient"

from districts x

left join lateral (

select distinct_campus.*,
allocations_campus.dedicated_service_recipient,
allocations_campus.dedicated_neca_internet_recipient,
allocations_campus.possible_dedicated_neca_internet_recipient,
allocations_campus.dedicated_neca_upstream_recipient,
allocations_campus.possible_dedicated_neca_upstream_recipient,
allocations_campus.dedicated_neca_wan_recipient,
allocations_campus.possible_dedicated_neca_wan_recipient,
allocations_campus.dedicated_fiber_status

from distinct_campus

left join allocations_campus
on distinct_campus.campus_id=allocations_campus.campus_id) y
on x.esh_id=y.district

left join district_dedicated_2 w
on x.esh_id=w.district_esh_id

left join lateral (

select entity_id,
sum(case when status=0 and label='district_missing_wan' then 1 else 0 end) as "district_missing_wan" 
from entity_flags ef
GROUP BY entity_id) v
on x.esh_id=v.entity_id
where x.include_in_universe_of_districts=true)

select *

from known_and_assumed

where (postal_cd='{{state}}' OR 'All'='{{state}}')
and (exclude_from_analysis::varchar='{{exclude_from_analysis}}' OR 'All'= '{{exclude_from_analysis}}')

ORDER BY district_name


{% form %}

state:
  type: text
  default: 'All'
  
exclude_from_analysis:
  type: select
  default: 'All'
  options:
            [['All'],
            ['true'],
            ['false']
            ]

{% endform %}