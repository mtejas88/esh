with li_lookup as (

    select
      dl.district_esh_id,
      a.line_item_id,
      --li.num_lines::numeric,
      li.num_lines as li_lookup_num_lines,
      sum(  case
              when a.num_lines_to_allocate is null
                then 0
              else a.num_lines_to_allocate
            end
          )::numeric as sum_lines_to_allocate


    from
      public.esh_allocations a

    join public.esh_line_items li
    on a.line_item_id = li.id

    left join entity_bens eb
    on a.recipient_ben = eb.ben

    join fy2017_district_lookup_matr dl
    on eb.entity_id::varchar = dl.esh_id

    where
      li.funding_year = 2017
      and li.broadband = true

    group by
      dl.district_esh_id,
      a.line_item_id,
      li.num_lines

  ),
  
adj_lines_to_district as (
  
select
    district_esh_id,
    line_item_id,
    case
      when li_lookup_num_lines::numeric > sum_lines_to_allocate
        then sum_lines_to_allocate
      else li_lookup_num_lines
    end as allocation_lines
  
  from
    li_lookup
  where
    li_lookup_num_lines != -1 

)

select d.esh_id,
upper(d.name) as district_name,
initcap(d.city) as city,
d.postal_cd as state,
li.frn_complete,
d.discount_rate_c1_matrix*100 as erate_discount,
case  when sr.purpose = 'WAN' then 'District WAN'
      when sr.purpose = 'Upstream' then 'Transport to ISP'
      else sr.purpose end as purpose_of_service,
sr.connect_category as type_of_connection,
sr.line_item_total_num_lines as total_circuits_in_line_item,
sr.bandwidth_in_mbps as downspeed_bandwidth_mbps_per_connection,
sr.line_item_total_cost as annual_cost,
sr.line_item_recurring_elig_cost as eligible_mrc,
upper(sr.applicant_name) as applied_for_by,
li.one_time_elig_cost as eligible_nrc,
sr.reporting_name as service_provider_name

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
              WHEN li.months_of_service > 0
                THEN li.total_cost / li.months_of_service
              ELSE li.total_cost / 12
            END AS line_item_total_monthly_cost,
            li.total_cost AS line_item_total_cost,
            li.rec_elig_cost AS line_item_recurring_elig_cost,
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
            case when
            d.consortium_affiliation is null
            then false
            else true
            end as recipient_consortium_member
          --  d.consortium_member AS recipient_consortium_member commenting out the fy2016 districts column, utilizng district deluxe for consortium member

          FROM adj_lines_to_district lid
          LEFT OUTER JOIN (select * from public.fy2017_esh_line_items_v
            where funding_year = 2017) li
          ON li.id = lid.line_item_id
          LEFT OUTER JOIN public.entity_bens eb
          ON eb.ben = li.applicant_ben
          LEFT OUTER JOIN (
            select distinct name, reporting_name
            from public.esh_service_providers
          ) spc
          ON spc.name = li.service_provider_name
          LEFT OUTER JOIN public.fy2017_districts_predeluxe_matr dd
          ON dd.esh_id = lid.district_esh_id
          left join public.fy2017_districts_aggregation_matr d
          on dd.esh_id = d.district_esh_id
    
) sr

left join public.fy2017_districts_deluxe_matr d
on d.esh_id = sr.recipient_id

left join public.fy2017_esh_line_items_v li
on sr.line_item_id = li.id

where sr.broadband = true
and sr.inclusion_status != 'dqs_excluded'
and (li.applicant_type = 'Consortium' or li.applicant_type = 'OtherLocation')
and d.include_in_universe_of_districts_all_charters = true

/*
Methodology: uses the logic from lines to district and services received, except I took out 
the part that says the recipient must have at least one line allocated to them (it would have been
on line 54)
*/