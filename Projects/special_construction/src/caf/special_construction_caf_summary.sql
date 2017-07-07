with apps as (
  select
    application_number,
    self_provisioning,
    count(distinct  case
                      when census_block_eligible
                        then blockcode
                    end) as eligible_census_blocks,
    count(distinct  case
                      when census_block_funded
                        then blockcode
                    end) as funded_census_blocks,
    count(*) as census_blocks
  from special_construction_caf
  group by 1, 2
)

select
  funded_census_blocks > 0 as funded_census_blocks,
  eligible_census_blocks > 0 as eligible_census_blocks,
  self_provisioning::varchar,
  median(census_blocks) as median_census_blocks,
  median(eligible_census_blocks/census_blocks::numeric) as median_pct_eligible_census_blocks,
  median(funded_census_blocks/census_blocks::numeric) as median_pct_funded_census_blocks,
  count(*)
from apps
where self_provisioning
group by 1, 2, 3

UNION

select
  funded_census_blocks > 0 as funded_census_blocks,
  eligible_census_blocks > 0 as eligible_census_blocks,
  'all' self_provisioning,
  median(census_blocks) as median_census_blocks,
  median(eligible_census_blocks/census_blocks::numeric) as median_pct_eligible_census_blocks,
  median(funded_census_blocks/census_blocks::numeric) as median_pct_funded_census_blocks,
  count(*)
from apps
group by 1, 2
