  select distinct
    frns_agg.frn,
    case
      when c.application_number is null
        then 0
      else 1
    end as consultant_indicator,
    frns_agg.special_construction_indicator,
    frns_agg.service_type,
    frns_agg.num_recipients,
    bi.application_number,
    bi.applicant_type,
    bi.certified_timestamp,
    bi.category_of_service,
    bi.urban_rural_status,
    bi.category_one_discount_rate,
    bi.fulltime_enrollment,
    bi.total_funding_year_commitment_amount_request,
    fr_agg.funded_frn,
    fr_agg.denied_frn,
    fr_agg.appealed_funded_frn,
    fr_agg.wave_number,
    fr_agg.fcdl_comment_for_frn,
    frns_agg.contract_expiry_date,
    frns_agg.frn_0_bids,
    frns_agg.frn_1_bid,
    frns_agg.state_master_contract,
    frns_agg.frn_from_previous_year,
    fr_py_agg.funded_frns as funded_frns_py,
    fr_py_agg.denied_frns as denied_frns_py,
    fr_py_agg.frns as frns_py,
    fli_agg.functions,
    fli_agg.purposes,
    fli_agg.line_items,
    fli_agg.total_monthly_eligible_recurring_costs,
    fli_agg.total_eligible_one_time_costs,
    total_pre_discount_charges::numeric *(category_one_discount_rate::numeric/100) as total_frn_funding
     
  from (
    select *
    from fy2016.basic_informations
  ) bi
  join (
  	select     
  		frns.frn,
      frns.application_number,
  		case
        when frns.fiber_sub_type = 'Special Construction'
          then 1
        else 0
      end as special_construction_indicator,
    	case
				when frns.service_type = 'Basic Maintenance of Internal Connections'
					then 'Basic Maintenance'
				else frns.service_type
			end as service_type,
	    frns.contract_expiry_date,
	    case
				when frns.num_bids_received::numeric = 0
					then 1
        else 0
			end as frn_0_bids,
      case
        when frns.num_bids_received::numeric = 1
          then 1
        else 0
      end as frn_1_bid,
	    case
				when frns.based_on_state_master_contract = 'Yes'
					then 1
        else 0
			end as state_master_contract,
	    case
				when frns.frn_number_from_the_previous_year is not null
					then 1
        else 1
			end as frn_from_previous_year,
      frns.total_pre_discount_charges,
	   	count(distinct ros.ben) as num_recipients

  from fy2016.frns
	left join fy2016.recipients_of_services ros
	on frns.frn = ros.frn
	group by 1,2,3,4,5,6,7,8,9,10
  ) frns_agg 
  on bi.application_number = frns_agg.application_number
  join (
  	select     
  		frn,
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
  	from fy2016.frn_line_items
  	group by 1
  ) fli_agg 
  on frns_agg.frn = fli_agg.frn
  left join fy2016.consultants c
  on bi.application_number = c.application_number
  left join (
    select 
    	frn,
	    case
        when fr.frn_status = 'Funded'
          then 1
        else 0
      end as funded_frn,
	    case
        when fr.frn_status = 'Denied'
          then 1
        else 0
      end as denied_frn,
      case
        when fr.appeal_wave_number != ''
        and fr.frn_status = 'Funded'
          then 1
        else 0
      end as appealed_funded_frn,
      fr.wave_number,
      fr.fcdl_comment_for_frn
    from funding_requests_2016_and_later fr
    where fr.funding_year = '2016'
  ) fr_agg
  on frns_agg.frn = fr_agg.frn
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
  ) fr_py_agg
  on bi.billed_entity_number = fr_py_agg.ben
