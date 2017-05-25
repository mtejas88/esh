select
	tgt16_agg.esh_id,
	dd.name,
	dd.postal_cd,
	dd.district_type,
	dd.locale,
	dd.district_size,
	dd.num_students,
	case
		when tgt16_agg.fiber_metric_status in ('clean_target', 'dirty_target')
			then true
		else false
	end as specifically_idd_as_fiber_target,
	num_fiber_470s > 0 as fiber_470s,
	num_maybe_fiber_470s > 0 as maybe_fiber_470s,
	num_0_bids > 0 as zero_bids,
	num_1_bids > 0 as one_bid,
	array_to_string(fiber_470s_array, ';') as fiber_470s_array,
	array_to_string(maybe_fiber_470s_array, ';') as maybe_fiber_470s_array,
	array_to_string(c1_470s_array, ';') as c1_470s_array,
	array_to_string(zero_bids_frn_array, ';') as zero_bids_frn_array,
	array_to_string(one_bid_frn_array, ';') as one_bid_frn_array
from (
	select
		esh_id,
		fiber_metric_status,
		count(distinct 	case
							when "Service Category" ilike '%internet access%'
							and "Function" ilike '%fiber%'
								then "470 Number"
						end) as num_fiber_470s,
		count(distinct 	case
							when "Service Category" ilike '%internet access%'
							and ("Function" ilike '%transport%'
								or "Function" in ('Other', 'Self-provisioning'))
								then "470 Number"
						end) as num_maybe_fiber_470s,
		array_agg(distinct 	case
								when "Service Category" ilike '%internet access%'
								and "Function" ilike '%fiber%'
									then "470 Number"
							end) as fiber_470s_array,
		array_agg(distinct 	case
								when "Service Category" ilike '%internet access%'
								and ("Function" ilike '%transport%'
									or "Function" in ('Other', 'Self-provisioning'))
									then "470 Number"
							end) as maybe_fiber_470s_array,
		array_agg(distinct case
								when "Service Category" ilike '%internet access%'
									then "Function"
							end) as c1_470s_array,
		array_agg(distinct case
								when num_bids_received =0
									then frn
							end) as zero_bids_frn_array,
		array_agg(distinct case
								when num_bids_received =1
									then frn
							end) as one_bid_frn_array,
		sum(case
				when num_bids_received =0
					then 1
				else 0
			end) as num_0_bids,
		sum(case
				when num_bids_received =1
					then 1
				else 0
			end) as num_1_bids
	from(
		select
			dd16.esh_id,
			dd16.fiber_metric_status,
			eb.ben as applicant_ben,
			form470s."470 Number",
			form470s."Service Category",
			form470s."Function",
			frns.num_bids_received::numeric,
			frns.frn
		from public.fy2016_districts_deluxe_matr dd16
		left join (
			select *
			from public.fy2017_services_received_matr
			where broadband
		) sr17
		on dd16.esh_id = sr17.recipient_id
		left join entity_bens eb
		on sr17.applicant_id = eb.entity_id
		left join fy2017.form470s
		on eb.ben = form470s."BEN"
		left join public.fy2017_esh_line_items_v li17
		on sr17.line_item_id = li17.id
		left join fy2017.frns
		on li17.frn = frns.frn
		where current_known_unscalable_campuses + current_assumed_unscalable_campuses > 0
		and include_in_universe_of_districts_all_charters
	) tgt16_470_frns
	group by 1,2
) tgt16_agg
left join fy2016_districts_deluxe_matr dd
on tgt16_agg.esh_id = dd.esh_id