select 
  district_esh_id,
  postal_cd,
  name as district_name,
  array_to_string(
    array_agg(distinct  case
                          when census_block_eligible 
                            then dc.esh_id
                        end)
  , ';') as esh_ids_caf_eligible,
  array_to_string(
    array_agg(distinct  case
                          when census_block_funded 
                            then dc.esh_id
                        end)
  , ';') as esh_ids_caf_funded
from public.fy2017_districts_deluxe_matr dd
left join districts_caf dc
on dd.esh_id = dc.district_esh_id
where include_in_universe_of_districts
and district_type = 'Traditional'
and (census_block_eligible or census_block_funded)
and fiber_target_status = 'Target'
group by 1,2,3
order by 2