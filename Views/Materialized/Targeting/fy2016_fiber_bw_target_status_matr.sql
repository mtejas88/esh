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
			  bi.exclude_from_analysis_2016 as exclude_from_ia_analysis,
				si.exclude_from_wan_analysis,
				si.stage_indicator,
				ps.fiber_priority_status,
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
				end as bw_target_status

				from fy2016_stage_indicator_matr si
				left join (
					select esh_id__c as esh_id,
							case
								when priority_status__c_f is null
									then 'Priority 0'
								else priority_status__c_f
							end as fiber_priority_status
					from districts.priority_status) ps
				on si.esh_id = ps.esh_id::varchar
				left join fy2016_bw_indicator_matr bi
				on si.esh_id = bi.esh_id 														) target_status
