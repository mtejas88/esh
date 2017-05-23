select funded_census_blocks > 0 as funded_census_blocks, count(*)
from(
  select
    district_esh_id,
    count(distinct  case
                      when census_block_eligible or census_block_funded
                        then blockcode
                    end) as funded_census_blocks
  from fiber_targets_ability_to_get_fiber_caf
  group by 1
) dists
group by 1