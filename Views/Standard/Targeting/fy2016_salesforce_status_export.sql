select 	ts.esh_id,
		ts.fiber_target_status as district_fiber_status,
		ts.bw_target_status as district_bw_status,
		slp.contract_expiring_2017,
		case
			when dd.exclude_from_wan_analysis
				then 'exclude from wan analysis'
			when dd.exclude_from_ia_analysis
				then 'exclude from ia analysis'
			when dd.exclude_from_wan_cost_analysis or dd.exclude_from_ia_cost_analysis
				then 'exclude from cost analysis'
			else 'include in all analysis'
		end as cleanliness,
		case
			when dd.exclude_from_wan_analysis
				then 'exclude from analysis'
			when wan_lines > 0
				then 'false'
			else 'true'
		end as no_wan_information,
		case
			when dd.exclude_from_wan_analysis
				then 'exclude from analysis'
			when non_fiber_lines > 0
				then 'true'
			else 'false'
		end as non_fiber_recipient,
		null as similar_priced_service_for_more_bw --stub so steven/meghan can begin work

from public.fy2016_fiber_bw_target_status ts
left join public.fy2016_state_landing_page slp
on ts.esh_id = slp.esh_id
left join public.fy2016_districts_deluxe dd
on ts.esh_id = dd.esh_id
