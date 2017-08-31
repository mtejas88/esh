select 
sum( case
        when postal_cd in ( 'AZ', 'CA', 'CO', 'FL', 'ID', 'MA', 'MD', 'ME', 'MO', 'MT', 'NC', 'NH', 'NM', 'NV', 'NY', 'OK', 'TX', 'VA')
        and discount_rate_c1_matrix >= .8
          then current_assumed_unscalable_campuses+current_known_unscalable_campuses
        else 0
      end)/sum(current_assumed_unscalable_campuses+current_known_unscalable_campuses)::numeric as pct_w_state_match_and_high_dr,
sum( case
        when postal_cd in ( 'AZ', 'CA', 'CO', 'FL', 'ID', 'MA', 'MD', 'ME', 'MO', 'MT', 'NC', 'NH', 'NM', 'NV', 'NY', 'OK', 'TX', 'VA')
        and discount_rate_c1_matrix >= .8
          then current_assumed_unscalable_campuses+current_known_unscalable_campuses
        else 0
      end)/sum( case
                  when postal_cd in ( 'AZ', 'CA', 'CO', 'FL', 'ID', 'MA', 'MD', 'ME', 'MO', 'MT', 'NC', 'NH', 'NM', 'NV', 'NY', 'OK', 'TX', 'VA')
                  and discount_rate_c1_matrix is not null
                    then current_assumed_unscalable_campuses+current_known_unscalable_campuses
                  else 0
                end)::numeric as pct_of_state_match_w_high_dr,
sum( case
        when postal_cd in ( 'AZ', 'CA', 'CO', 'FL', 'ID', 'MA', 'MD', 'ME', 'MO', 'MT', 'NC', 'NH', 'NM', 'NV', 'NY', 'OK', 'TX', 'VA')
          then current_assumed_unscalable_campuses+current_known_unscalable_campuses
        else 0
      end)/sum(current_assumed_unscalable_campuses+current_known_unscalable_campuses)::numeric as pct_state_match
from public.fy2017_districts_deluxe_matr 

--('IL', 'KS', 'MN')
where include_in_universe_of_districts
and district_type = 'Traditional'