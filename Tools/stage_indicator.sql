select 
	d.esh_id,
	case when lines_w_dirty = 0 then 'FIBER TARGET'																	--per brad, dqs cleaning standards
	when num_campuses = 1 and fiber_internet_upstream_lines_w_dirty > 0 then 'CLOSED LOST'							--per brad, dqs cleaning standards
	when non_fiber_lines_w_dirty > 0 then																			--row 1
		case when num_campuses = 1 and fiber_internet_upstream_lines_w_dirty > 0 then									--row 2
			case when 	exclude_from_analysis = false then																--row 3
				'CLOSED LOST 3/4/5' else 'dont update 3/4/5' end 														--rows 4,5
		else	
			case when district_specif_recip_nonfiber_lines > 0 and campuses_specif_recip_nonfiber_lines = 0 then		--row 6
					case when 	non_fiber_lines_w_dirty > 0 then														--row 7
						case when num_campuses = campuses_specif_recip_fiber_wan_lines then 							--row 8
							case when fiber_internet_upstream_lines_w_dirty > 0 then									--row 9
								case 	when 	exclude_from_analysis = false and 
												priority_status__c not in ('Priority 1','Priority 3') and
												(not(array_to_string(flag_array,',') ilike '%wan%')
												or flag_array is null) then 'CLOSED LOST 11/12'
										when 	exclude_from_analysis = true and 
												priority_status__c not in ('Priority 1','Priority 3') and
												array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 11/12'	--row 10
								 		else 'dont update 11/12' end													--rows 11,12
							else 
								case when 	district_recip_clean_nonfiber_lines > 0 and 
											(not('district_missing_ia' = any(flag_array)) or flag_array is null) and
											(not('district_isp_missing_upstream' = any(flag_array)) or flag_array is null) then
									'FIBER TARGET 13/14/15' else 'dont update 13/14/15' end	
							end																							--rows 13,14,15
						else 
							case when 	num_campuses = campuses_specif_recip_fiber_internet_upstream_lines and
										num_campuses <= fiber_internet_upstream_lines_w_dirty then						--row 16
								case 	when 	exclude_from_analysis = false and 
												priority_status__c not in ('Priority 1','Priority 3') and
												(not(array_to_string(flag_array,',') ilike '%wan%')
												or flag_array is null) then 'CLOSED LOST 18/19'
										when 	exclude_from_analysis = true and 
												priority_status__c not in ('Priority 1','Priority 3') and
												array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 18/19'	--row 17
								 		else 'dont update 18/19' end													--rows 18,19
							else 
								case when 	district_recip_clean_nonfiber_lines > 0 and 
											(not('district_missing_ia' = any(flag_array)) or flag_array is null) and
											(not('district_isp_missing_upstream' = any(flag_array)) or flag_array is null) then
									'FIBER TARGET 20/21/22' else 'dont update 20/21/22' end	
							end																							--rows 20,21,22
						end
					else
						case 	when 	exclude_from_analysis = false and 
										priority_status__c not in ('Priority 1','Priority 3') and
										(not(array_to_string(flag_array,',') ilike '%wan%')
										or flag_array is null) then 'CLOSED LOST 24/25'
								when 	exclude_from_analysis = true and 
										priority_status__c not in ('Priority 1','Priority 3') and
										array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 24/25'			--row 23
						 		else 'dont update 24/25' end															--rows 24,25
					end
			else
				case when 	campuses_specif_recip_nonfiber_not_wan_lines_alloc = 0 or
							fiber_internet_upstream_lines_w_dirty >= sum_alloc_ia_fiber_lines or 
							fiber_internet_upstream_lines_w_dirty >= count_ben_ia_fiber_lines then						--row 26
					case when fiber_internet_upstream_lines_w_dirty > 0 then 											--row 27
						case 	when 	exclude_from_analysis = false and 
										priority_status__c not in ('Priority 1','Priority 3') and
										(not(array_to_string(flag_array,',') ilike '%wan%')
										or flag_array is null) then 'CLOSED LOST 29/30'
								when 	exclude_from_analysis = true and 
										priority_status__c not in ('Priority 1','Priority 3') and
										array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 29/30'			--row 28
						 		else 'dont update 29/30' end															--rows 29,30
					else 
						case when 	district_recip_clean_nonfiber_lines > 0 and 
									(not('district_missing_ia' = any(flag_array)) or flag_array is null) and
									(not('district_isp_missing_upstream' = any(flag_array)) or flag_array is null) then
							'FIBER TARGET 31/32/33' else 'dont update 31/32/33' end	
					end																									--rows 31,32,33
				else 
					case when 	campuses_specif_recip_nonfiber_not_ia_lines_alloc = 0  or
								fiber_wan_lines_w_dirty >= sum_alloc_wan_fiber_lines or 
								fiber_wan_lines_w_dirty >= count_ben_wan_fiber_lines then								--row 34
						case 	when 	exclude_from_analysis = false and 
										priority_status__c not in ('Priority 1','Priority 3') and
										(not(array_to_string(flag_array,',') ilike '%wan%')
										or flag_array is null) then 'CLOSED LOST 36/37'
								when 	exclude_from_analysis = true and 
										priority_status__c not in ('Priority 1','Priority 3') and
										array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 36/37'			--row 35
						 		else 'dont update 36/37' end															--rows 36,37
					else 
						case when 	district_recip_clean_nonfiber_lines > 0 and 
									(not('district_missing_ia' = any(flag_array)) or flag_array is null) and
									(not('district_isp_missing_upstream' = any(flag_array)) or flag_array is null) then
							'FIBER TARGET 38/39/40' else 'dont update 38/39/40' end	
					end																									--rows 38,39,40
				end
			end
		end
	else
		case 	when 	exclude_from_analysis = false and 
						priority_status__c not in ('Priority 1','Priority 3') and
						(not(array_to_string(flag_array,',') ilike '%wan%')
						or flag_array is null) then 'CLOSED LOST 42/43'
				when 	exclude_from_analysis = true and 
						priority_status__c not in ('Priority 1','Priority 3') and
						array_to_string(flag_array,',') ilike '%wan%' then 'POTENTIAL 42/43'							--row 41
		 		else 'dont update 42/43' end																			--rows 42,43
	end as stage_indicator,
	non_fiber_lines_w_dirty,
	non_fiber_internet_upstream_lines_w_dirty,
	fiber_internet_upstream_lines_w_dirty,
	district_specif_recip_nonfiber_lines,
	campuses_specif_recip_nonfiber_lines,
	campuses_specif_recip_fiber_wan_lines,
	campuses_specif_recip_fiber_internet_upstream_lines,
	campuses_specif_recip_nonfiber_not_wan_lines_alloc,
	campuses_specif_recip_nonfiber_not_ia_lines_alloc,
	district_recip_clean_nonfiber_lines,
	num_campuses,
	exclude_from_analysis,
	priority_status__c,
	flag_array
from public.fy2016_districts_deluxe_ma d
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
					when campus_id is not null and specif_recip_fiber_internet_upstream_lines > 0
						then campus_id
				end) as campuses_specif_recip_fiber_internet_upstream_lines,
			count(case
					when campus_id is not null and specif_recip_nonfiber_lines > 0 and specif_recip_fiber_wan_lines_alloc = 0
						then campus_id
				end) as campuses_specif_recip_nonfiber_not_wan_lines_alloc,
			count(case
					when campus_id is not null and specif_recip_nonfiber_lines > 0 and specif_recip_fiber_internet_upstream_lines_alloc = 0
						then campus_id
				end) as campuses_specif_recip_nonfiber_not_ia_lines_alloc,
			count(case
					when specif_recip_clean_nonfiber_lines > 0
						then esh_id
				end) as district_recip_clean_nonfiber_lines
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
									when (c.internet_conditions_met = true or c.upstream_conditions_met = true) 
									and c.connect_category ilike '%Fiber%'
										then ec.circuit_id
								end) as specif_recip_fiber_internet_upstream_lines,
				count(distinct 	case
									when (c.internet_conditions_met = true or c.upstream_conditions_met = true) 
									and c.connect_category ilike '%Fiber%'
									and num_lines != 'Unknown'
									and (	num_lines::numeric = li.num_recipients or 
											num_lines::numeric = alloc.alloc
										)
										then ec.circuit_id
								end) as specif_recip_fiber_internet_upstream_lines_alloc,
				count(distinct 	case
									when 	not(c.connect_category ilike '%Fiber%')
											and	(	c.num_open_flags	=	0 or 
													(	c.num_open_flags	=	1 and 
														'exclude_for_cost_only'	=	any(c.open_flag_labels)
													)
												)
										then ec.circuit_id
								end) as specif_recip_clean_nonfiber_lines
		from fy2016_districts_demog_ma d
		left join public.fy2016_district_lookup_ma dl
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
) campus_recips
on d.esh_id = campus_recips.esh_id
left join (
		select  d.esh_id,
				sum(case
						when not(li.connect_category ilike '%Fiber%')
							then alloc.original_num_lines_to_allocate
					end) as sum_alloc_nonfiber_lines,
				sum(case
						when li.wan_conditions_met = true 
							and li.connect_category ilike '%Fiber%'		
							then alloc.original_num_lines_to_allocate
					end) as sum_alloc_wan_fiber_lines,
				sum(case
						when (li.internet_conditions_met = true or li.upstream_conditions_met = true)
							and li.connect_category ilike '%Fiber%'		
							then alloc.original_num_lines_to_allocate
					end) as sum_alloc_ia_fiber_lines,
				count(distinct 	case
									when not(li.connect_category ilike '%Fiber%')
										then alloc.recipient_ben
								end) as count_ben_nonfiber_lines,
				count(distinct 	case
									when li.wan_conditions_met = true 
										and li.connect_category ilike '%Fiber%'		
										then alloc.recipient_ben
								end) as count_ben_wan_fiber_lines,
				count(distinct 	case
									when (li.internet_conditions_met = true or li.upstream_conditions_met = true)
										and li.connect_category ilike '%Fiber%'		
										then alloc.recipient_ben
								end) as count_ben_ia_fiber_lines
		from fy2016_districts_demog_ma d
		left join public.fy2016_lines_to_district_by_line_item_ma ldli
		on d.esh_id = ldli.district_esh_id
		left join fy2016.line_items li
		on ldli.line_item_id = li.id
		left join (
			select 	*
			from fy2016.allocations
			where broadband = true
			and recipient_type in ('School', 'District')
		) alloc
		on ldli.line_item_id = alloc.line_item_id
		where li.isp_conditions_met = false
		and li.backbone_conditions_met = false
		and li.consortium_shared = false
		and (not('canceled' = any(li.open_flag_labels) or 
		        'video_conferencing' = any(li.open_flag_labels) or
		        'exclude' = any(li.open_flag_labels))
				or li.open_flag_labels is null)
		and district_esh_id is not null
		group by d.esh_id		
) district_alloc_recips
on d.esh_id = district_alloc_recips.esh_id
where district_type = 'Traditional'
or (postal_cd = 'AZ' and district_type = 'Charter')

/*
Author: Justine Schott
Created On Date: 8/17/2016
Last Modified Date: 8/31/2016
Name of QAing Analyst(s): 
Purpose: To identify districts that can have their stage modified in Salesforce algorithmically
Methodology: Utilizes fy2016_districts_deluxe_ma -- the districts deluxe materialized version, because the query 
took too long to run. Need to brainstorm a solution when implementing.
*/