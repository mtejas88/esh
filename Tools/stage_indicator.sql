select 
	d.esh_id,
	case when non_fiber_lines > 0 then																					--row 5
			case when district_specif_recip_nonfiber_lines > 0 and campuses_specif_recip_nonfiber_lines = 0 then		--row 6
					case when 	fixed_wireless_internet_upstream_lines +
								cable_internet_upstream_lines +
								copper_internet_upstream_lines + 
								satellite_lte_internet_upstream_lines + 
								uncategorized_internet_upstream_lines > 0 then											--row 7
						case when num_campuses = campuses_specif_recip_fiber_wan_lines then 							--row 8
							case when fiber_internet_upstream_lines > 0 then 											--row 9
								case when 	exclude_from_analysis = false and 
											priority_status__c not in ('Priority 1','Priority 3') then					--row 10
								'CLOSED LOST' else 'dont update' end													--rows 11,12
							else 
								case when district_specif_recip_clean_nonfiber_lines > 0 then
									'FIBER TARGET' else 'dont update' end	
							end																							--rows 13,14,15
						else 
							case when num_campuses = campuses_specif_recip_fiber_internet_upstream_lines then			--row 16
								case when 	exclude_from_analysis = false and 
											priority_status__c not in ('Priority 1','Priority 3') then					--row 17 
								'CLOSED LOST' else 'dont update' end													--rows 18,19
							else 
								case when district_specif_recip_clean_nonfiber_lines > 0 then
									'FIBER TARGET' else 'dont update' end	
							end																							--rows 20,21,22
						end
					else
						case when 	exclude_from_analysis = false and 
									priority_status__c not in ('Priority 1','Priority 3') then							--row 23
						'CLOSED LOST' else 'dont update' end															--rows 24,25 
					end
			else
				case when campuses_specif_recip_nonfiber_not_wan_lines_alloc = 0 then									--row 26
					case when fiber_internet_upstream_lines > 0 then 													--row 27
						case when 	exclude_from_analysis = false and 
									priority_status__c not in ('Priority 1','Priority 3') then 							--row 28
						'CLOSED LOST' else 'dont update' end															--rows 29, 30
					else 
						case when district_specif_recip_clean_nonfiber_lines > 0 then
							'FIBER TARGET' else 'dont update' end	
					end																									--rows 31,32,33
				else 
					case when num_campuses = campuses_specif_recip_fiber_internet_upstream_lines then					--row 34
						case when 	exclude_from_analysis = false and 
									priority_status__c not in ('Priority 1','Priority 3') then							--row 35 
						'CLOSED LOST' else 'dont update' end															--rows 36,37
					else 
						case when district_specif_recip_clean_nonfiber_lines > 0 then
							'FIBER TARGET' else 'dont update' end	
					end																									--rows 38,39,40
				end
			end
	else
		case when 	exclude_from_analysis = false and 
					priority_status__c not in ('Priority 1','Priority 3') then											--row 41
		'CLOSED LOST' else 'dont update' end																			--rows 42,43
	end as stage_indicator,
	non_fiber_lines,
	fixed_wireless_internet_upstream_lines + cable_internet_upstream_lines + copper_internet_upstream_lines + 
		satellite_lte_internet_upstream_lines + uncategorized_internet_upstream_lines as non_fiber_internet_upstream_lines,
	fiber_internet_upstream_lines,
	district_specif_recip_nonfiber_lines,
	campuses_specif_recip_nonfiber_lines,
	campuses_specif_recip_fiber_wan_lines,
	campuses_specif_recip_nonfiber_not_wan_lines_alloc,
	campuses_specif_recip_fiber_internet_upstream_lines,
	district_specif_recip_clean_nonfiber_lines,
	num_campuses,
	exclude_from_analysis,
	priority_status__c
from public.districts_longitudinal d
left join (
	select 
		account__esh_id__c, 
		priority_status__c
	from salesforce.opportunity opp
	where priority_status__c ilike '%priority%'
) opp
on d.esh_id = opp.account__esh_id__c
left join (
	select esh_id,
			count(case
					when campus_id is null and specif_recip_nonfiber_lines > 0
						then esh_id
				end) as district_specif_recip_nonfiber_lines,
			count(case
					when campus_id is not null and specif_recip_nonfiber_lines > 0
						then campus_id
				end) as campuses_specif_recip_nonfiber_lines,
			count(case
					when campus_id is not null and specif_recip_fiber_wan_lines > 0
						then campus_id
				end) as campuses_specif_recip_fiber_wan_lines,
			count(case
					when campus_id is not null and specif_recip_nonfiber_lines > 1 and specif_recip_fiber_wan_lines_alloc = 0
						then campus_id
				end) as campuses_specif_recip_nonfiber_not_wan_lines_alloc,
			count(case
					when campus_id is not null and specif_recip_fiber_internet_upstream_lines > 0
						then campus_id
				end) as campuses_specif_recip_fiber_internet_upstream_lines,
			count(case
					when specif_recip_clean_nonfiber_lines > 0
						then esh_id
				end) as district_specif_recip_clean_nonfiber_lines
	from(
		select  d.esh_id,
				ds.campus_id,
				count(distinct 	case
									when not(c.connect_category ilike '%Fiber%')
										then ec.circuit_id
								end) as specif_recip_nonfiber_lines,
				count(distinct 	case
									when c.wan_conditions_met = true 
									and c.connect_category ilike '%Fiber%'
										then ec.circuit_id
								end) as specif_recip_fiber_wan_lines,
				count(distinct 	case
									when c.wan_conditions_met = true 
									and c.connect_category ilike '%Fiber%'
									and num_lines != 'Unknown'
									and (	num_lines::numeric = li.num_recipients or 
											num_lines::numeric = alloc.alloc
										)
										then ec.circuit_id
								end) as specif_recip_fiber_wan_lines_alloc,
				count(distinct 	case
									when (c.internet_conditions_met = true or c.internet_conditions_met = true) 
									and c.connect_category ilike '%Fiber%'
										then ec.circuit_id
								end) as specif_recip_fiber_internet_upstream_lines,
				count(distinct 	case
									when 	not(c.connect_category ilike '%Fiber%')
											and	(	c.num_open_flags	=	0 or 
													(	c.num_open_flags	=	1 and 
														'exclude_for_cost_only'	=	any(c.open_flag_labels)
													)
												)
										then ec.circuit_id
								end) as specif_recip_clean_nonfiber_lines
		from districts_longitudinal d
		left join public.district_lookup_2016 dl
		on d.esh_id = dl.district_esh_id
		left join (
				select 	school_id::varchar,
						case
							when campus_id is null
								then 'unknown'
							else campus_id
						end as campus_id --string in place of campus_id so that null campus can be district above
				from fy2016.districts_schools 
		) ds
		on dl.esh_id = ds.school_id
		left join fy2016.entity_circuits ec
		on ec.entity_id::varchar = dl.esh_id
		left join fy2016.circuits c
		on ec.circuit_id = c.id
		left join fy2016.line_items li
		on c.line_item_id = li.id
		left join (
			select 	line_item_id,
					sum(original_num_lines_to_allocate) as alloc
			from fy2016.allocations
			where broadband = true
			group by line_item_id
		) alloc
		on c.line_item_id = alloc.line_item_id
		where c.isp_conditions_met = false
		and c.backbone_conditions_met = false
		and c.consortium_shared = false
		and (not('canceled' = any(c.open_flag_labels) or 
		        'video_conferencing' = any(c.open_flag_labels) or
		        'exclude' = any(c.open_flag_labels))
				or c.open_flag_labels is null)
		and district_esh_id is not null
		group by d.esh_id,
				ds.campus_id
	) campus_agg
	group by esh_id
) clean_campus_recips
on d.esh_id = clean_campus_recips.esh_id

/*
Author: Justine Schott
Created On Date: 8/17/2016
Last Modified Date: 8/23/2016
Name of QAing Analyst(s): 
Purpose: To identify districts that can have their stage modified in Salesforce algorithmically
Methodology: Utilizes districts_longitudinal -- NOTE THAT WHEN 2015 DATA IS IN THAT TABLE, WE NEED TO ONLY USE 2016 FOR THIS QUERY. 
*/