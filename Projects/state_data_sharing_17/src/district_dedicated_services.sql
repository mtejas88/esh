select d.esh_id,
upper(d.name) as district_name,
initcap(d.city) as city,
li.frn_complete,
d.discount_rate_c1*100 as erate_discount,
case  when sr.purpose = 'WAN' then 'District WAN'
      when sr.purpose = 'Upstream' then 'Transport to ISP'
      else sr.purpose end as purpose_of_service,
'' as purpose_of_service_corrected,
sr.connect_category as type_of_connection,
'' as type_of_connection_corrected,
sr.quantity_of_line_items_received_by_district as circuits_serving_districts_schools,
'' as circuits_serving_districts_schools,
sr.line_item_total_num_lines as total_circuits_in_line_item,
'' as total_circuits_in_line_item_corrected,
sr.bandwidth_in_mbps as downspeed_bandwidth_mbps_per_connection,
'' as downspeed_bandwidth_mbps_per_connection,
sr.line_item_total_cost as annual_cost,
'' as annual_cost_corrected,
sr.line_item_recurring_elig_cost as eligible_mrc,
'' as eligible_mrc_corrected,
upper(sr.applicant_name) as applied_for_by,
li.one_time_elig_cost as eligible_nrc,
'' as eligible_nrc_corrected,
li.reporting_name as service_provider_name,
'' as other_data_corrections,

case  when  'unknown_conn_type'=any(open_flag_labels) OR
            'product_bandwidth'=any(open_flag_labels) OR 
            'forced_bandwidth'=any(open_flag_labels) OR
            sr.connect_category ='Uncategorized'
      then 'Yes'
      else 'No'
      end as "suspected_incorrect_connection_technology",

case  when  'not_isp'=any(open_flag_labels) OR
            'not_upstream'=any(open_flag_labels) OR
            'not_bundled_ia'=any(open_flag_labels) OR
            'not_wan'=any(open_flag_labels)
            then 'Yes'
            else 'No'
            end as "suspected_incorrect_purpose",

case  when 'flipped_speed'=any(open_flag_labels) OR
            'product_bandwidth'=any(open_flag_labels) OR
            'forced_bandwidth'=any(open_flag_labels)
            then 'Yes'
            else 'No'
            end as "suspected_incorrect_bandwidth",

case  when 'unknown_quantity'=any(open_flag_labels)
            then 'Yes'
            else 'No'
            end as "suspected_incorrect_quantity",
            
case  when  'exclude_for_cost_only_unknown' = any(li.open_tag_labels) OR
            'exclude_for_cost_only_restricted' = any(li.open_tag_labels) OR
            'outlier_cost_per_circuit' = any(li.open_tag_labels)
            then 'Yes'
            else 'No'
            end as "suspected_incorrect_cost",
            
case  when  'dqt_veto'=any(open_flag_labels) OR
            'dqt_veto_wan'=any(open_flag_labels)
            then 'Yes'
            else 'No'
            end as "other_suspected_issue"



from public.fy2017_services_received_matr sr

left join public.fy2017_districts_deluxe_matr d
on d.esh_id = sr.recipient_id

left join public.fy2017_esh_line_items_v li
on sr.line_item_id = li.id



where sr.purpose in ('Internet','WAN','Upstream')
and d.exclude_from_ia_analysis = false
and sr.broadband = true
and sr.inclusion_status != 'dqs_excluded'
and d.include_in_universe_of_districts_all_charters