select 
	d.esh_id,
	case
		when exclude_from_analysis = false then
			case when non_fiber_lines > 0 or app_non_fiber_lines > 0 then														--row 5
					case when non_fiber_lines = 0 then																			--row 6
							case when app_non_fiber_internet_upstream_lines > 0 then											--row 7
								case when num_campuses = campuses_specif_recip_fiber_wan_lines then 							--row 8
									case when fiber_internet_upstream_lines > 0 then 											--row 9
										case when priority_status__c not in ('Priority 1','Priority 3') then					--row 10
										'CLOSED LOST' else 'dont update' end													--rows 11,12
									else 'FIBER TARGET' end																		--rows 13,14,15
								else 
									case when num_campuses = campuses_specif_recip_fiber_internet_upstream_lines then			--row 16
										case when priority_status__c not in ('Priority 1','Priority 3') then					--row 17 
										'CLOSED LOST' else 'dont update' end													--rows 18,19
									else 'FIBER TARGET' end																		--rows 20,21,22
								end
							else
								case when priority_status__c not in ('Priority 1','Priority 3') then							--row 23
								'CLOSED LOST' else 'dont update' end															--rows 24,25 
							end
					else
						case when num_campuses = campuses_specif_recip_fiber_wan_lines then	 									--row 26
							case when fiber_internet_upstream_lines > 0 then 													--row 27
								case when priority_status__c not in ('Priority 1','Priority 3') then 							--row 28
								'CLOSED LOST' else 'dont update' end															--rows 29, 30
							else 'FIBER TARGET' end																				--rows 31,32,33
						else 
							case when num_campuses = campuses_specif_recip_fiber_internet_upstream_lines then					--row 34
								case when priority_status__c not in ('Priority 1','Priority 3') then							--row 35 
								'CLOSED LOST' else 'dont update' end															--rows 36,37
							else 'FIBER TARGET' end																				--rows 38,39,40
						end
					end
			else
				case when priority_status__c not in ('Priority 1','Priority 3') then											--row 41
				'CLOSED LOST' else 'dont update' end																			--rows 42,43
			end
	else
		'dont update'
	end as stage_indicator,
	exclude_from_analysis,
	non_fiber_lines as recip_non_fiber_lines,
	app_non_fiber_lines,
	app_non_fiber_internet_upstream_lines,
	fiber_internet_upstream_lines as recip_fiber_internet_upstream_lines,
	priority_status__c,
	num_campuses,
	campuses_specif_recip_fiber_wan_lines,
	campuses_specif_recip_fiber_internet_upstream_lines
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
	select dl.district_esh_id,
			sum(case
					when not(connect_category ilike '%Fiber%')
						then num_lines::numeric
					else 0
				end) as app_non_fiber_lines,
			sum(case
					when not(connect_category ilike '%Fiber%')
					and (internet_conditions_met = true
						or upstream_conditions_met = true)
						then num_lines::numeric
					else 0
				end) as app_non_fiber_internet_upstream_lines
	from fy2016.line_items li
	left join public.district_lookup_2016 dl
	on li.applicant_id::varchar = dl.esh_id
	where broadband = true
	and isp_conditions_met = false
	and backbone_conditions_met = false
	and consortium_shared = false
	and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
	and (not('canceled' = any(open_flag_labels) or 
	        'video_conferencing' = any(open_flag_labels) or
	        'exclude' = any(open_flag_labels))
			or open_flag_labels is null)
	and district_esh_id is not null
	group by dl.district_esh_id
) clean_li_apps
on d.esh_id = clean_li_apps.district_esh_id
left join (
	select esh_id,
			count(case
					when specif_recip_fiber_wan_lines > 0
						then campus_id
				end) as campuses_specif_recip_fiber_wan_lines,
			count(case
					when specif_recip_fiber_internet_upstream_lines > 0
						then campus_id
				end) as campuses_specif_recip_fiber_internet_upstream_lines
	from(
		select  d.esh_id,
				ds.campus_id,
				count(distinct 	case
									when c.wan_conditions_met = true 
									and c.connect_category ilike '%Fiber%'
										then ec.circuit_id
								end) as specif_recip_fiber_wan_lines,
				count(distinct 	case
									when (c.internet_conditions_met = true or c.internet_conditions_met = true) 
									and c.connect_category ilike '%Fiber%'
										then ec.circuit_id
								end) as specif_recip_fiber_internet_upstream_lines
		from districts_longitudinal d
		left join public.district_lookup_2016 dl
		on d.esh_id = dl.district_esh_id
		left join fy2016.districts_schools ds
		on dl.esh_id = ds.school_id::varchar
		left join fy2016.entity_circuits ec
		on ec.entity_id = ds.school_id
		left join fy2016.circuits c
		on ec.circuit_id = c.id
		where c.isp_conditions_met = false
		and c.backbone_conditions_met = false
		and c.consortium_shared = false
		and	(c.num_open_flags	=	0 or (c.num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(c.open_flag_labels)))
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
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: To identify districts that can have their stage modified in Salesforce algorithmically
Methodology: Utilizes districts_longitudinal -- NOTE THAT WHEN 2015 DATA IS IN THAT TABLE, WE NEED TO ONLY USE 2016 FOR THIS QUERY. 
*/