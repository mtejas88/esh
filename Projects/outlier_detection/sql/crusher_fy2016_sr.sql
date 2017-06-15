select *
  from public.fy2016_services_received_matr

 /*select sr.*, district_type 
from public.fy2016_services_received_matr sr
left join public.fy2016_districts_deluxe_matr dd
on sr.recipient_id=dd.esh_id
where district_type='Traditional'*/
  