with cost_lookup as (

select  dd.esh_id,
          case
            when 'special_construction' = any(open_flags)
              then 'Special construction'
            when sr.purpose = 'Not broadband'
              then 'Unknown'
            when sr.purpose in ('ISP', 'Upstream', 'Internet', 'Backbone')
              then 'Internet Access'
            else sr.purpose
          end as purpose,
          sum(line_item_district_monthly_cost_total*case
                                                      when sr.months_of_service > 0
                                                        then sr.months_of_service
                                                      else 12
                                                    end) as total_spend,
          sum(line_item_district_monthly_cost_total) as monthly_spend
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
  group by 1,2
  
)

select esh_id,
sum(case when purpose = 'Internet Access' then total_spend else 0 end) as total_internet_spend,
sum(case when purpose = 'WAN' then total_spend else 0 end) as total_wan_spend,
sum(case when purpose = 'Internet Access' then monthly_spend else 0 end) as monthly_internet_spend,
sum(case when purpose = 'WAN' then monthly_spend else 0 end) as monthly_wan_spend

from cost_lookup

group by 1