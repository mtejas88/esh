select ldli.*, 
       array_to_string(array_agg(distinct lif.label),';') as dirty_line_item_level_flags,
       case
        when number_of_dirty_line_item_flags = 0
          then 0
        else 1
        end as dirty_line_item_indic,
       array_to_string(array_agg(distinct ef.label),';') as dirty_entity_level_flags,
       count(distinct ef.label) as dirty_entity_level_flag_count,
       case
        when 'committed_information_rate'=any(li.open_flags)
              or 'ethernet_copper'=any(li.open_flags)
              or 'exclude_for_cost_only'=any(li.open_flags)
              or connect_type = 'Data Plan/Air Card Service'
              or li.id in (select fy2015_item21_services_and_cost_id
                            from public.line_item_flags
                            where label = 'new_line_item')
          then true
        else false end as excluded_from_machine_learning,
       wan_conditions_met,
       upstream_conditions_met,
       internet_conditions_met,
       isp_conditions_met
from lines_to_district_by_line_item_2015 ldli
join public.line_items li
on ldli.line_item_id = li.id 
--want all line items (direct to district)
left join (
  select *
  from public.line_item_flags
  where status = 0
  and dirty = true
) lif
on ldli.line_item_id = lif.fy2015_item21_services_and_cost_id
--only want dirty districts
join (
  select *
  from public.entity_flags
  where status = 0
  and dirty = true
) ef
on ldli.district_esh_id = ef.entity_id

where li.broadband = true
and (not('exclude' = any(open_flags)) or open_flags is null)
and (not('video_conferencing' = any(open_flags)) or open_flags is null)
and (not('charter_service' = any(open_flags)) or open_flags is null)
and (not('consortium_shared' = any(open_flags)) or open_flags is null)
and (not('consortium_shared_manual' = any(open_flags)) or open_flags is null)

group by 1,2,3, number_of_dirty_line_item_flags, li.open_flags, connect_type, li.id, 
wan_conditions_met, upstream_conditions_met, internet_conditions_met, isp_conditions_met
