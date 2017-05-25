with dists as (
  select
    district_esh_id,
    count(distinct  case
                      when census_block_eligible
                        then blockcode
                    end) as eligible_census_blocks,
    count(distinct  case
                      when census_block_funded
                        then blockcode
                    end) as funded_census_blocks,
    count(*) as census_blocks
  from districts_caf
  group by 1
)

select
  funded_census_blocks > 0 as funded_census_blocks,
  eligible_census_blocks > 0 as eligible_census_blocks,
  median(census_blocks) as median_census_blocks,
  median(eligible_census_blocks/census_blocks::numeric) as median_pct_eligible_census_blocks,
  median(funded_census_blocks/census_blocks::numeric) as median_pct_funded_census_blocks,
  count(*)
from dists
group by 1, 2
