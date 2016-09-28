select 	*,
		case
			when fiber_target_status in ('Target', 'Potential Target')
					and bw_target_status in ('Target', 'Potential Target')
				then 'Fiber & BW Target'
			when 	fiber_target_status in ('Target', 'Potential Target')
				then 'Fiber Target'
			when 	bw_target_status in ('Target', 'Potential Target')
				then 'BW Target'
			when 	fiber_target_status = 'Not Target'
					and bw_target_status = 'Not Target'
				then 'Not Target'
			else 'No Data'
		end aggregate_status


from( select 	si.esh_id,
				si.postal_cd,
				si.exclude_from_wan_analysis as exclude_from_analysis,
				si.stage_indicator,
				ps.fiber_priority_status,
				case
					when si.stage_indicator in ('Uncertain', 'No Data') and fiber_priority_status in ('Priority 1', 'Priority 3')
										then 'Target'
					when si.stage_indicator in ('Uncertain', 'No Data') and fiber_priority_status in ('Priority 10', 'Priority 0')
										then 'Not Target'
					when si.stage_indicator ='Uncertain'
										then 'Potential Target'
					when si.stage_indicator ='No Data'
										then 'No Data'
					else
										si.stage_indicator
				end as fiber_target_status_before_override,
				case --note: still need to add IRT Manual Override to this case-when statement, once its storage location is known
					when si.stage_indicator in ('Uncertain', 'No Data') and fiber_priority_status in ('Priority 1', 'Priority 3')
										then 'Target'
					when si.stage_indicator in ('Uncertain', 'No Data') and fiber_priority_status in ('Priority 10', 'Priority 0')
										then 'Not Target'
					when si.stage_indicator ='Uncertain'
										then 'Potential Target'
					when si.stage_indicator ='No Data'
										then 'No Data'
					else
										si.stage_indicator
				end as fiber_target_status,
				case
					when 	si.stage_indicator = 'No Data' 
							and (ia_bandwidth_per_student_kbps_2015 = 'Insufficient data' or ia_bandwidth_per_student_kbps_2015 is null)
							and bw_indicator = 'Potential Target' 
						then 'No Data'
					else bw_indicator
				end as bw_target_status_before_override,
				case
					when 	si.stage_indicator = 'No Data' --note: still need to add IRT Manual Override to this case-when statement, once its storage location is known
							and (ia_bandwidth_per_student_kbps_2015 = 'Insufficient data' or ia_bandwidth_per_student_kbps_2015 is null)
							and bw_indicator = 'Potential Target' 
						then 'No Data'
					else bw_indicator
				end as bw_target_status

				from public.fy2016_stage_indicator si
				left join (
					select esh_id, 
							case 
								when fiber_priority_status is null
									then 'Priority 0'
								else fiber_priority_status
							end as fiber_priority_status
					from endpoint.district_priority_status) ps
				on si.esh_id = ps.esh_id::varchar
				left join public.fy2016_bw_indicator bi
				on si.esh_id = bi.esh_id 														) target_status
