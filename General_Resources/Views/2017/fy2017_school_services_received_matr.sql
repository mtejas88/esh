select base.*,
    CASE
      WHEN district_info_by_li.num_students_served > 0 and (consortium_shared=true OR purpose = 'Backbone')
            then (base.recipient_num_students/district_info_by_li.num_students_served)*base.line_item_recurring_elig_cost
      WHEN consortium_shared=true OR purpose = 'Backbone'
        then null
      WHEN base.line_item_total_num_lines = 'Unknown'
        THEN null
      when base.line_item_total_num_lines::numeric > 0
        THEN (base.quantity_of_line_items_received_by_district / base.line_item_total_num_lines::numeric) * base.line_item_recurring_elig_cost
      ELSE NULL
    END AS line_item_district_monthly_cost_recurring,
    CASE
      WHEN district_info_by_li.num_students_served > 0 and (consortium_shared=true OR purpose = 'Backbone')
            then (base.recipient_num_students/district_info_by_li.num_students_served)*base.line_item_mrc_unless_null
      WHEN consortium_shared=true OR purpose = 'Backbone'
        then null
      WHEN base.line_item_total_num_lines = 'Unknown'
        THEN null
      when base.line_item_total_num_lines::numeric > 0
        THEN (base.quantity_of_line_items_received_by_district / base.line_item_total_num_lines::numeric) * base.line_item_mrc_unless_null
      ELSE NULL
    END AS line_item_district_mrc_unless_null,
    CASE
      WHEN district_info_by_li.num_students_served > 0 and (consortium_shared=true OR purpose = 'Backbone')
            then (base.recipient_num_students/district_info_by_li.num_students_served)*base.line_item_total_monthly_cost
      WHEN consortium_shared=true OR purpose = 'Backbone'
        then null
      WHEN base.line_item_total_num_lines = 'Unknown'
        THEN null
      when base.line_item_total_num_lines::numeric > 0
        THEN (base.quantity_of_line_items_received_by_district / base.line_item_total_num_lines::numeric) * base.line_item_total_monthly_cost
      ELSE NULL
    END AS line_item_district_monthly_cost_total,
    CASE
      WHEN district_info_by_li.num_students_served > 0 and (consortium_shared=true OR purpose = 'Backbone')
            then (base.recipient_num_students/district_info_by_li.num_students_served)*base.line_item_one_time_cost
      WHEN consortium_shared=true OR purpose = 'Backbone'
        then null
      WHEN base.line_item_total_num_lines = 'Unknown'
        THEN null
      when base.line_item_total_num_lines::numeric > 0
        THEN (base.quantity_of_line_items_received_by_district / base.line_item_total_num_lines::numeric) * base.line_item_one_time_cost
      ELSE NULL
    END AS line_item_district_one_time_cost,
    case
      when line_item_total_num_lines = 'Unknown'
        then null
      when base.line_item_total_num_lines::numeric > 0
        then line_item_recurring_elig_cost/line_item_total_num_lines::numeric
      else NULL
    end as monthly_circuit_cost_recurring,
    case
      when line_item_total_num_lines = 'Unknown'
        then null
      when base.line_item_total_num_lines::numeric > 0
        then line_item_total_monthly_cost/line_item_total_num_lines::numeric
      else NULL
    end as monthly_circuit_cost_total

FROM (
          SELECT
            li.id AS line_item_id,
            CASE
              WHEN  'exclude' = any(li.open_flag_labels) or
                    'canceled' = any(li.open_flag_labels) or
                    'video_conferencing' = any(li.open_flag_labels)
                THEN 'dqs_excluded'
              WHEN ('exclude_for_cost_only_free' = any(li.open_tag_labels) 
                OR 'exclude_for_cost_only_restricted' = any(li.open_tag_labels) 
                OR 'exclude_for_cost_only_unknown' = any(li.open_tag_labels))
                and li.num_open_flags = 0
                THEN 'clean_no_cost'
              WHEN li.num_open_flags > 0
                THEN  'dirty'
              ELSE 'clean_with_cost'
            END AS inclusion_status,
            li.open_tag_labels AS open_tags,
            li.open_flag_labels AS open_flags,
            li.erate AS erate,
            li.consortium_shared AS consortium_shared,
            CASE
              WHEN li.isp_conditions_met
                THEN 'ISP'
              WHEN li.internet_conditions_met
                THEN 'Internet'
              WHEN li.wan_conditions_met
                THEN 'WAN'
              WHEN li.upstream_conditions_met
                THEN 'Upstream'
              WHEN li.backbone_conditions_met
                THEN 'Backbone'
              ELSE 'Not broadband'
            END AS purpose,
            li.broadband AS broadband,
            lis.allocation_lines AS quantity_of_line_items_received_by_district,
            li.num_lines AS line_item_total_num_lines,
            li.connect_category AS connect_category,
            CASE
              WHEN li.months_of_service > 0
                THEN li.total_cost / li.months_of_service
              ELSE li.total_cost / 12
            END AS line_item_total_monthly_cost,
            li.total_cost AS line_item_total_cost,
            li.rec_elig_cost AS line_item_recurring_elig_cost,
            CASE
              WHEN li.rec_elig_cost is null or li.rec_elig_cost = 0
                THEN  CASE
                        WHEN li.months_of_service > 0
                          THEN li.total_cost / li.months_of_service
                        ELSE li.total_cost / 12
                      END
              ELSE li.rec_elig_cost
            END AS line_item_mrc_unless_null,
            li.one_time_elig_cost AS line_item_one_time_cost,
            li.bandwidth_in_mbps AS bandwidth_in_mbps,
            li.months_of_service AS months_of_service,
            li.contract_end_date AS contract_end_date,
            case
              when spc.reporting_name is null
                then  li.service_provider_name
              else spc.reporting_name
            end AS reporting_name,
            li.service_provider_name AS service_provider_name,
            li.applicant_name AS applicant_name,
            eb.entity_id AS applicant_id,
            s.campus_id AS recipient_id,
            s.num_students as recipient_num_students,
            s.postal_cd as recipient_postal_cd

          FROM public.fy2017_lines_to_school_by_line_item_matr lis
          LEFT OUTER JOIN (select * from public.fy2017_esh_line_items_v
            where funding_year = 2017) li
          ON li.id = lis.line_item_id
          LEFT OUTER JOIN public.entity_bens eb
          ON eb.ben = li.applicant_ben
          LEFT OUTER JOIN (
            select distinct id, reporting_name
            from public.esh_service_providers
          ) spc
          ON spc.id = li.service_provider_id
          join public.fy2017_schools_demog_matr s
          on lis.campus_id = s.campus_id
) base
left join (
          select  lsli.line_item_id,
                  sum(s.num_students::numeric) as num_students_served

          from public.fy2017_lines_to_school_by_line_item_matr lsli

          left join public.fy2017_schools_demog_matr s
          on lsli.campus_id = s.campus_id

          left join public.fy2017_esh_line_items_v li
          on lsli.line_item_id = li.id

          where (li.consortium_shared=true
             OR li.backbone_conditions_met=true)
          and s.postal_cd in ('HI', 'DE', 'RI')

          group by lsli.line_item_id
) district_info_by_li
on base.line_item_id=district_info_by_li.line_item_id
where s.postal_cd in ('HI', 'DE', 'RI')




/*
Author:                   Justine Schott
Created On Date:
Last Modified Date:       8/11/2017 - JS copied from services_received
Name of QAing Analyst(s):
Purpose:                  2016 district data in terms of 2016 methodology
Methodology: Commenting out y2016.districts tables, based on our discussion with engineering team. Per Justine, this can be eliminated for our version 1 views currently and will need to be refactored after discussing the SFDC loop back feature with engineering and/or Districts team.
Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
might need to add below two additional attributes

Dependencies: [endpoint.fy2017_lines_to_school_by_line_item, fy2017.esh_line_items_v, public.entity_bens]
*/
