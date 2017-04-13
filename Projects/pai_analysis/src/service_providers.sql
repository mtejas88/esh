select    sr.reporting_name,
          dd.esh_id,
          dd.postal_cd,
          case
            when 'special_construction' = any(open_flags)
              then 'Special construction'
            when sr.purpose = 'Not broadband'
              then 'Unknown'
            when sr.purpose in ('ISP', 'Upstream', 'Internet', 'Backbone')
              then 'Internet Access'
            else sr.purpose
          end as purpose,
          sr.connect_category,
          sum(line_item_district_monthly_cost_total*case
                                                      when sr.months_of_service > 0
                                                        then sr.months_of_service
                                                      else 12
                                                    end) as total_spend,
          sum(line_item_district_monthly_cost_total) as monthly_spend,
          sum(case when dd.exclude_from_ia_analysis = false
                    then line_item_district_monthly_cost_total*case
                                                      when sr.months_of_service > 0
                                                        then sr.months_of_service
                                                      else 12
                                                    end
              else 0 end) as total_clean_spend,
          sum(case when dd.exclude_from_ia_analysis = false
                    then line_item_district_monthly_cost_total
              else 0 end) as monthly_clean_spend,
          sum(case when sr.purpose in ('Internet','Upstream')
                    then sr.bandwidth_in_mbps * sr.quantity_of_line_items_received_by_district
              else 0 end) as dedicated_bandwidth_mbps,
          sum(case when dd.exclude_from_ia_analysis = false and sr.purpose in ('Internet','Upstream')
                    then sr.bandwidth_in_mbps * sr.quantity_of_line_items_received_by_district
              else 0 end) as clean_dedicated_bandwidth_mbps
  from public.fy2016_services_received_matr sr  
  left join fy2016.line_items li
  on sr.line_item_id = li.id
  left join fy2016.frns 
  on li.frn = frns.frn
  left join public.fy2016_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  where sr.broadband
  and recipient_include_in_universe_of_districts
  and dd.district_type = 'Traditional'
  and not('special_construction' = any(open_flags))
  and sr.purpose != 'Not broadband'
  and dd.postal_cd != 'AK'
  and sr.inclusion_status != 'dqs_excluded'
  group by 1,2,3,4,5
