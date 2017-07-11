select
  funding_year::numeric,
  count(*) as c1_applications,
  sum(total_funding_year_commitment_amount_request::numeric) as c1_funding_requested,
  sum(case
        when total_funding_year_commitment_amount_request::numeric < 25000
          then 1
        else 0
      end) as lowcost_c1_applications,
  sum(case
        when total_funding_year_commitment_amount_request::numeric < 25000
          then total_funding_year_commitment_amount_request::numeric
        else 0
      end) as lowcost_c1_funding_requested
from fy2016.basic_informations
where category_of_service::numeric = 1
and window_status = 'In Window'
group by 1

UNION

select
  funding_year::numeric,
  count(*) as c1_applications,
  sum(total_funding_year_commitment_amount_request::numeric) as c1_funding_requested,
  sum(case
        when total_funding_year_commitment_amount_request::numeric < 25000
          then 1
        else 0
      end) as lowcost_c1_applications,
  sum(case
        when total_funding_year_commitment_amount_request::numeric < 25000
          then total_funding_year_commitment_amount_request::numeric
        else 0
      end) as lowcost_c1_funding_requested
from fy2017.basic_informations
where category_of_service::numeric = 1
and window_status = 'In Window'
group by 1
