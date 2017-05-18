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
)

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