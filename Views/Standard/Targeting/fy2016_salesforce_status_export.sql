select 	ts.esh_id,
		ts.fiber_target_status as district_fiber_status,
		ts.bw_target_status as district_bw_status,
		case
			when contract_expiring::timestamp <= DATE to_timestamp('06/30/2017', 'MM/DD/YYYY')
				then true
			else false
		end as contract_expiring,
		contract_expiration_date,
		ia_bw_mbps_total as district_total_bw,
		num_students as district_num_students,
		null as dqt_fiber_override, --not created yet
		null as dqt_bw_override, --not created yet
		null as dqt_notes, --not created yet
		null as one_or_more_instance_of_better_bw_pricing_in_state,
		fiber_target_status_before_override as non_override_fiber_status,
		bw_target_status_before_override as non_override_bw_status




from public.fy2016_fiber_bw_target_status ts
left join (
	select *,
			case
				when 	dedicated_isp_contract_expiration <= bundled_internet_contract_expiration
						and dedicated_isp_contract_expiration <= upstream_contract_expiration
					then dedicated_isp_contract_expiration
				when 	bundled_internet_contract_expiration <= dedicated_isp_contract_expiration
						and bundled_internet_contract_expiration <= upstream_contract_expiration
					then bundled_internet_contract_expiration
				when 	upstream_contract_expiration <= dedicated_isp_contract_expiration
						and upstream_contract_expiration <= bundled_internet_contract_expiration
					then upstream_contract_expiration
			end as contract_expiration_date
	from public.fy2016_districts_deluxe_m 
) dd
on ts.esh_id = dd.esh_id
