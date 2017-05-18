with pc_eligible_fmt as (
		select distinct block_fips as census_block,
						true as pc_indicator
		from caf.pc_eligible_blocks
),
challenge_fmt as (
		select distinct fips as census_block,
						true as challenge_indicator
		from caf.challenge
),
rbe_eligible_fmt as (
		select distinct cb_fips as census_block,
						true as rbe_indicator
		from caf.rbe_eligible_blocks
),
cam43_eligible_fmt as (
		select distinct cb as census_block,
						true as cam43_indicator
		from caf.cam43_eligible_blocks
),
cam43_ex_high_cost_fmt as (
		select distinct census_block,
						true as cam43_ex_high_cost_indicator
		from caf.cam43_es_high_cost
),
ror_r1_eligible_fmt as (
		select distinct census_block,
						true as ror_r1_indicator
		from caf.ror_r1_eligible_blocks
),
pc_ph2_eligible_fmt as (
		select distinct census_block,
						true as pc_ph2_indicator
		from caf.pc_ph2_eligible_blocks
),
ror_r2_eligible_fmt as (
		select distinct census_block,
						true as ror_r2_indicator
		from caf.ror_r2_eligible_blocks
),
frontier_fmt as (
		select distinct census_block,
						true as frontier_indicator
		from caf.frontier_blocks
),
centurylink_fmt as (
		select distinct census_block,
						true as centurylink_indicator
		from caf.centurylink_blocks
),
acam232_fmt as (
		select distinct census_block,
						true as acam232_indicator
		from caf.acam232_blocks
),
frontier_r2_fmt as (
		select distinct census_block,
						true as frontier_r2_indicator
		from caf.frontier_r2_blocks
),
ny_auction_fmt as (
		select distinct census_block,
						true as ny_auction_indicator
		from caf.ny_auction_blocks
),
j1 as (
	select 	case
				when p1.census_block is null
					then ch.census_block
				else p1.census_block
			end as census_block,
			pc_indicator,
			challenge_indicator
	from pc_eligible_fmt p1
	full outer join challenge_fmt ch
	on p1.census_block = ch.census_block
),
j2 as (
	select case
				when rb.census_block is null
					then cm.census_block
				else rb.census_block
			end as census_block,
			rbe_indicator,
			cam43_indicator
	from rbe_eligible_fmt rb
	full outer join cam43_eligible_fmt cm
	on rb.census_block = cm.census_block
),
j3 as (
	select case
				when ex.census_block is null
					then r1.census_block
				else ex.census_block
			end as census_block,
			cam43_ex_high_cost_indicator,
			ror_r1_indicator
	from cam43_ex_high_cost_fmt ex
	full outer join ror_r1_eligible_fmt r1
	on ex.census_block = r1.census_block
),
j4 as (
	select case
				when p2.census_block is null
					then r2.census_block
				else p2.census_block
			end as census_block,
			pc_ph2_indicator,
			ror_r2_indicator
	from pc_ph2_eligible_fmt p2
	full outer join ror_r2_eligible_fmt r2
	on p2.census_block = r2.census_block
),
j5 as (
	select case
				when f1.census_block is null
					then cl.census_block
				else f1.census_block
			end as census_block,
			frontier_indicator,
			centurylink_indicator
	from frontier_fmt f1
	full outer join centurylink_fmt cl
	on f1.census_block = cl.census_block
),
j6 as (
	select case
				when ac.census_block is null
					then f2.census_block
				else ac.census_block
			end as census_block,
			acam232_indicator,
			frontier_r2_indicator
	from acam232_fmt ac
	full outer join frontier_r2_fmt f2
	on ac.census_block = f2.census_block
),
j7 as (
	select 	case
				when j1.census_block is null
					then j2.census_block
				else j1.census_block
			end as census_block,
			pc_indicator,
			challenge_indicator,
			rbe_indicator,
			cam43_indicator
	from j1
	full outer join j2
	on j1.census_block = j2.census_block
),
j8 as (
	select case
				when j3.census_block is null
					then j4.census_block
				else j3.census_block
			end as census_block,
			cam43_ex_high_cost_indicator,
			ror_r1_indicator,
			pc_ph2_indicator,
			ror_r2_indicator
	from j3
	full outer join  j4
	on j3.census_block = j4.census_block
),
j9 as (
	select case
				when j5.census_block is null
					then j6.census_block
				else j5.census_block
			end as census_block,
			frontier_indicator,
			centurylink_indicator,
			acam232_indicator,
			frontier_r2_indicator
	from  j5
	full outer join  j6
	on j5.census_block = j6.census_block
),
j10 as (
	select 	case
				when j7.census_block is null
					then j8.census_block
				else j7.census_block
			end as census_block,
			pc_indicator,
			challenge_indicator,
			rbe_indicator,
			cam43_indicator,
			cam43_ex_high_cost_indicator,
			ror_r1_indicator,
			pc_ph2_indicator,
			ror_r2_indicator
	from  j7
	full outer join  j8
	on j7.census_block = j8.census_block
),
j11 as (
	select case
				when j9.census_block is null
					then ny.census_block
				else j9.census_block
			end as census_block,
				frontier_indicator,
				centurylink_indicator,
				acam232_indicator,
				frontier_r2_indicator,
				ny_auction_indicator
	from  j9
	full outer join ny_auction_fmt ny
	on j9.census_block = ny.census_block
),
eligible_census_blocks as (
	select 	case
				when j10.census_block is null
					then j11.census_block
				else j10.census_block
			end as census_block,
			pc_indicator,
			challenge_indicator,
			rbe_indicator,
			cam43_indicator,
			cam43_ex_high_cost_indicator,
			ror_r1_indicator,
			pc_ph2_indicator,
			ror_r2_indicator,
			frontier_indicator,
			centurylink_indicator,
			acam232_indicator,
			frontier_r2_indicator,
			ny_auction_indicator
	from  j10
	full outer join  j11
	on j10.census_block = j11.census_block
)

select 	pc_indicator,
		challenge_indicator,
		rbe_indicator,
		cam43_indicator,
		cam43_ex_high_cost_indicator,
		ror_r1_indicator,
		pc_ph2_indicator,
		ror_r2_indicator,
		frontier_indicator,
		centurylink_indicator,
		acam232_indicator,
		frontier_r2_indicator,
		ny_auction_indicator,
		count(*) as num_census_blocks,
		count(*)/num_census_blocks as pct_census_blocks
from eligible_census_blocks
left join (
	select count(*) as num_census_blocks
	from eligible_census_blocks
) agg
on true
group by 1,2,3,4,5,6,7,8,9,10,11,12,13, agg.num_census_blocks
order by 1,2,3,4,5,6,7,8,9,10,11,12,13