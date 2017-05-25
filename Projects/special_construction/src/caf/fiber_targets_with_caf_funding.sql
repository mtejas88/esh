select
  fc.district_esh_id,
  dd.postal_cd,
  dd.name as district_name,
  specifically_idd_as_fiber_target,
  array_to_string(array_agg(distinct  case
                                        when fc.esh_id is null
                                          then fc.district_esh_id
                                        else fc.esh_id
                                      end), ';') as esh_ids_with_caf_funding,
  array_to_string(array_agg(distinct  case
                                        when sd.name is null
                                          then dd.name
                                        else sd.name
                                      end), ';') as entity_names_with_caf_funding

from public.fiber_targets_ability_to_get_fiber_caf fc
left join public.fy2016_schools_demog_matr sd
on fc.esh_id = sd.school_esh_id
left join public.fy2016_districts_demog_matr dd
on fc.district_esh_id = dd.esh_id
where census_block_funded

group by 1, 2, 3, 4