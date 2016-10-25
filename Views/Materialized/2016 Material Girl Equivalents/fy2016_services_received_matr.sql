select base.*,
    CASE
      WHEN district_info_by_li.num_students_served > 0 and consortium_shared=true OR purpose = 'Backbone'
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
      WHEN district_info_by_li.num_students_served > 0 and consortium_shared=true OR purpose = 'Backbone'
            then (base.recipient_num_students/district_info_by_li.num_students_served)*base.line_item_total_monthly_cost
      WHEN consortium_shared=true OR purpose = 'Backbone'
        then null
      WHEN base.line_item_total_num_lines = 'Unknown'
        THEN null
      when base.line_item_total_num_lines::numeric > 0
        THEN (base.quantity_of_line_items_received_by_district / base.line_item_total_num_lines::numeric) * base.line_item_total_monthly_cost
      ELSE NULL
    END AS line_item_district_monthly_cost_total,
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
              WHEN 'exclude_for_cost_only_free' = any(li.open_tag_labels) OR 'exclude_for_cost_only_restricted' = any(li.open_tag_labels) and li.num_open_flags = 0
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
            lid.allocation_lines AS quantity_of_line_items_received_by_district,
            li.num_lines AS line_item_total_num_lines,
            li.connect_category AS connect_category,
            CASE
              WHEN li.months_of_service = 0 OR li.months_of_service IS NULL
                THEN li.total_cost / 12
              ELSE li.total_cost / li.months_of_service
            END AS line_item_total_monthly_cost,
            li.total_cost AS line_item_total_cost,
            li.rec_elig_cost AS line_item_recurring_elig_cost,
            li.one_time_elig_cost AS line_item_one_time_cost,
            li.bandwidth_in_mbps AS bandwidth_in_mbps,
            li.months_of_service AS months_of_service,
            li.contract_end_date AS contract_end_date,
            spc.reporting_name AS reporting_name,
            li.service_provider_name AS service_provider_name,
            li.applicant_name AS applicant_name,
            li.applicant_id AS applicant_id,
            dd.esh_id AS recipient_id,
            dd.name AS recipient_name,
            dd.postal_cd AS recipient_postal_cd,
            dd.ia_monthly_cost_per_mbps AS recipient_ia_monthly_cost_per_mbps,
            dd.ia_bw_mbps_total AS recipient_ia_bw_mbps_total,
            dd.ia_bandwidth_per_student_kbps AS recipient_ia_bandwidth_per_student_kbps,
            dd.num_students AS recipient_num_students,
            dd.num_schools AS recipient_num_schools,
            dd.latitude AS recipient_latitude,
            dd.longitude AS recipient_longitude,
            dd.locale AS recipient_locale,
            dd.district_size AS recipient_district_size,
            dd.exclude_from_ia_analysis AS recipient_exclude_from_ia_analysis,
            dd.exclude_from_ia_cost_analysis AS recipient_exclude_from_ia_cost_analysis,
            dd.exclude_from_wan_analysis AS recipient_exclude_from_wan_analysis,
            dd.exclude_from_wan_cost_analysis AS recipient_exclude_from_wan_cost_analysis,
            dd.include_in_universe_of_districts as recipient_include_in_universe_of_districts,
            d.consortium_member AS recipient_consortium_member
          FROM public.fy2016_lines_to_district_by_line_item_matr lid
          LEFT OUTER JOIN fy2016.line_items li
          ON li.id = lid.line_item_id
          LEFT OUTER JOIN (
            select distinct name, reporting_name
            from fy2016.service_providers
          ) spc
          ON spc.name = li.service_provider_name
          LEFT OUTER JOIN public.fy2016_districts_deluxe_matr dd
          ON dd.esh_id = lid.district_esh_id
          LEFT OUTER JOIN fy2016.districts d
          ON dd.esh_id::numeric = d.esh_id
          WHERE li.broadband
) base
left join (
          select  ldli.line_item_id,
                  sum(d.num_students::numeric) as num_students_served

          from public.fy2016_lines_to_district_by_line_item_matr ldli

          left join public.fy2016_districts_demog_matr d
          on ldli.district_esh_id = d.esh_id

          left join fy2016.line_items li
          on ldli.line_item_id = li.id

          where (li.consortium_shared=true
             OR li.backbone_conditions_met=true)

          group by ldli.line_item_id
) district_info_by_li
on base.line_item_id=district_info_by_li.line_item_id

/*
Author:                   Justine Schott
Created On Date:
Last Modified Date:       10/20/2016
Name of QAing Analyst(s):
Purpose:                  2016 district data in terms of 2016 methodology
Methodology:
*/