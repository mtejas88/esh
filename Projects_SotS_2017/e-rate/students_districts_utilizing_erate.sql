select 
  sum(case
        when broadband_recipients.recipient_id is not null
          then num_students
        else 0
      end)/sum(num_students)::numeric as pct_students,
  sum(case
        when broadband_recipients.recipient_id is not null
          then 1
        else 0
      end)/sum(1)::numeric as pct_districts
from public.fy2017_districts_deluxe_matr dd
left join (
  select distinct recipient_id
  from public.fy2017_services_received_matr
  where inclusion_status != 'dqs_excluded'
  and erate
) broadband_recipients
on dd.esh_id = broadband_recipients.recipient_id
where include_in_universe_of_districts
and district_type = 'Traditional'