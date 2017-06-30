  select 
    bi.application_number,
    bi.billed_entity_number,
    case
      when c.application_number is null
        then 0
      else 1
    end as consultant_indicator,
    bi.total_funding_year_commitment_amount_request::numeric,
    frns_agg.special_construction_indicator,
    frns_agg.num_service_types,
    frns_agg.service_types,
    frns_agg.num_spins,
    bi.applicant_type,
    bi.certified_timestamp,
    bi.category_of_service,
    bi.urban_rural_status,
    bi.category_one_discount_rate,
    bi.fulltime_enrollment,
    fr_agg.funded_frns,
    fr_agg.denied_frns,
    fr_agg.frns,
    fr_agg.avg_wave_number,
    frns_agg.min_contract_expiry_date,
    frns_agg.max_contract_expiry_date,
    frns_agg.num_frns_0_bids,
    frns_agg.num_frns_1_bids,
    frns_agg.num_frns_state_master_contract,
    frns_agg.num_frns_from_previous_year
     
  from (
    select *
    from fy2016.basic_informations
    where total_funding_year_commitment_amount_request::numeric > 0
    and window_status = 'In Window'
  ) bi
  join (
  	select     
  		frns.application_number,
  		count(distinct  case
	                      when frns.fiber_sub_type = 'Special Construction'
	                        then frns.application_number
	                    end) as special_construction_indicator,
    	count(distinct frns.service_type) as num_service_types,
    	array_to_string(array_agg(distinct 	case
												when frns.service_type = 'Basic Maintenance of Internal Connections'
													then 'Basic Maintenance'
												else frns.service_type
											end),';') as service_types,
	    count(distinct frns.service_provider_number) as num_spins,
	    min(frns.contract_expiry_date) as min_contract_expiry_date,
	    max(frns.contract_expiry_date) as max_contract_expiry_date,
	    count(distinct 	case
	    					when frns.num_bids_received::numeric = 0
	    						then frns.frn
	    				end) as num_frns_0_bids,
	    count(distinct 	case
	    					when frns.num_bids_received::numeric = 1
	    						then frns.frn
	    				end) as num_frns_1_bids,
	    count(distinct 	case
	    					when frns.based_on_state_master_contract = 'Yes'
	    						then frns.frn
	    				end) as num_frns_state_master_contract,
	    count(distinct 	case
	    					when frns.frn_number_from_the_previous_year is not null
	    						then frns.frn
	    				end) as num_frns_from_previous_year,
	   	count(distinct ros.ben) as num_recipients

  	from fy2016.frns
	left join fy2016.recipients_of_services ros
  	on frns.application_number = ros.application_number
  	group by 1
  ) frns_agg 
  on bi.application_number = frns_agg.application_number
  left join fy2016.consultants c
  on bi.application_number = c.application_number
  left join (
    select 
    	application_number,
	    sum(case
	          when fr.frn_status = 'Funded'
	            then 1
	          else 0
	        end) as funded_frns,
	    sum(case
	          when fr.frn_status = 'Denied'
	            then 1
	          else 0
	        end) as denied_frns,
	    count(*) as frns,
	    avg(case
	          when fr.wave_number is not null and fr.wave_number != ''
	            then fr.wave_number::numeric
	        end) as avg_wave_number
    from funding_requests_2016_and_later fr
    where fr.funding_year = '2016'
    group by 1
  ) fr_agg
  on bi.application_number = fr_agg.application_number
  left join (
    select 
    	ben,
	    sum(case
	          when fr.commitment_status = 'FUNDED'
	            then 1
	          else 0
	        end) as funded_frns,
	    sum(case
	          when fr.commitment_status = 'NOT FUNDED'
	            then 1
	          else 0
	        end) as denied_frns,
	    count(*) as frns
    from funding_requests fr
    where fr.funding_year = '2015'
    and not(fr.cmtd_category_of_service ilike '%internal connections%')
    group by 1
  ) fr_15_agg
  on bi.billed_entity_number = fr_15_agg.ben