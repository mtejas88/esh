select distinct
	dl.esh_id,
	dl.district_esh_id,
	duf.fiber_target_specifically_identified,
	case
		when 	(num_fiber_470s > 0 or num_maybe_fiber_470s > 0) and
				(num_0_bids > 0 or num_1_bids > 0)
			then true
		else false
	end as unable_to_get_fiber,
	duf.fiber_470s,
	duf.maybe_fiber_470s,
	duf.zero_bids,
	duf.one_bid,
	ecb.blockcode,
	not(cafe.census_block is null) as census_block_eligible,
	not(caff.census_block is null) as census_block_funded

from public.fiber_targets_ability_to_get_fiber duf
left join fy2017_district_lookup_matr dl
on duf.esh_id = dl.district_esh_id
left join public.entities_to_census_blocks ecb
on dl.esh_id = ecb.esh_id
left join public.caf_eligible cafe
on ecb.blockcode::numeric = cafe.census_block
left join public.caf_eligible caff
on ecb.blockcode::numeric = caff.census_block