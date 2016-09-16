select 	*,
		case
			when 	fiber_target_status in ('Target', 'Potential Target')
					and bw_target_status in ('Target', 'Potential Target')
				then 'Fiber & BW Target'
			when 	fiber_target_status in ('Target', 'Potential Target')
				then 'Fiber Target'
			when 	bw_target_status in ('Target', 'Potential Target')
				then 'BW Target'
			when 	fiber_target_status = 'Not Target'
					and bw_target_status = 'Not Target'
				then 'Not Target'
			else 'Error'
		end salesforce_status


from( select 	si.esh_id,
/*				si.stage_indicator,
				ps.fiber_priority_status,*/ --not needed at this time
				case --note: still need to add IRT Manual Override to this case-when statement, once its storage location is known
					when si.stage_indicator = 'Uncertain'
						then 	case
									when ps.fiber_priority_status is null
										then 'No Data'
									when fiber_priority_status in ('Priority 1', 'Priority 3')
										then 'Target'
									when fiber_priority_status in ('Priority 10', 'Priority 0')
										then 'Not Target'
									else
										'Potential Target'
								end
						else
							si.stage_indicator
				end as fiber_target_status,
				case
					when si.stage_indicator = 'No Data' and case --note: still need to add IRT Manual Override to this case-when statement, once its storage location is known
																when si.stage_indicator = 'Uncertain'
																	then 	case
																				when ps.fiber_priority_status is null
																					then 'No Data'
																				when fiber_priority_status in ('Priority 1', 'Priority 3')
																					then 'Target'
																				when fiber_priority_status in ('Priority 10', 'Priority 0')
																					then 'Not Target'
																				else
																					'Potential Target'
																			end
																	else
																		si.stage_indicator
															end = 'Potential Target' 
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
