select 
  d16.needs_wifi as needs_wifi_16,
  d17.needs_wifi as needs_wifi_17, 
  count(d17.esh_id)


from public.fy2017_districts_deluxe_matr d17

left join public.fy2016_districts_deluxe_matr d16
on d17.esh_id = d16.esh_id

where d17.include_in_universe_of_districts = true
and d17.district_type = 'Traditional'
and d17.c2_prediscount_remaining_15 - d17.c2_prediscount_remaining_17 > 0

group by 1,2