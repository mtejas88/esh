select  line_items.application_number,
        line_items.applicant_ben,
        line_items.applicant_name,
        bi.billed_entity_address_1,
        bi.billed_entity_city,
        bi.billed_entity_state,
        bi.billed_entity_zipcode,
        line_items.frn,
        fr.frn_status,
        scfrns.fiber_sub_type as fiber_sub_type_original,
        scfrns_curr.fiber_sub_type as fiber_sub_type_current,
        sum(case
              when resolved_sc.flaggable_id is not null
                then 1
              else 0
            end) as resolved_sc_flag,
        sum(case
              when 'special_construction_tag' = any(open_tag_labels)
                then 1
              else 0
            end)  as open_sc_tag,
        sum(case
              when 'special_construction' = any(open_flag_labels)
                then 1
              else 0
            end)  as open_sc_flag

from fy2016.line_items
full outer join (
  select distinct flaggable_id
  from fy2016.flags
  where label = 'special_construction'
  and status = 'resolved'
) resolved_sc
on line_items.id = resolved_sc.flaggable_id
left join public.funding_requests_2016_and_later fr
on line_items.frn = fr.frn
left join fy2016.basic_informations bi
on line_items.application_number = bi.application_number
left join (
  select *
  from fy2016.current_frns
  where fiber_sub_type is not null
) scfrns_curr
on line_items.frn = scfrns_curr.frn
left join (
  select *
  from fy2016.frns
  where fiber_sub_type is not null
) scfrns
on line_items.frn = scfrns.frn
where resolved_sc.flaggable_id is not null
or 'special_construction_tag' = any(open_tag_labels)
or 'special_construction' = any(open_flag_labels)
group by 1,2,3,4,5,6,7,8,9,10,11
