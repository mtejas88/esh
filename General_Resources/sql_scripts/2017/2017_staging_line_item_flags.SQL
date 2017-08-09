with a as (select *,
case
  when status = 'open' and (updated_at >= '2017-07-07' or created_at >= '2017-07-07')
  then 'flag opened by mass update'
  when status = 'resolved' and (updated_at >= '2017-07-07' or created_at >= '2017-07-07')
  then 'flag resolved by mass update'
  else null
end as status_update

from public.flags 

where flaggable_type = 'LineItem'
and funding_year = 2017)
select *
from a 
where status_update is not null
