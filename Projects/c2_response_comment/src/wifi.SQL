select d.esh_id,
d.name,
d.postal_cd,
d.locale,
d.district_size,
d.num_students,
d.discount_rate_c2,
d.c2_prediscount_budget_15,
c.c2_budget_postdiscount as c2_postdiscount_budget_15,
d.c2_prediscount_remaining_17,
d.c2_postdiscount_remaining_17,
d.needs_wifi

from public.fy2017_districts_deluxe_matr d

left join public.fy2017_districts_c2_funding_matr c
on d.esh_id = c.esh_id

where d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'