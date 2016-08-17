select  		dd.esh_id as district_esh_id,
--ia bw/student pieces											
				sum(case											
							when	'committed_information_rate'	=	any(open_tag_labels)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false							
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	com_info_bandwidth,									
				sum(case											
							when	internet_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false								
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	internet_bandwidth,									
				sum(case											
							when	upstream_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false		
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	upstream_bandwidth,									
				sum(case											
							when	isp_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false			
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	isp_bandwidth,	
				sum(case											
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)							
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
							and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
							and consortium_shared = false
							and bandwidth_in_mbps >= 25		
								then	allocation_lines								
							else	0										
						end)	as	broadband_internet_upstream_lines,
--ia cost/mbps pieces
				sum(case											
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and consortium_shared = false									
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	com_info_bandwidth_cost,									
				sum(case											
							when	internet_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false								
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	internet_bandwidth_cost,									
				sum(case											
							when	upstream_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false								
								then	bandwidth_in_mbps	*	allocation_lines								
							else	0										
						end)	as	upstream_bandwidth_cost,									
				sum(case											
							when	isp_conditions_met	=	TRUE								
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_flag_labels	is	null)								
							and	num_open_flags	=	0
							and consortium_shared = false									
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
									and num_lines::numeric>0
										then	total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																	/ case
																		when months_of_service = 0 or months_of_service is null
																			then 12
																		else months_of_service
																	  end						
									else	0										
								end)	as	ia_monthly_cost_direct_to_district,									
						sum(case											
									when	((consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true))
													or backbone_conditions_met = true)														
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
										then	total_cost::numeric	/ (district_info_by_li.num_students_served::numeric * months_of_service )								
									else	0										
								end)	as	ia_monthly_cost_per_student_backbone_pieces,
-- wan cost/connection pieces
						sum(case											
									when	wan_conditions_met = true								
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
									and	num_open_flags	=	0
									and consortium_shared = false
									and num_lines::numeric>0
										then	total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																	/ case
																		when months_of_service = 0 or months_of_service is null
																			then 12
																		else months_of_service
																	  end					
									else	0										
								end)	as	wan_monthly_cost,	
						sum(case											
									when	wan_conditions_met = true	
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)								
									and	num_open_flags	=	0
									and consortium_shared = false									
										then allocation_lines								
									else	0										
								end) as wan_lines_cost,
-- campus fiber percentage pieces		
						sum(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then allocation_lines								
									else	0										
								end) as wan_lines,
						sum(case											
									when	connect_category ilike '%fiber%'
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false								
										then	allocation_lines								
									else	0										
								end) as fiber_lines,
						sum(case											
									when	connect_category in ('Other Copper', 'T-1', 'DSL')
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false							
										then	allocation_lines								
									else	0										
								end) as copper_dsl_lines,
						sum(case											
									when not(connect_category ilike '%fiber%')
									and isp_conditions_met = false								
									and	num_open_flags	=	0
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as non_fiber_lines,
--other
				        array_to_string(
				          array_agg( distinct
				            case 
								when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)							
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false	
				                then connect_category 
				            end 
				          ), ', ') as all_ia_connectcat,
						sum(case											
									when connect_category ILIKE '%Fiber%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as fiber_internet_upstream_lines,
						sum(case											
									when connect_category ILIKE '%Fixed Wireless%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as fixed_wireless_internet_upstream_lines,
						sum(case											
									when connect_category ILIKE '%Cable%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as cable_internet_upstream_lines,
						sum(case											
									when 	connect_category ILIKE '%DSL%' or 
						    				connect_category ILIKE '%Copper%' or 
						    				connect_category ILIKE '%T-1%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as copper_internet_upstream_lines,
						sum(case											
									when connect_category ILIKE '%Satellite/LTE%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as satellite_lte_internet_upstream_lines,
						sum(case											
									when connect_category ILIKE '%Uncategorized%'
									and (internet_conditions_met = true or upstream_conditions_met = true)						
									and (num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then	allocation_lines								
									else	0										
								end) as uncategorized_internet_upstream_lines,
						min(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then bandwidth_in_mbps														
								end) as wan_bandwidth_low,
						max(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false									
										then bandwidth_in_mbps														
								end) as wan_bandwidth_high,
						sum(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false	
									and bandwidth_in_mbps >= 1000										
										then allocation_lines								
									else	0										
								end) as gt_1g_wan_lines,
						sum(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false
									and connect_category ILIKE '%Fiber%'	
									and bandwidth_in_mbps < 1000										
										then allocation_lines								
									else	0										
								end) as lt_1g_fiber_wan_lines,
						sum(case											
									when	wan_conditions_met = true		
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)														
									and	(num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))
									and consortium_shared = false
									and not(connect_category ILIKE '%Fiber%')	
									and bandwidth_in_mbps < 1000										
										then allocation_lines								
									else	0										
								end) as lt_1g_nonfiber_wan_lines,
					    array_to_string(
					    	array_agg(distinct 
					    				case when 	internet_conditions_met=true or
					    							upstream_conditions_met=true or
					    							isp_conditions_met=true
					    					then 
					    						concat(applicant_name,
					    								case when consortium_shared=true
					    										then ' (shared)'
					    									when consortium_shared=false and 
					    									isp_conditions_met=true
					    										then ' (dedicated ISP only)'
					    									when consortium_shared=false and 
					    									internet_conditions_met=true
					    										then ' (dedicated Internet)'
					    									when consortium_shared=false and 
					    									upstream_conditions_met=true
					    										then ' (dedicated Upstream)'
					    									else ' (unknown purpose)'
					    								end)
					    				end)
					    , ', ') as ia_applicants,
						--dedicated ISP
					    array_to_string(
					    	array_agg(case 
					    				when isp_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ', 
								                        	connect_category, ' line(s) at ', 
								                        	bandwidth_in_mbps, ' Mbps from ', 
								                        	service_provider_name, ' for $', 
								                        	round(total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																				/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end,2), '/mth')
					                end), ', ') as dedicated_isp_services,					                    
	                    array_to_string(
	                    	array_agg(case 
	                    				when isp_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ', 
	                    								extract(month from contract_end_date::timestamp), '/', 
	                    								extract(year from contract_end_date::timestamp)) 
	                    			end), ', ') as dedicated_isp_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case 
				              when isp_conditions_met = TRUE and consortium_shared=false 
				                then service_provider_name
				            end
				          ), ', ') as dedicated_isp_sp,
					    --bundled IA
					    array_to_string(
					    	array_agg(case 
					    				when internet_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ', 
								                        	connect_category, ' line(s) at ', 
								                        	bandwidth_in_mbps, ' Mbps from ', 
								                        	service_provider_name, ' for $', 
								                        	round(total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																				/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end,2), '/mth')
					                end), ', ') as bundled_internet_services,
	                    array_to_string(
	                    	array_agg(case 
	                    				when internet_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ', 
	                    								extract(month from contract_end_date::timestamp), '/', 
	                    								extract(year from contract_end_date::timestamp)) 
	                    			end), ', ') as bundled_internet_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case 
				              when internet_conditions_met = TRUE and consortium_shared=false
				                then service_provider_name
				            end
				          ), ', ') as bundled_internet_sp,					    
	                    --upstream
					    array_to_string(
					    	array_agg(case 
					    				when upstream_conditions_met=true and consortium_shared=false  and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ', 
								                        	connect_category, ' line(s) at ', 
								                        	bandwidth_in_mbps, ' Mbps from ', 
								                        	service_provider_name, ' for $', 
								                        	round(total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																				/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end,2), '/mth')
					                end), ', ') as upstream_services,
	                    array_to_string(
	                    	array_agg(case 
	                    				when upstream_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ', 
	                    								extract(month from contract_end_date::timestamp), '/', 
	                    								extract(year from contract_end_date::timestamp)) 
	                    			end), ', ') as upstream_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case 
				              when upstream_conditions_met = TRUE and consortium_shared=false 
				                then service_provider_name
				            end
				          ), ', ') as upstream_sp,
					    --WAN
					    array_to_string(
					    	array_agg(distinct case 
					    						when wan_conditions_met=true and consortium_shared=false 
					    							then applicant_name 
					    					end), ', ') as wan_applicants,    
					    array_to_string(            
					    	array_agg(case 
					    				when wan_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ', 
								                        	connect_category, ' line(s) at ', 
								                        	bandwidth_in_mbps, ' Mbps from ', 
								                        	service_provider_name, ' for $', 
								                        	round(total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric) 
																				/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end,2), '/mth')
					                end), ', ') as wan_services,
					    array_to_string(
	                    	array_agg(case 
	                    				when wan_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ', 
	                    								extract(month from contract_end_date::timestamp), '/', 
	                    								extract(year from contract_end_date::timestamp)) 
	                    			end), ', ') as wan_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case 
				              when wan_conditions_met = TRUE and consortium_shared=false 
				                then service_provider_name
				            end
				          ), ', ') as wan_sp,
						campus_count,
						frl_percent,
						flag_array,
						flag_count,
						tag_array,
						c1_discount_rate,
						c2_discount_rate,
						sum(case											
									when (num_open_flags	=	0 or (num_open_flags	=	1 and 'exclude_for_cost_only'	=	any(open_flag_labels)))	
									and ('cc_updated_15' = any(tag_array) or 
										 'purpose_updated_15' = any(tag_array) or 
										 'num_lines_updated_15' = any(tag_array) or 
										 'bw_updated_15' = any(tag_array))
										then allocation_lines								
									else	0										
								end) as machine_cleaned_lines

from	public.districts_demog_2016 dd
left join public.lines_to_district_by_line_item_2016	ldli
on 	dd.esh_id = ldli.district_esh_id							
left join	(
		select *
		from fy2016.line_items
		where broadband = true
		and (not('canceled' = any(open_flag_labels) or 
		        'video_conferencing' = any(open_flag_labels) or
		        'exclude' = any(open_flag_labels))
	    		or open_flag_labels is null)
)	li									
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
				count(distinct 	case
									when campus_id is null
										then address
									else campus_id
								end) as campus_count,
				case
					when sum(frl_percentage_denomenator) > 0
						then sum(frl_percentage_numerator)/sum(frl_percentage_denomenator) 
				end as frl_percent									
													
		from schools_demog_2016										
													
		group	by	district_esh_id	
) school_info									
on	school_info.district_esh_id	=	dd.esh_id		
left join (
		select	flaggable_id,
				array_agg(distinct label) as flag_array,
				case
					when count(distinct label) is null
						then 0
					else count(distinct label)
				end as flag_count											
													
		from fy2016.flags
		where status = 'open'									
													
		group	by	flaggable_id	
) flag_info									
on	flag_info.flaggable_id::varchar	=	dd.esh_id		
left join (
		select	taggable_id,
				array_agg(distinct label) as tag_array									
													
		from fy2016.tags
		where deleted_at is null										
													
		group	by	taggable_id	
) tag_info									
on	tag_info.taggable_id::varchar	=	dd.esh_id									
left join (
		select	entity_id,
				min(parent_category_one_discount_rate) as c1_discount_rate,
				min(parent_category_two_discount_rate) as c2_discount_rate								
													
		from fy2016.discount_calculations dc
		join ( select distinct entity_id, ben
            from public.entity_bens) eim
		on dc.parent_entity_ben = eim.ben
		group by entity_id
) dr_info									
on	dr_info.entity_id::varchar	=	dd.esh_id		
group by	dd.esh_id,
			campus_count,
			frl_percent,
			flag_array,
			flag_count,
			tag_array,
			c1_discount_rate,
			c2_discount_rate

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 8/16/2016
Name of QAing Analyst(s): 
Purpose: Districts' line item aggregation (bw, lines, cost of pieces contributing to metrics),
as well as school metric, flag/tag, and discount rate aggregation
Methodology: Utilizing other aggregation tables
*/