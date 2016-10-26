select 			si.esh_id,
				si.postal_cd,
			  	bi.exclude_from_analysis_2016 as exclude_from_ia_analysis,
				si.exclude_from_wan_analysis,
				ps.fiber_priority_status,
				si.stage_indicator as fiber_target_no_override,
				bi.bw_indicator as bw_target_no_override,
				-- Fiber Target DQT Manual Override tags accounted for here:
				case when 'fiber_not_target' = any(dd.tag_array) and si.stage_indicator != 'Not Target' then 'Not Target'
						 when 'fiber_target' = any(dd.tag_array) and si.stage_indicator != 'Target' then 'Target'
						 else si.stage_indicator
						 end as fiber_target_status,
				-- Bandwidth Target DQT Manual Override tags accounted for here:
				case when 'bw_not_target' = any(dd.tag_array) and bi.bw_indicator != 'Not Target' then 'Not Target'
						 when 'bw_target' = any(dd.tag_array) and bi.bw_indicator != 'Target' then 'Target'
						 else bi.bw_indicator
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
				on si.esh_id = bi.esh_id
				left join public.fy2016_districts_deluxe_matr dd
				on si.esh_id = dd.esh_id

/*
Author:                      Justine Schott
Created On Date:			 9/26/2016
Last Modified Date:          10/10/2016 - Lindsey Stevenson (simplified output and added DQT override)
Name of QAing Analyst(s):	 Jess Seok
Purpose:                     Aggregate targeting status
Methodology:

*/
