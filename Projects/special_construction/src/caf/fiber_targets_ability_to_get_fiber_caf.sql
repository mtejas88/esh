select distinct
	dl.esh_id,
	dl.district_esh_id,
	duf.specifically_idd_as_fiber_target,
	case
		when 	(fiber_470s or maybe_fiber_470s) and
				(zero_bids or one_bid)
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
left join public.caf_funded caff
on ecb.blockcode::numeric = caff.census_block