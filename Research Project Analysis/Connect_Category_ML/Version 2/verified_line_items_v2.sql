with district_with_lunches AS (SELECT Sum("TOTFRL") AS free_and_reduced,
          ds.district_id,
          ben
   FROM   PUBLIC.sc121a s
          JOIN PUBLIC.entity_nces_codes nc
            ON nc.nces_code = Lpad(s."NCESSCH", 12, '0')
          JOIN PUBLIC.districts_schools ds
            ON nc.entity_id = ds.school_id
          JOIN PUBLIC.entity_bens eb
            ON eb.entity_id = ds.district_id
   GROUP  BY ds.district_id,
             ben
   ORDER  BY free_and_reduced DESC),
district_info
AS (SELECT esh_id,
          NAME,
          postal_cd,
          nces_cd,
          highest_connect_type,
          free_and_reduced,
          ben,
          Array_length(all_services_received_ids, 1) AS num_of_services
   FROM   PUBLIC.districts d
          LEFT JOIN district_with_lunches dl
                 ON d.esh_id = dl.district_id),

group_con_cat
AS (SELECT service_provider_name,
         connect_category,
         Sum(num_lines) AS lines,
         row_number () over (partition by service_provider_name order by sum(num_lines) DESC) as row
  FROM   PUBLIC.line_items
  WHERE  broadband = true
         AND erate = true
  GROUP  BY service_provider_name,
            connect_category
  ORDER  BY service_provider_name ASC),


providers_to_cat as (
  SELECT service_provider_name,
      connect_category AS providers_typical_category
 FROM   group_con_cat
 WHERE  row = 1),


providers_to_lines
AS (SELECT id AS line_item_id,
          providers_to_cat.*,
          ben,
          bandwidth_in_mbps,
          num_students,
          connect_category,
          total_cost,
          num_lines,
          frn_complete
   FROM   PUBLIC.line_items li
          LEFT JOIN providers_to_cat
                 ON providers_to_cat.service_provider_name =
                    li.service_provider_name
   WHERE  erate = true
          AND broadband = true),



version_order
AS (SELECT fy2015_item21_services_and_cost_id AS line_item_id,
          CASE
            WHEN contacted IS NULL
                  OR contacted = false THEN false
            WHEN contacted = true THEN true
          END                                AS contacted,
          version_id,
          Row_number()
            OVER (
              partition BY fy2015_item21_services_and_cost_id
              ORDER BY version_id DESC )     AS row_num
   FROM   line_item_notes
   WHERE  note NOT LIKE '%little magician%'
   and contacted = true
    or user_id is not null),
consultant_info
AS (SELECT "BEN",
          "Consult Co Name",
          "Consult Person Name"
   FROM   PUBLIC.fy2015_basic_information_and_certifications),
consult_cat
AS (SELECT li.ben,
          CASE
            WHEN "Consult Co Name" IS NULL THEN 'No Consultant'
            ELSE "Consult Co Name"
          END AS consultant_name,
          connect_category
   FROM   PUBLIC.line_items li
          LEFT JOIN consultant_info
                 ON consultant_info."BEN" = li.ben
   WHERE  broadband = true),
consult_cat_freq
AS (SELECT consultant_name,
          connect_category,
          Count(connect_category) AS connect_cat_frequency,
          ben
   FROM   consult_cat
   GROUP  BY consultant_name,
             connect_category,
             ben
   ORDER  BY consultant_name DESC,
             connect_cat_frequency DESC),
final_consult_mapping
AS (SELECT consultant_name,
          connect_category,
          connect_cat_frequency,
          ben,
          Row_number ()
            OVER (
              partition BY consultant_name
              ORDER BY connect_cat_frequency DESC) AS row
   FROM   consult_cat_freq),
consult_freq
AS (SELECT ben,
          connect_category AS most_freq_cat,
          consultant_name,
          connect_cat_frequency
   FROM   final_consult_mapping
   WHERE  row = 1),
entity_ben_to_consult_freq
AS (SELECT consultant_info.*,
          most_freq_cat,
          eb.*
   FROM   consultant_info
          LEFT JOIN consult_freq
                 ON consult_freq.consultant_name =
                    consultant_info."Consult Co Name"
          LEFT JOIN PUBLIC.entity_bens eb
                 ON eb.ben = "BEN"
   WHERE  "Consult Co Name" IS NOT NULL
          AND entity_type = 'District')
SELECT DISTINCT pl.line_item_id,
          esh_id                        AS district_esh_id,
          NAME                          AS district_name,
          di.ben,
          free_and_reduced,
          service_provider_name,
          providers_typical_category,
          case when eb_freq.most_freq_cat is null then 'No Consultant' else  eb_freq.most_freq_cat end
          AS consultants_typical_category,
          case when eb_freq."Consult Person Name" is null then 'No Consultant' else eb_freq."Consult Person Name" end AS consultant_name,
          postal_cd,
          highest_connect_type,
          num_of_services,
          bandwidth_in_mbps,
          case when bandwidth_in_mbps = 1.5
                  or bandwidth_in_mbps = 3.0
                  or bandwidth_in_mbps = 4.5
                  or bandwidth_in_mbps = 45
                  or bandwidth_in_mbps = 90
               then true
               else false
               end as copper_line,
          num_students,
          connect_category,
          CASE
            WHEN total_cost > 0
                 AND num_lines > 0 THEN total_cost / num_lines
            ELSE 0
          END                           AS cost_per_line,
          frn_complete
FROM   providers_to_lines pl
 JOIN district_info di
   ON pl.ben = di.ben
 JOIN version_order vo
   ON vo.line_item_id = pl.line_item_id
 LEFT JOIN entity_ben_to_consult_freq eb_freq
        ON eb_freq.ben = pl.ben
WHERE  row_num = 1
ORDER  BY line_item_id ASC
