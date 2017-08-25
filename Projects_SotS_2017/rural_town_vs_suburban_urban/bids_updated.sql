select t.locale, 
sum(1) as num_districts,
sum(case when district_received_0_bids = 1 then 1 else 0 end) as num_received_0_bids,
median(num_bids_received_per_frn) as median_bids_received,
avg(num_bids_received_per_frn) avg_bids_received
from (
select dd.esh_id,
    case when locale in ('Rural','Town') then 'Rural/Town' else 'Suburban/Urban' end as locale,
    sum(frns.num_bids_received::numeric)/count(frns.frn)::numeric as num_bids_received_per_frn,
    sum(case
          when frns.num_bids_received::numeric = 0 or frns.num_bids_received is null
            then 1
          else 0
        end) as num_frns_with_0_bids,
    case
      when sum(frns.num_bids_received::numeric) = 0
        or sum(frns.num_bids_received::numeric) is null
        then 1
      else 0
    end as district_received_0_bids
    from fy2017.frns frns
    
    left join public.entity_bens eb
    on frns.ben = eb.ben
    
    left join public.fy2017_district_lookup_matr dl
    on dl.district_esh_id = eb.entity_id::varchar
    
    join public.fy2017_districts_deluxe_matr dd
    on dl.district_esh_id = dd.esh_id
    
    where 
    include_in_universe_of_districts
    and district_type = 'Traditional'
    and num_bids_received::numeric <= 1000
    
    group by 1,2)
  t
  group by 1