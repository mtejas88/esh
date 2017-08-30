select 
c2.esh_id,
d.postal_cd,
d.district_size,
d.locale,
d.num_students,
d.discount_rate_c2,
c2.c2_budget::numeric as pre_budget,
c2.c2_budget_postdiscount::numeric as post_budget,
c2.budget_remaining_c2_2015::numeric,
c2.budget_remaining_c2_2016::numeric,
c2.budget_remaining_c2_2017::numeric,
c2.budget_remaining_c2_2015_postdiscount::numeric,
c2.budget_remaining_c2_2016_postdiscount::numeric,
c2.budget_remaining_c2_2017_postdiscount::numeric


from public.fy2017_districts_c2_funding_matr c2

join public.fy2017_districts_deluxe_matr d
on c2.esh_id = d.esh_id

where d.include_in_universe_of_districts
and d.district_type = 'Traditional'