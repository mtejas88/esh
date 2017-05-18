with caf_p1_fmt as (
	select 	fips as census_block,
			sum(final_funding) as p1_funding_authorized,
			array_agg(distinct carrier) as p1_carriers
	from caf.caf_p1_funds
	group by 1
),
ror_fmt as (
    select ror_funded_blocks.census_block,
    sum(annual_a_cam_support::numeric * supported_locations_232 / total_ror_locations_in_cbs_receiving_model_based_funding)
    	as ror_funding_authorized_assumed,
    array_agg(distinct holding_company) as ror_carriers
    from caf.ror_funded_blocks
    left join caf.ror_r2_authorizations
    on trim(both ' ' from ror_funded_blocks.short_name) = trim(both ' ' from ror_r2_authorizations.rate_of_return_carrier)
    and ror_funded_blocks.state = ror_r2_authorizations.state
    group by 1
),
cam43_eligible_fmt as (
	select distinct cb as census_block,
					short_name as cam_carrier,
					state,
					locations
	from caf.cam43_eligible_blocks
),
cam43_ex_high_cost_fmt as (
	select distinct cb as census_block,
					carrier as cam_carrier,
					carrier_offer_state as state,
					price_cap__extremely_high_cost_locations as locations
	from caf.cam43_es_high_cost
),/* need to check if there are any census blocks that are accepted by multiple state/carrier combos
cam43_fmt as(
	select elig.census_block,
	sum(support_amount_dollars * locations / homes_businesses_served) as cam43_funding_authorized_assumed,
	array_agg(distinct cam_carrier) as cam43_carriers
	from (
		select *
		from cam43_eligible_fmt
		UNION
		select *
		from cam43_ex_high_cost_fmt
	) elig
	join caf.caf_p2_commitments funded
	on elig.cam_carrier = funded.shortname
	and elig.cam_state = funded.state
	group by 1
), need to add funding amounts based on PDFs by state/carrier
rbe_fmt as (
	select census_block,
	sum(selected_bid_amount * / census_blocks) as rbe_funding_authorized_assumed,
	array_agg(distinct long_name) as rbe_carriers
	from caf.rbe_authorized ra
	left join caf.rbe_authorized_amounts raa
	on ra.da_no = raa.da_no
	and ra.long_name = raa.long_name
	and ra.bid_no = raa.bid_no
	and case
			when raa.state is not null
				then ra.state = raa.state
			else true
		end
	group by 1
),*/
j1 as (
	select 	case
				when p1.census_block is null
					then ro.census_block
				else p1.census_block
			end as census_block,
			p1_funding_authorized,
			ror_funding_authorized_assumed,
			p1_carriers,
			ror_carriers
	from caf_p1_fmt p1
	full outer join ror_fmt ro
	on p1.census_block = ro.census_block
)/*,
j2 as (
	select 	case
				when ca.census_block is null
					then rb.census_block
				else ca.census_block
			end as census_block,
			cam43_funding_authorized_assumed,
			rbe_funding_authorized_assumed,
			cam43_carriers,
			rbe_carriers
	from cam43_fmt ca
	full outer join rbe_fmt rb
	on p1.census_block = ro.census_block
),
j3 as (
	select 	case
				when j1.census_block is null
					then j2.census_block
				else j1.census_block
			end as census_block,
			p1_funding_authorized,
			ror_funding_authorized_assumed,
			cam43_funding_authorized_assumed,
			rbe_funding_authorized_assumed,
			p1_carriers,
			ror_carriers,
			cam43_carriers,
			rbe_carriers
	from j1
	full outer join j2
	on j1.census_block = j2.census_block
)*/

select
	case
		when p1_funding_authorized > 0 and ror_funding_authorized_assumed > 0
			then 'overlap'
		else 'no overlap'
	end as block_type,
	count(*) as census_blocks,
	sum(p1_funding_authorized) as p1_funding_authorized,
	sum(ror_funding_authorized_assumed) as ror_funding_authorized_assumed
from j1
group by 1