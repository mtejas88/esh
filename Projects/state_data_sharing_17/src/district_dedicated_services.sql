select d.esh_id,
upper(d.name) as district_name,
initcap(d.city) as city,
li.frn_complete,
d.discount_rate_c1_matrix*100 as erate_discount,
case  when sr.purpose = 'WAN' then 'District WAN'
      when sr.purpose = 'Upstream' then 'Transport to ISP'
      else sr.purpose end as purpose_of_service,
sr.connect_category as type_of_connection,
sr.quantity_of_line_items_received_by_district as circuits_serving_districts_schools,
sr.line_item_total_num_lines as total_circuits_in_line_item,
sr.bandwidth_in_mbps as downspeed_bandwidth_mbps_per_connection,
sr.line_item_total_cost as annual_cost,
sr.line_item_recurring_elig_cost as eligible_mrc,
upper(sr.applicant_name) as applied_for_by,
li.one_time_elig_cost as eligible_nrc,
li.reporting_name as service_provider_name



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