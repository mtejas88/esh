--c1 = ia_funding; WAN + Internet
--ia_total_funds = ia_funding, Internet 

with funding_lookup as (

  select  '2016 received' as year,
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
                                                    end) as ia_spend,
          sum(line_item_district_monthly_cost_total*case
                                                      when sr.months_of_service > 0
                                                        then sr.months_of_service
                                                      else 12
                                                    end*(discount_rate::numeric/100)) as ia_funding
  from public.fy2016_services_received_matr sr  
  left join fy2016.line_items li
  on sr.line_item_id = li.id
  left join fy2016.frns 
  on li.frn = frns.frn
  where sr.broadband
  and recipient_include_in_universe_of_districts
  and sr.inclusion_status != 'dqs_excluded'
  and sr.recipient_id in (
    select esh_id as recipient_id
    from public.fy2016_districts_deluxe_matr 
    where district_type = 'Traditional'
    and postal_cd != 'AK'
  )
  group by 2

)

select sum(case when purpose in ('WAN', 'Internet Access') then ia_funding end) as c1,
sum(case when purpose in ('Internet Access') then ia_funding end) as ia_total_funds

from funding_lookup