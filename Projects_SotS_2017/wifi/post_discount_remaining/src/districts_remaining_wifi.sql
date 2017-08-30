select esh_id,
case
  when c2_postdiscount_remaining_16 = 0
    then 0
  else 1 - c2_postdiscount_remaining_17 /c2_postdiscount_remaining_16
end as perc_spent_post,
case
  when c2_prediscount_remaining_16 = 0
    then 0
  else 1 - c2_prediscount_remaining_17 /c2_prediscount_remaining_16 
end as perc_spent_pre

from public.fy2017_districts_deluxe_matr

where include_in_universe_of_districts
and district_type = 'Traditional'

