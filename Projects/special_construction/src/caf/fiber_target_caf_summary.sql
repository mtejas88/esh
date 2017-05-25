with dists as (
  select
    district_esh_id,
    unable_to_get_fiber,
    count(distinct  case
                      when census_block_eligible
                        then blockcode
                    end) as eligible_census_blocks,
    count(distinct  case
                      when census_block_funded
                        then blockcode
                    end) as funded_census_blocks,
    count(*) as census_blockss
  from fiber_targets_ability_to_get_fiber_caf
  group by 1, 2

)

select
  funded_census_blocks > 0 as funded_census_blocks,
  eligible_census_blocks > 0 as eligible_census_blocks,
  unable_to_get_fiber::varchar,
  median(census_blocks) as median_census_blocks,
  median(eligible_census_blocks/census_blocks::numeric) as median_pct_eligible_census_blocks,
  median(funded_census_blocks/census_blocks::numeric) as median_pct_funded_census_blocks,
  count(*)
from dists
where unable_to_get_fiber
group by 1, 2, 3

UNION

select
  funded_census_blocks > 0 as funded_census_blocks,
  eligible_census_blocks > 0 as eligible_census_blocks,
  'all' unable_to_get_fiber,
  median(census_blocks) as median_census_blocks,
  median(eligible_census_blocks/census_blocks::numeric) as median_pct_eligible_census_blocks,
  median(funded_census_blocks/census_blocks::numeric) as median_pct_funded_census_blocks,
  count(*)
from dists
group by 1, 2


