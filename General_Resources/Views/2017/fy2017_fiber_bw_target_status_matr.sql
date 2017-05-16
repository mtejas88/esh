select 			si.esh_id,
				si.postal_cd,
			  	bi.exclude_from_analysis_2016 as exclude_from_ia_analysis,
				si.exclude_from_wan_analysis,
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

				from public.fy2017_stage_indicator_matr si
				
				left join public.fy2017_bw_indicator_matr bi
				on si.esh_id = bi.esh_id
				left join public.fy2017_districts_predeluxe_matr dd
				on si.esh_id = dd.esh_id

/*
Author:                      Jeremy Holtzman
Created On Date:			 4/27/2017
Last Modified Date:          
Name of QAing Analyst(s):	 
Purpose:                     Aggregate targeting status
Methodology:

*/
