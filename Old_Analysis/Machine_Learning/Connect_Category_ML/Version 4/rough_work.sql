with districts_wealth as (
              select sum("TOTFRL") as free_and_reduced,
              "LEAID"
                from public.sc121a sc
              group by "LEAID"
),

district_info as (
  select
    d.esh_id,
    eb.ben,
    d.name,
    d.postal_cd,
    d.nces_cd,
    d.highest_connect_type,
    array_length(d.all_services_received_ids, 1) as num_of_services,
    free_and_reduced
  from public.districts d
  left join districts_wealth dw
  on dw."LEAID" = d.nces_cd
  left join public.entity_bens eb
  on eb.entity_id = d.esh_id
),

sp_cat_freq as (select service_provider_name,
         connect_category,
         Sum(num_lines) as lines,
         row_number () over (partition by service_provider_name order by sum(num_lines) DESC) as row
  from   public.line_items
  where  broadband = true
         AND erate = true
  GROUP  BY service_provider_name,
            connect_category),

line_item_info as (
  select id as line_item_id,
            ben,
            postal_cd,
            bandwidth_in_mbps,
            num_students,
            connect_category,
            total_cost,
            num_lines,
            frn_complete,
            (
              select
              connect_category as providers_typical_category
              from sp_cat_freq
              where row = 1
            ) as providers_typical_category,
            case when bandwidth_in_mbps = 1.5
              or bandwidth_in_mbps = 3.0
              or bandwidth_in_mbps = 4.5
              or bandwidth_in_mbps = 45
              or bandwidth_in_mbps = 90
            then true
            else false
            end as copper_line
     from   public.line_items li
     where erate = true
     AND broadband = true
),

consult_info as (
  select
      "BEN" as ben,
      "Consult Person Name" as consultant_name,
      li.connect_category
    from  public.fy2015_basic_information_and_certifications bi
    left join public.line_items li
    on li.ben = bi."BEN"
    where li.broadband = true
    group by "BEN", consultant_name, connect_category
  ),

li_ver as (
  select
    fy2015_item21_services_and_cost_id as line_item_id,
    Row_number()
      OVER (
        partition BY fy2015_item21_services_and_cost_id
        ORDER BY version_id DESC ) as row_num
  from line_item_notes
  where note NOT LIKE '%little magician%'
  and (
  contacted = true
  or
  user_id is not null ))

  select
    linf.line_item_id,
    linf.ben,
    linf.bandwidth_in_mbps,
    linf.num_students,
    linf.connect_category,
    linf.total_cost,
    linf.num_lines,
    linf.frn_complete,
    linf.providers_typical_category,
    linf.copper_line,
    linf.postal_cd,
    linf.copper_line,
    di.esh_id,
    di.name,
    di.ben,
    di.nces_cd,
    di.num_of_services,
    di.highest_connect_type,
    di.free_and_reduced,
    ci.consultants_category,
    case
      when linf.total_cost > 0 and num_lines > 0 then
        total_cost / num_lines
      else 0
    end as cost_per_line
  from line_item_info linf
  join li_ver
  using (line_item_id)
  left join district_info di
  on di.ben = linf.ben
  left join consult_info ci
  on ci.ben = linf.ben
  where li_ver.row_num = 1
  ORDER  BY line_item_id ASC
