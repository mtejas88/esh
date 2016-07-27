with version_order as (
                select fy2015_item21_services_and_cost_id,
                      case 
                        when contacted is null or contacted = false 
                          then 
                            case
                              when user_id is not null
                                then true
                              else 
                                false
                            end
                        when contacted = true 
                          then true
                      end as contacted_or_inferred,
                      version_id,
                      row_number() over (
                                        partition by fy2015_item21_services_and_cost_id 
                                        order by version_id desc
                                        ) as row_num
                
                from public.line_item_notes
                where note not like '%little magician%'
)

select  li.*, spc.reporting_name, recipient_schools, count_recipient_districts,
        case
          when 'backbone' = any(open_flags)
            then true
          else false
        end as backbone_conditions_met
from public.line_items li
join version_order
on li.id = version_order.fy2015_item21_services_and_cost_id
left join (
      select distinct name, reporting_name, category
      from public.service_provider_categories
) spc
on li.service_provider_name = spc.name
left join lateral (
  select  line_item_id,
          sum(DISTINCT case
                when num_schools = 'No data'
                  then 0
                else
                  num_schools::numeric
              end) as "recipient_schools",
          count(DISTINCT case
                when num_schools != 'No data'
                  then district_esh_id
              end) as "count_recipient_districts"          
  from lines_to_district_by_line_item_2015 ldli
  left join public.districts
  on ldli.district_esh_id = districts.esh_id
  GROUP BY line_item_id) x
on li.id=x.line_item_id

where (li.broadband=true
and li.erate=true
and li.consortium_shared=false
and not('video_conferencing'=any(li.open_flags))
and not('exclude'=any(li.open_flags))
and not('charter_service'=any(li.open_flags))
and not('committed_information_rate'=any(li.open_flags))
and not('ethernet_copper'=any(li.open_flags))
and app_type != 'LIBRARY'
and row_num = 1
and contacted_or_inferred = true
and exclude = false
and frn_line_item_no is not null
and frn is not null)
or 'backbone' = any(open_flags)