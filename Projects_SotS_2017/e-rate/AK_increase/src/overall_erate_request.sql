with frns_2017 as (
  select *
  from fy2017.frns 
  where service_type != 'Voice'
  and frn not in (
    select frn
    from fy2017.current_frns 
    where service_type != 'Voice'  
  )

  UNION

  select *
  from fy2017.current_frns 
  where service_type != 'Voice'
  and frn_status not in ('Denied', 'Cancelled')
)

select 
  sum(funding_commitment_request::numeric) as funding_commitment_request
from frns_2017