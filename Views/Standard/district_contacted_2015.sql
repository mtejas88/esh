with version_order as (
                select fy2015_item21_services_and_cost_id,
                      case when contacted is null or contacted = false then 'false' 
                        when contacted = true then 'true'
                      end as contacted,
                      version_id,
                      row_number() over (
                                        partition by fy2015_item21_services_and_cost_id 
                                        order by version_id desc
                                        ) as row_num
                
                from public.line_item_notes
                where note not like '%little magician%'
),
most_recent as (
                select av.line_item_id,
                      version_order.contacted,
                      av.district_esh_id,
                      case when 'assumed_ia' = any(open_flags)
                            or 'assumed_wan' = any(open_flags)
                            or 'assumed_fiber' = any(open_flags)
                      then true else false end as assumed_flags
                      
                from line_item_district_association_2015 av
                left join public.version_order
                on av.line_item_id = version_order.fy2015_item21_services_and_cost_id
                left join public.line_items
                on av.line_item_id = line_items.id
                
                where (row_num = 1 or row_num is null)
                and broadband = true

                ),
                
district_counts as (
                    select district_esh_id,
                          count(case when contacted = 'true' then 1 end) as true_count,
                          count(case when contacted = 'false' then 1 end) as false_count,
                          count(case when contacted is null and assumed_flags = true then 1 end) as null_assumed_count,
                          count(case when contacted is null and assumed_flags = false then 1 end) as null_untouched_count
                    
                    from most_recent
                    
                    group by district_esh_id
)

select district_esh_id,
    case when true_count >= 1 then 'verified'
      when true_count = 0 and false_count >= 1 then 'inferred'
      when true_count = 0 and false_count = 0 and null_assumed_count >= 1 then 'interpreted'
      when true_count = 0 and false_count = 0 and null_assumed_count = 0 and null_untouched_count >= 1 then 'assumed'
    end as clean_categorization,
    case when true_count >= 1 and false_count = 0 and null_assumed_count = 0 and null_untouched_count = 0
      then true else false end as totally_verified
      
from district_counts

/*
Author: Justine Schott
Created On Date: 2/9/2016
Last Modified Date: 06/13/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Determine whether district was contacted
Methodology: Determine most recent contacted status for a line item as specified by DQS. Then create cleanliness determination
as defined here: https://educationsuperhighway.atlassian.net/wiki/display/EDS/Dimensioning+Clean
*/