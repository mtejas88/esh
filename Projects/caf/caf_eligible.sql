select 	case
				when pc_chal_hic.census_block is null
					then ror_r1_eligible_blocks.census_block
				else pc_chal_hic.census_block
			end as census_block,
		pc_challenge_status,
		pc_high_cost_status,
			case
				when sum(case when ror_r1_eligible_blocks.census_block is not null then 1 else 0 end) > 0
					then true
				else false
			end as ror_r1_status
from(
	select 	case
				when pc_chal.census_block is null
					then cam43_es_high_cost.census_block
				else pc_chal.census_block
			end as census_block,
			pc_challenge_status,
			case
				when sum(case when cam43_es_high_cost.census_block is not null then 1 else 0 end) > 0
					then true
				else false
			end as pc_high_cost_status
	from(
		select case
				when pc_eligible_blocks.block_fips is null
					then challenge.fips
				else pc_eligible_blocks.block_fips
			end as census_block,
			case
				when sum(case when challenge.challenge is null or challenge.challenge = false then 1 else 0 end) > 0
					then 'no challenge'
				when sum(case when challenge.challenge = true and pc_eligible_blocks.block_fips is not null then 1 else 0 end) > 0
					then 'removal challenge'
				when sum(case when challenge.challenge = true then 1 else 0 end) > 0
					then 'addition challenge'
			end as pc_challenge_status
		from caf.pc_eligible_blocks
		full outer join caf.challenge
		on pc_eligible_blocks.block_fips = challenge.fips
		group by 1
	) pc_chal
	full outer join caf.cam43_es_high_cost
	on pc_chal.census_block = cam43_es_high_cost.census_block
	group by 1, 2
) pc_chal_hic
full outer join caf.ror_r1_eligible_blocks
on pc_chal_hic.census_block = ror_r1_eligible_blocks.census_block
group by 1,2, 3

/*full outer join caf.rbe_eligible_blocks
on pc_chal.census_block = rbe_eligible_blocks.cb_fips
full outer join caf.cam43_eligible_blocks
on pc_chal.census_block = cam43_eligible_blocks.cb*/
