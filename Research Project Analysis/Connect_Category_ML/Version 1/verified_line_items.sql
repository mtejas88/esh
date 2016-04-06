with district_with_lunches as (
  select
    sum("TOTFRL") as free_and_reduced,
    ds.district_id,
    ben
  from public.sc121a s
  join public.entity_nces_codes nc
  on nc.nces_code = lpad(s."NCESSCH", 12, '0')
  join public.districts_schools ds
  on nc.entity_id = ds.school_id
  join public.entity_bens eb
  on eb.entity_id = ds.district_id
  group by ds.district_id, ben
  order by free_and_reduced DESC),

district_info as (
  select
    esh_id,
    name,
    postal_cd,
    nces_cd,
    highest_connect_type,
    free_and_reduced,
    ben,
    array_length(all_services_received_ids, 1) as num_of_services
  from public.districts d
  left join district_with_lunches dl
  on d.esh_id = dl.district_id
),

group_con_cat as (
  select
    service_provider_name,
    connect_category,
    sum(num_lines) as lines
  from public.line_items
  where broadband = true
  and erate = true
  group by service_provider_name, connect_category
  order by service_provider_name ASC),

group_con_cat_row as (
  select
    service_provider_name,
    connect_category,
    row_number() over ( partition by service_provider_name order by lines DESC ) as row
  from group_con_cat),

providers_to_cat as (
  select
    service_provider_name,
    connect_category as providers_typical_category
  from group_con_cat_row
  where row = 1),

providers_to_lines as (
  select
    id as line_item_id,
    providers_to_cat.*,
    ben,
    bandwidth_in_mbps,
    num_students,
    connect_category,
    total_cost,
    num_lines,
    frn_complete
  from public.line_items li
  left join providers_to_cat
  on providers_to_cat.service_provider_name = li.service_provider_name
  where erate = true
  and broadband = true),

version_order as (
                select
                  fy2015_item21_services_and_cost_id as line_item_id,
                  case when contacted is null or contacted = false then false
                       when contacted = true then true
                       end as contacted,
                  version_id,
                  row_number() over ( partition by fy2015_item21_services_and_cost_id order by version_id desc
                                    ) as row_num

                from line_item_notes
                where note not like '%little magician%'
)

select
  pl.line_item_id,
  esh_id as district_esh_id,
  name as district_name,
  di.ben,
  free_and_reduced,
  service_provider_name,
  providers_typical_category,
  postal_cd,
  highest_connect_type,
  num_of_services,
  bandwidth_in_mbps,
  num_students,
  connect_category,
  CASE when total_cost > 0 and num_lines > 0 then total_cost / num_lines
  else 0
  end as cost_per_line,
  frn_complete
from providers_to_lines pl
join district_info di
on pl.ben = di.ben
join version_order vo
on vo.line_item_id = pl.line_item_id
where contacted = true
order by line_item_id ASC
