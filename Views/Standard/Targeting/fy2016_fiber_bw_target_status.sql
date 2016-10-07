select 	si.esh_id,
		si.postal_cd,
	  	bi.exclude_from_analysis_2016 as exclude_from_ia_analysis,
		si.exclude_from_wan_analysis,
		si.stage_indicator,
		ps.fiber_priority_status,
		--note: still need to add IRT Manual Override to this case-when statement, once its storage location is known
		si.stage_indicator fiber_target_status,
		bw_indicator as bw_target_status,
		null as aggregate_status

		from fy2016_stage_indicator si
		left join (
			select esh_id,
					case
						when fiber_priority_status is null
							then 'Priority 0'
						else fiber_priority_status
					end as fiber_priority_status
			from endpoint.district_priority_status) ps
		on si.esh_id = ps.esh_id::varchar
		left join fy2016_bw_indicator bi
		on si.esh_id = bi.esh_id