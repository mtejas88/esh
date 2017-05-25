select distinct
	dl.esh_id,
	dl.district_esh_id,
	ecb.blockcode,
	not(cafe.census_block is null) as census_block_eligible,
	not(caff.census_block is null) as census_block_funded

from public.fy2016_districts_deluxe_matr dd
left join fy2017_district_lookup_matr dl
on dd.esh_id = dl.district_esh_id
left join public.entities_to_census_blocks ecb
on dl.esh_id = ecb.esh_id
left join public.caf_eligible cafe
on ecb.blockcode::numeric = cafe.census_block
left join public.caf_funded caff
on ecb.blockcode::numeric = caff.census_block
where dd.include_in_universe_of_districts_all_charters