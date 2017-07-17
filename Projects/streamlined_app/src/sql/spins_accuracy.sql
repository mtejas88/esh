select  spin, 
        service_provider_name,
        count(distinct application_number) as applications_served,
        sum(case
              when frn_status = 'Funded'
                then 1
              else 0
            end)/count(*)::numeric as pct_funded 
from funding_requests_2016_and_later
where frn_status in ('Funded', 'Denied')
and funding_year = '2016'
group by 1, 2