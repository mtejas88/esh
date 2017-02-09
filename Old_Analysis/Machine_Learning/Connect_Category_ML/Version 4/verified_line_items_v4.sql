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
    d.name as district_name,
    d.postal_cd,
    d.nces_cd,
    d.highest_connect_type,
    array_length(d.all_services_received_ids, 1) as num_of_services,
    free_and_reduced,
    num_students,
    all_services_received_ids
  from public.districts d
  left join districts_wealth dw
  on dw."LEAID" = d.nces_cd
  left join public.entity_bens eb
  on eb.entity_id = d.esh_id
),

ol as (
  select
    name as other_location_name,
    eb.ben,
    case
      when ol.district_esh_id is null
      then true
      else false
      end as other_location_no_district,
      true as other_location,
    di.num_students,
    array_length(di.all_services_received_ids, 1) as num_of_services,
    di.highest_connect_type,
    free_and_reduced
  from public.other_locations ol
  left join public.entity_bens eb
  on ol.esh_id = eb.entity_id
  left join district_info di
  on di.esh_id = ol.district_esh_id
),

school_info as (
  select
    eb.ben,
    di.num_students,
    array_length(di.all_services_received_ids, 1) as num_of_services,
    di.highest_connect_type,
    free_and_reduced
    from public.schools sc
    left join
    public.entity_bens eb
    on sc.esh_id = eb.entity_id
    left join district_info di
    on di.esh_id = sc.district_esh_id
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
              and sp_cat_freq.service_provider_name = li.service_provider_name
            ) as providers_typical_category,
            case when bandwidth_in_mbps = 1.5
              or bandwidth_in_mbps = 3.0
              or bandwidth_in_mbps = 4.5
              or bandwidth_in_mbps = 45
              or bandwidth_in_mbps = 90
            then true
            else false
            end as copper_line,
            case
              when li.postal_cd = 'TX' and ( li.service_provider_name LIKE '%Education Service Center%'
                or li.service_provider_name LIKE '%ESC%'
                or li.service_provider_name LIKE '%Region%')
              then true
              when li.postal_cd = 'CA' and (li.service_provider_name LIKE '%County%'
                or li.service_provider_name LIKE '%Superintendent%'
                or li.service_provider_name LIKE '%Office%'
                ) and ( li.service_provider_name NOT LIKE '%LA County Office of Education%')
              then true
              when li.service_provider_name = 'WiscNet'
              then true
              else false
              end as exception_not_fiber,
              case when purpose = 'Internet' and wan = 'N'
                then true
                else false
              end as likely_other_uncategorized,
              case when wan = 'Y' and purpose = 'Transport'
              then true
              else false
              end as likely_wan_fiber,
              case when wan = 'Y' and purpose = 'Transport' and num_lines > 3
              then true
              else false
              end as wan_fiber_3_lines,
              case when service_type = 'Wireless Service'
              then true
              else false
              end as wireless_service,
              case when service_type = 'IA Only (no circuit)'
              then true
              else false
              end as ia_circuit_only,
              isp_conditions_met,
              upstream_conditions_met
     from   public.line_items li
     where erate = true
     AND broadband = true
),

consult_info as (
  select
      "BEN" as ben,
      "Consult Person Name" as consultant_name,
      true as consultant_applied
    from  public.fy2015_basic_information_and_certifications bi
    join public.line_items li
    on li.ben = bi."BEN"
    where li.broadband = true
    and "Consult Person Name" is not null
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
    distinct on (linf.line_item_id) linf.line_item_id,
    linf.ben,
    linf.bandwidth_in_mbps,
    case
      when linf.num_students is not null
      then linf.num_students::numeric
      when scl.num_students is not null
      then scl.num_students::numeric
      when ol.num_students is not null
      then ol.num_students::numeric
      else 0
      end as num_students,
    linf.connect_category,
    linf.providers_typical_category,
    case when ci.consultant_applied is true
      then true
      else false
    end as consultant_app,
    case
    when ci.consultant_applied is true
     then linf.connect_category
    else 'N/A'
    end as consultants_cat,
    linf.total_cost,
    linf.num_lines,
    linf.frn_complete,
    linf.copper_line,
    linf.exception_not_fiber,
    linf.likely_other_uncategorized,
    linf.likely_wan_fiber,
    linf.wan_fiber_3_lines,
    linf.wireless_service,
    linf.ia_circuit_only,
    linf.isp_conditions_met,
    linf.upstream_conditions_met,
    linf.postal_cd,
    di.esh_id,
    di.district_name,
    case
      when ol.other_location is null
        then false
        else true
        end as other_location ,
    case
      when ol.other_location_no_district is null
      then false
      else ol.other_location_no_district
    end as other_location_no_district,
    di.ben,
    di.nces_cd,
    case
      when di.num_of_services is not null
      then di.num_of_services
      when scl.num_of_services is not null
      then scl.num_of_services
      when ol.num_of_services is not null
      then ol.num_of_services
      else 0
      end as num_of_services,
    case
      when di.highest_connect_type is not null
      then di.highest_connect_type
      when scl.highest_connect_type is not null
      then scl.highest_connect_type
      when ol.highest_connect_type is not null
      then ol.highest_connect_type
      else 'unknown'
    end as highest_connect_type,
    case
      when di.free_and_reduced is not null
      then di.free_and_reduced
      when ol.free_and_reduced is not null
      then ol.free_and_reduced
      when scl.free_and_reduced is not null
      then scl.free_and_reduced
      else 0
    end as free_and_reduced,
    entity_type,
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
  left join ol
  on ol.ben = linf.ben
  left join school_info as scl
  on scl.ben = linf.ben
  left join consult_info ci
  on ci.ben = linf.ben
  inner join public.entity_bens eb
  on linf.ben = eb.ben
  where li_ver.row_num = 1
