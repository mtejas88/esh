select 
c2.esh_id,
d17.postal_cd,
d17.district_size,
d17.locale,
d17.num_students,
d17.discount_rate_c2,
c2.c2_budget::numeric as pre_budget,
c2.c2_budget_postdiscount::numeric as post_budget,
c2.budget_remaining_c2_2015::numeric,
c2.budget_remaining_c2_2016::numeric,
c2.budget_remaining_c2_2017::numeric,
c2.budget_remaining_c2_2015_postdiscount::numeric,
c2.budget_remaining_c2_2016_postdiscount::numeric,
c2.budget_remaining_c2_2017_postdiscount::numeric,
d16.upgrade_indicator as upgraded_16,
d17.upgrade_indicator as upgraded_17,
d15.exclude_from_analysis exclude_from_analysis_15,
d16.exclude_from_ia_analysis as exclude_from_analysis_16,
d17.exclude_from_ia_analysis as exclude_from_analysis_17


from public.fy2017_districts_c2_funding_matr c2

join public.fy2017_districts_deluxe_matr d17
on c2.esh_id = d17.esh_id

join public.fy2016_districts_deluxe_matr d16
on d17.esh_id = d16.esh_id

join public.fy2015_districts_deluxe_m d15
on d16.esh_id = d15.esh_id::varchar


where d17.include_in_universe_of_districts
and d17.district_type = 'Traditional'
