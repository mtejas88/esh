--stopped customizing due to fact that 2015 had a different application and may not help us predict
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
    frns_agg.num_recipients,
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
    frns_agg.num_frns_from_previous_year,
    fr_14_agg.funded_frns as funded_frns_14,
    fr_14_agg.denied_frns as denied_frns_14,
    fr_14_agg.frns as frns_14,
    fli_agg.functions,
    fli_agg.purposes,
    fli_agg.line_items,
    fli_agg.total_monthly_eligible_recurring_costs,
    fli_agg.total_eligible_one_time_costs
     
  from (
    select *
    from fy2016.basic_informations
  ) bi
  join (
  	select     
  		frns."Application Number" as application_number,
  		0 as special_construction_indicator,
    	count(distinct frns."Service Type") as num_service_types,
    	array_to_string(array_agg(distinct 	case
                    												when frns."Service Type" ilike '%internal connections%'
                    													then 'Internal Connections'
                                            when frns."Service Type" ilike '%voice%'
                                              then 'Voice'
                                            when frns."Service Type" is null
                                              then null
                    												else 'Data Transmission and/or Internet Access'
                    											end),';') as service_types,
	    count(distinct frns."SPIN") as num_spins,
	    min(frns."CED") as min_contract_expiry_date,
	    max(frns."CED") as max_contract_expiry_date,
	    null as num_frns_0_bids,
	    null as num_frns_1_bids,
	    count(distinct 	case
	    					when frns."Mast Contr" = 'Y'
	    						then frns.frn
	    				end) as num_frns_state_master_contract,
	    null as num_frns_from_previous_year,
	   	count(distinct ros."BEN") as num_recipients

  from public.fy2015_funding_request_key_informations frns
	left join public.fy2015_item21_allocations_by_entities ros
	on frns."Application Number" = ros."Application Number"
	group by 1
  ) frns_agg 
  on bi.application_number = frns_agg.application_number
  join (
  	select     
  		"Application Number",
  		array_to_string(array_agg(distinct 	case
                    												when function ilike '%fiber%'
                    													then 'Fiber'
                    												when function ilike '%wireless%'
                    													then 'Wireless'
                    												when function ilike '%copper%'
                    													then 'Copper'
                    											end),';') as functions,
  		array_to_string(array_agg(distinct 	case
                    												when purpose ilike '%Internet access service with no circuit%'
                    													then 'ISP'
                    												when purpose ilike '%Internet access service that includes a connection%'
                    													then 'Internet'
                    												when purpose ilike '%where Internet access service is billed separately%'
                    													then 'Upstream'
                    												when purpose ilike '%Data Connection between two or more sites %'
                    													then 'WAN'
                    												when purpose ilike '%Backbone circuit%'
                    													then 'Backbone'
                    											end), ';') as purposes,
  		count(*) as line_items,
  		sum(total_monthly_eligible_recurring_costs::numeric) as total_monthly_eligible_recurring_costs,
  		sum(total_eligible_one_time_costs::numeric) as total_eligible_one_time_costs  		
  	from public.fy2015_item21_services_and_costs
  	group by 1
  ) fli_agg 
  on bi.application_number = fli_agg.application_number
  left join fy2016.consultants c
  on bi.application_number = c.application_number
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
  ) fr_agg
  on bi.billed_entity_number = fr_agg.ben
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
    where fr.funding_year = '2014'
    and not(fr.cmtd_category_of_service ilike '%internal connections%')
    group by 1
  ) fr_14_agg
  on bi.billed_entity_number = fr_14_agg.ben
