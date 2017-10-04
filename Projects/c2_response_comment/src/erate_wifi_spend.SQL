select
  round(sum(c.c2_budget_postdiscount) - sum(budget_remaining_c2_2015_postdiscount),0) as erate_wifi_spend_15,
  round(sum(c.budget_remaining_c2_2015_postdiscount) - sum(budget_remaining_c2_2016_postdiscount),0) as erate_wifi_spend_16,
  round(sum(c.budget_remaining_c2_2016_postdiscount) - sum(budget_remaining_c2_2017_postdiscount),0) as erate_wifi_spend_17

from public.fy2017_districts_c2_funding_matr c

join public.fy2017_districts_deluxe_matr d
on c.esh_id = d.esh_id
and d.district_type = 'Traditional'
and d.include_in_universe_of_districts = true