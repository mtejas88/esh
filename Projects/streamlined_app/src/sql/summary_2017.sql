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
  where fr.funding_year != ''
  and fr.funding_year::numeric = 2017
  and window_status = 'In Window'
  and bi.total_funding_year_commitment_amount_request::numeric > 0
  group by 1, 2
)

select
  case
    when frns_denied > 0
      then 1
    else 0
  end as yhat,
  sum(total_funding_year_commitment_amount_request) as total_funding_year_commitment_amount_request,
  count(*) as application_number,
  2017 as year,
  'all actual' as model

from lca
group by 1, 4, 5