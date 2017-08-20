with districts as (
select *
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and exclude_from_ia_analysis = false
and fiber_target_status in ('Target', 'Potential Target')
and postal_cd in ('MT', 'ID', 'MN', 'KS', 'IL', 'MD', 'MA', 'MO', 'NH', 
                  'AZ', 'VA', 'NC', 'TX', 'CA', 'NM', 'NY', 'OK', 'FL', 'ME')
),
total_unscalable_campuses as (
  select sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses) as unscalable_campuses
  from districts
)


select
  discount_rate_c1_matrix,
  sum(case
        when postal_cd in ('MT', 'MD', 'MA', 'MO', 'NH', 'TX')
          then current_assumed_unscalable_campuses + current_known_unscalable_campuses
        else 0
      end)/unscalable_campuses::numeric as pct_unscalable_campuses_with_state_match,
  sum(case
        when postal_cd not in ('MT', 'MD', 'MA', 'MO', 'NH', 'TX')
          then current_assumed_unscalable_campuses + current_known_unscalable_campuses
        else 0
      end)/unscalable_campuses::numeric as pct_unscalable_campuses_with_state_match_pending
    
from districts
join total_unscalable_campuses 
on true
group by 1, unscalable_campuses