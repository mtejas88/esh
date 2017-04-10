with special_construction_applications as (
  select  line_items.application_number,
          line_items.applicant_ben,
          line_items.applicant_name,
          billed_entity_address_1,
          billed_entity_city,
          billed_entity_state,
          billed_entity_zipcode,
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
  left join fy2016.basic_informations bi
  on line_items.application_number = bi.application_number
  where resolved_sc.flaggable_id is not null
  or 'special_construction_tag' = any(open_tag_labels)
  or 'special_construction' = any(open_flag_labels)
  group by 1,2,3,4,5,6,7
)

select cbi.*
from special_construction_applications sca
left join fy2016.current_basic_informations cbi
on sca.application_number = cbi.application_number