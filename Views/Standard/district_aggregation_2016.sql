select  ldli.district_esh_id,
--ia bw/student pieces											
				sum(case											
							when	'committed_information_rate'	=	any(open_tag_labels)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false
							and backbone_conditions_met = false								
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	com_info_bandwidth,									
				sum(case											
							when	internet_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false
							and backbone_conditions_met = false									
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	internet_bandwidth,									
				sum(case											
							when	upstream_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false
							and backbone_conditions_met = false			
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	upstream_bandwidth,									
				sum(case											
							when	isp_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false
							and backbone_conditions_met = false				
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	isp_bandwidth,	
--ia cost/mbps pieces
				sum(case											
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and consortium_shared = false
							and backbone_conditions_met = false										
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	com_info_bandwidth_cost,									
				sum(case											
							when	internet_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false
							and backbone_conditions_met = false										
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	internet_bandwidth_cost,									
				sum(case											
							when	upstream_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false
							and backbone_conditions_met = false										
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	upstream_bandwidth_cost,									
				sum(case											
							when	isp_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false
							and backbone_conditions_met = false										
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	isp_bandwidth_cost,																	
						sum(case											
									when	(isp_conditions_met	=	TRUE								
												or	internet_conditions_met	=	TRUE								
												or	upstream_conditions_met	=	TRUE								
												or	'committed_information_rate'	=	any(open_tag_labels))								
									and	num_open_flags	=	0
									and consortium_shared = false
									and backbone_conditions_met = false
									and num_lines::numeric>0
										then	total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)						
									else	0										
								end)	as	ia_cost_direct_to_district,									
						sum(case											
									when	((consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true))
													or backbone_conditions_met = true)														
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
										then	total_cost::numeric	/ district_info_by_li.num_students_served::numeric								
									else	0										
								end)	as	ia_cost_per_student_backbone_pieces,
-- campus fiber percentage pieces		
						sum(case											
									when	wan_conditions_met = true	
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false
									and backbone_conditions_met = false									
										then allocation_lines								
									else	0										
								end) as wan_lines,
						sum(case											
									when	connect_category ilike '%fiber%'
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false
									and backbone_conditions_met = false								
										then	allocation_lines								
									else	0										
								end) as fiber_lines,
						sum(case											
									when	connect_category in ('Other Copper', 'T-1', 'DSL')
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false
									and backbone_conditions_met = false							
										then	allocation_lines								
									else	0										
								end) as copper_dsl_lines,
						sum(case											
									when not(connect_category ilike '%fiber%')
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false
									and backbone_conditions_met = false									
										then	allocation_lines								
									else	0										
								end) as non_fiber_lines,
						campus_count

from	lines_to_district_by_line_item_2016	ldli									
join	fy2016.line_items	li									
on	ldli.line_item_id	=	li.id								
left join (
		select	ldli.line_item_id,										
						sum(d.num_students::numeric)	as	num_students_served									
													
		from lines_to_district_by_line_item_2016	ldli									
													
		join districts_demog_2016	d									
		on ldli.district_esh_id	=	d.esh_id								
													
		join fy2016.line_items	li									
		on ldli.line_item_id	=	li.id								
													
		where	(li.consortium_shared=true										
		or backbone_conditions_met = true)
		and broadband = true										
													
		group	by	ldli.line_item_id	
) district_info_by_li									
on	district_info_by_li.line_item_id	=	ldli.line_item_id
left join (
		select	district_esh_id,
						count(case
										when campus_id is null
											then address
										else campus_id
									end) as campus_count									
													
		from schools_demog_2016										
													
		group	by	district_esh_id	
) campus_info									
on	campus_info.district_esh_id	=	ldli.district_esh_id								
where broadband = true
group by	ldli.district_esh_id,
					campus_count

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: Districts' line item aggregation (bw, lines, cost of pieces contributing to metrics)
Methodology: Utilizing other aggregation tables
*/