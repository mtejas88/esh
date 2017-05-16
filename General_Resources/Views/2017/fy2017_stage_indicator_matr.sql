select
	d.esh_id,
	d.lines_w_dirty,
	d.num_campuses,
	d.fiber_internet_upstream_lines,
	d.non_fiber_lines_w_dirty,
	d.fiber_internet_upstream_lines_w_dirty,
	d.exclude_from_wan_analysis,
	d.wan_lines_w_dirty,
	d.non_fiber_lines,
	d.fiber_wan_lines_w_dirty,
	d.include_in_universe_of_districts,
	d.district_type,
	d.postal_cd,
	case when d16.fiber_target_no_override = 'Not Target' then 'Not Target' --2016 not target pre-override
	when d.lines_w_dirty = 0 and d16.fiber_target_no_override = 'Target' then 'Target' --2016 target pre-override
	when d.lines_w_dirty = 0 then 'No Data' --1																	
	when d.num_campuses = 1 and d.fiber_internet_upstream_lines > 0 then 'Not Target' --4									-- 1-campus districts with a clean IA or upstream
	when d.non_fiber_lines_w_dirty > 0 then																					-- "Does the district receive non-fiber?"
			case when count(case when c.campus_nonfiber_lines_w_dirty > 0 then c.campus_id end) = 0 or
                (count(case when c.campus_nonfiber_lines_w_dirty > 0 then c.campus_id end) = count(c.campus_id)) then		-- "Is the non-fiber allocated to the district BEN or all campuses"
						case when count(case when c.campus_fiber_lines_alloc_w_dirty > 0 then c.campus_id end) = count(c.campus_id) then -- "Does every campus have correctly allocated fiber WAN/IA/Upstream"
							case when d.fiber_internet_upstream_lines_w_dirty > 0 then										-- "Does the district have fiber IA/upstream?"
								case  when d.exclude_from_wan_analysis = false then 'Not Target'	--21					-- "Is the district fit for WAN analysis"
								else 'Potential Target' end	--20												
							else
								case when d.exclude_from_wan_analysis = false then 'Target' --19							-- "Is the district fit for WAN analysis"
								else 'Potential Target'	end									--18						
							end																							
						else
							case when	d.exclude_from_wan_analysis = false and 
										d.wan_lines_w_dirty = 0 and
										d.num_campuses >= 6 and 
										d.fiber_internet_upstream_lines_w_dirty > 0 then 'Not Target'	--13				--"Is the district fit for WAN, and num_wan_lines = 0, and district has fiber IA/upstream?"
							     when 	d.non_fiber_lines = 0 then 'Potential Target' --14									--suggested addition for only dirty non-fiber
							     when 	d.fiber_internet_upstream_lines_w_dirty + d.fiber_wan_lines_w_dirty = 0 then 'Target' --15 --"Does the district have any fiber"
							     when 	d.fiber_internet_upstream_lines_w_dirty + d.fiber_wan_lines_w_dirty < d.num_campuses and
										d.exclude_from_wan_analysis = false then 'Target' --17								--"Is the sum of the fiber lines < num campuses and is the district fit for WAN?"
							else 'Potential Target' end --16 															
						end
			else
				case when count(case when c.campus_nonfiber_lines_w_dirty > 0 then c.campus_id end) = 
				          count(case when c.campus_nonfiber_lines_w_dirty > 0 and c.campus_fiber_lines_alloc_w_dirty > 0 then c.campus_id end) then --"Does every campus recipient of the non-fiber have correctly allocated fiber WAN/IA/upstream?"
					case when d.fiber_internet_upstream_lines_w_dirty > 0 then												-- "Does the district have fiber IA/upstream?"
						case when d.exclude_from_wan_analysis = false then 'Not Target' --12								-- "Is the district fit for WAN analysis"
						else 'Potential Target' end --11
					else 
						case when d.exclude_from_wan_analysis = false then 'Target' --10									-- "Is the district fit for WAN analysis"
						else 'Potential Target' end --9
					end
				else
					case when 	d.non_fiber_lines = 0 then 'Potential Target' --5											-- "Is the non-fiber line clean?"
					     when 	d.fiber_internet_upstream_lines_w_dirty + d.fiber_wan_lines_w_dirty = 0 then 'Target' --6	-- "Does the district have any fiber?"
					     when 	d.fiber_internet_upstream_lines_w_dirty + d.fiber_wan_lines_w_dirty < d.num_campuses and 	-- "Is the sum of the fiber lines < num campuses"
								d.exclude_from_wan_analysis = false then 'Target' --8										-- "Is the district fit for WAN analysis"
					else 'Potential Target' end --7
				end
			end
	else
		case 	when 	d.exclude_from_wan_analysis = false then 'Not Target'	--3											-- "Is the district fit for WAN analysis"
				else 'Potential Target' end --2
	end as stage_indicator

from public.fy2017_districts_predeluxe_matr d

left join fy2017_campus_w_fiber_nonfiber_matr c
on d.esh_id = c.district_esh_id

left join public.fy2016_fiber_bw_target_status_matr d16
on d.esh_id = d16.esh_id

where d.include_in_universe_of_districts_all_charters
group by d.esh_id,
  d.lines_w_dirty,
  d.num_campuses,
  d.fiber_internet_upstream_lines,
  d.non_fiber_lines_w_dirty,
  d.fiber_internet_upstream_lines_w_dirty,
  d.exclude_from_wan_analysis,
  d.wan_lines_w_dirty,
  d.non_fiber_lines,
  d.fiber_wan_lines_w_dirty,
  d.include_in_universe_of_districts,
  d.district_type,
  d.postal_cd,
  d16.fiber_target_no_override

/*
Author: Jeremy Holtzman
Created On Date: 4/27/2017
Last Modified Date: 4/27/2017
Name of QAing Analyst(s):
Purpose: To identify fiber targets, potential targets, and not targets
Methodology: same logic as 2016, except first checks if Not Target (pre override) in 2016, and
	if Target in 2016 preoverride but would've been No Data 2017
*/