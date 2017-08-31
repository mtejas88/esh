select round(sum(c2_postdiscount_remaining_16) - sum(c2_postdiscount_remaining_17),0) as erate_wifi_17
from public.fy2017_districts_deluxe_matr
where include_in_universe_of_districts = true
and district_type = 'Traditional'
