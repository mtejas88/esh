with lca as (
  select
    fr.application_number,
    bi.total_funding_year_commitment_amount_request::numeric,
      sum(case
          when frn_status = 'Denied'
            then 1
          else 0
        end) as frns_denied
  from funding_requests_2016_and_later fr
  join fy2017.basic_informations bi
  on fr.application_number = bi.application_number
  where category_of_service::numeric = 1
  and fr.funding_year != ''
  and fr.funding_year::numeric = 2017
  and window_status = 'In Window'
  and bi.total_funding_year_commitment_amount_request::numeric > 0
  group by 1, 2
)

select
  frns_denied > 0 as application_denied,
  count(*) as apps,
  sum(case
      when total_funding_year_commitment_amount_request < 25000
        then 1
      else 0
    end) as lowcost_apps,
  sum(total_funding_year_commitment_amount_request) as requested,
  sum(case
      when total_funding_year_commitment_amount_request < 25000
        then total_funding_year_commitment_amount_request
      else 0
    end) as lowcost_requested

from lca
group by 1