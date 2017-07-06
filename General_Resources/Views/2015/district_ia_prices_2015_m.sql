select  district_esh_id,
        postal_cd,
        bandwidth_in_mbps,
        internet_conditions_met,
        upstream_conditions_met,
        case
          when connect_type = 'Cable Modem'
            then 'Cable'
          when connect_category = 'Cable / DSL'
            then 'Copper'
          when connect_type = 'Dark Fiber Service'
            then 'Dark Fiber'
          else
            connect_category
        end as connect_category,
        total_cost::numeric/num_lines::numeric as cost_per_circuit

from public.lines_to_district_by_line_item_charter_bie_2015_m ldli
join public.line_items li
on ldli.line_item_id = li.id
where exclude = false
and (internet_conditions_met = true or upstream_conditions_met = true)
and not (internet_conditions_met = true and upstream_conditions_met = true)
and total_cost::numeric > 0


/*
Author:                     Justine Schott
Created On Date:            6/1/2016
Last Modified Date:         12/5/2016
Name of QAing Analyst(s):   Greg Kurzhals
Purpose:                    To feed into priority_status query only
Methodology:                service and cost information of clean services received for
determining if there is more bw available at a similar price
Note:                       original query located here:
https://modeanalytics.com/educationsuperhighway/reports/f3981b94a2ff
*/