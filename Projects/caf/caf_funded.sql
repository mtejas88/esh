/*select *
from (*/
  select
    sum(final_funding) as caf_p1_funds,
    sum(esh_calculated_annual_a_cam_support)*10 as ror_funds,
    count(*) as num_blocks
  from caf.caf_p1_funds
  full outer join (
    select ror_funded_blocks.*, annual_a_cam_support::numeric, authorization_date, holding_company,
    number_of_locations_in_eligible_cbs_obliged_to_offer_10_1_mbps, number_of_locations_in_eligible_cbs_obliged_to_offer_25_3_mbps,
    number_of_locations_in_eligible_cbs_obliged_to_offer_4_1_mbps, number_of_locations_remaining_on_reasonable_request_standard,
    rate_of_return_carrier, ror_r2_authorizations.state, total_ror_locations_in_cbs_receiving_model_based_funding,
    annual_a_cam_support::numeric * supported_locations_232 / total_ror_locations_in_cbs_receiving_model_based_funding
      as esh_calculated_annual_a_cam_support
    from caf.ror_funded_blocks
    left join caf.ror_r2_authorizations
    on trim(both ' ' from ror_funded_blocks.short_name) = trim(both ' ' from ror_r2_authorizations.rate_of_return_carrier)
    and ror_funded_blocks.state = ror_r2_authorizations.state
  ) esh_ror_funded_blocks_r2_authorizations
  on caf_p1_funds.fips = esh_ror_funded_blocks_r2_authorizations.census_block/*) j1
full outer join
on  case
      when j1.fips is null
        then j1.census_block
      else j1.fips
    end = .*/

/*
caf.ny_auction_blocks
caf.challenge
caf.acam232_blocks
caf.ror_authorizations
full outer join caf.frontier_blocks
full outer join caf.cam43_es_high_cost
full outer join caf.centurylink_blocks
full outer join caf.frontier_r2_blocks
full outer join caf.pc_eligible_blocks
full outer join caf.rbe_eligible_blocks
full outer join caf.cam43_eligible_blocks
caf.ror_r2_eligible_blocks
caf.ror_r1_eligible_blocks
full outer join caf.pc_ph2_eligible_blocks
full outer join caf.summary_authorizations
full outer join caf.ror_several_authorizations */