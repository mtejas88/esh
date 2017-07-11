select  		dd.esh_id as district_esh_id,
--ia bw/student pieces
				sum(case
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth,
				sum(case
							when	internet_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth,
				sum(case
							when	isp_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps >= 25
								then	allocation_lines
							else	0
						end)	as	broadband_internet_upstream_lines,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps < 25
								then	allocation_lines
							else	0
						end)	as	not_broadband_internet_upstream_lines,
--ia cost/mbps pieces
				sum(case
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth_cost,
				sum(case
							when	internet_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth_cost,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth_cost,
				sum(case
							when	isp_conditions_met	=	TRUE
							and (not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth_cost,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_tag_labels))
									and	num_open_flags	=	0
									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
																	/*/ case
																		when months_of_service = 0 or months_of_service is null
																			then 12
																		else months_of_service
																	  end*/
									else	0
								end)	as	ia_monthly_cost_direct_to_district,
						sum(case
									when	backbone_conditions_met = true
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
										then	esh_rec_cost::numeric	/ district_info_by_li.num_students_served::numeric /** months_of_service )*/
									else	0
								end)	as	ia_monthly_cost_per_student_backbone_pieces,
						sum(case
									when	consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true)
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
										then	esh_rec_cost::numeric	/ district_info_by_li.num_students_served::numeric /** months_of_service )*/
									else	0
								end)	as	ia_monthly_cost_per_student_shared_ia_pieces,
-- wan cost/connection pieces
						sum(case
									when	wan_conditions_met = true
									and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
									and num_lines::numeric>0
										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
																	/*/ case
																		when months_of_service = 0 or months_of_service is null
																			then 12
																		else months_of_service
																	  end*/
									else	0
								end)	as	wan_monthly_cost,
						sum(case
									when	wan_conditions_met = true
									and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
										then allocation_lines
									else	0
								end) as wan_lines_cost,
-- campus fiber percentage pieces
						sum(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
										then allocation_lines
									else	0
								end) as wan_lines,
						sum(case
									when	connect_category ilike '%fiber%'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_lines,
						sum(case
									when	connect_category = 'Fixed Wireless'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fixed_wireless_lines,
						sum(case
									when	connect_category = 'Cable'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as cable_lines,
						sum(case
									when	connect_category in ('Other Copper', 'T-1', 'DSL')
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as copper_dsl_lines,
						sum(case
									when	connect_category = 'Satellite/LTE'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as satellite_lte_lines,
						sum(case
									when not(connect_category ilike '%fiber%')
									and isp_conditions_met = false
									and backbone_conditions_met = false
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
									and	num_open_flags	=	0
									and consortium_shared = false
				                then connect_category
				            end
				          ), ' | ') as all_ia_connectcat,
						sum(case
									when connect_category ILIKE '%Fiber%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_internet_upstream_lines,
						sum(case
									when connect_category ILIKE '%Fixed Wireless%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fixed_wireless_internet_upstream_lines,
						sum(case
									when connect_category ILIKE '%Cable%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as cable_internet_upstream_lines,
						sum(case
									when 	connect_category ILIKE '%DSL%' or
						    				connect_category ILIKE '%Copper%' or
						    				connect_category ILIKE '%T-1%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as copper_internet_upstream_lines,
						sum(case
									when connect_category ILIKE '%Satellite/LTE%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as satellite_lte_internet_upstream_lines,
						sum(case
									when connect_category ILIKE '%Uncategorized%'
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as uncategorized_internet_upstream_lines,
						min(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
										then bandwidth_in_mbps
								end) as wan_bandwidth_low,
						max(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
										then bandwidth_in_mbps
								end) as wan_bandwidth_high,
						sum(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
									and bandwidth_in_mbps >= 1000
										then allocation_lines
									else	0
								end) as gt_1g_wan_lines,
						sum(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
									and connect_category ILIKE '%Fiber%'
									and bandwidth_in_mbps < 1000
										then allocation_lines
									else	0
								end) as lt_1g_fiber_wan_lines,
						sum(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
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
					    , ' | ') as ia_applicants,
						--dedicated ISP
					    array_to_string(
					    	array_agg(case
					    				when isp_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' line(s) at ',
								                        	bandwidth_in_mbps, ' Mbps from ',
								                        	service_provider_name, ' for $',
								                        	round(esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric),2)
																				/*/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end*/, '/mth')
					                end), ' | ') as dedicated_isp_services,
	                    array_to_string(
	                    	array_agg(case
	                    				when isp_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ',
	                    								extract(month from contract_end_date::timestamp), '/',
	                    								extract(year from contract_end_date::timestamp))
	                    			end), ' | ') as dedicated_isp_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case
				              when isp_conditions_met = TRUE and consortium_shared=false
				                then service_provider_name
				            end
				          ), ' | ') as dedicated_isp_sp,
					    --bundled IA
					    array_to_string(
					    	array_agg(case
					    				when internet_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ',
								                        	connect_category, ' line(s) at ',
								                        	bandwidth_in_mbps, ' Mbps from ',
								                        	service_provider_name, ' for $',
								                        	round(esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric),2)
																				/*/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end*/, '/mth')
					                end), ' | ') as bundled_internet_services,
	                    array_to_string(
	                    	array_agg(case
	                    				when internet_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ',
	                    								extract(month from contract_end_date::timestamp), '/',
	                    								extract(year from contract_end_date::timestamp))
	                    			end), ' | ') as bundled_internet_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case
				              when internet_conditions_met = TRUE and consortium_shared=false
				                then service_provider_name
				            end
				          ), ' | ') as bundled_internet_sp,
	                    --upstream
					    array_to_string(
					    	array_agg(case
					    				when upstream_conditions_met=true and consortium_shared=false  and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ',
								                        	connect_category, ' line(s) at ',
								                        	bandwidth_in_mbps, ' Mbps from ',
								                        	service_provider_name, ' for $',
								                        	round(esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric),2)
																				/*/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end*/, '/mth')
					                end), ' | ') as upstream_services,
	                    array_to_string(
	                    	array_agg(case
	                    				when upstream_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ',
	                    								extract(month from contract_end_date::timestamp), '/',
	                    								extract(year from contract_end_date::timestamp))
	                    			end), ' | ') as upstream_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case
				              when upstream_conditions_met = TRUE and consortium_shared=false
				                then service_provider_name
				            end
				          ), ' | ') as upstream_sp,
					    --WAN
					    array_to_string(
					    	array_agg(distinct case
					    						when wan_conditions_met=true and consortium_shared=false
					    							then applicant_name
					    					end), ' | ') as wan_applicants,
					    array_to_string(
					    	array_agg(case
					    				when wan_conditions_met=true and consortium_shared=false and num_lines != 'Unknown' and num_lines::numeric > 0
					                    	then concat(	allocation_lines, ' ',
								                        	connect_category, ' line(s) at ',
								                        	bandwidth_in_mbps, ' Mbps from ',
								                        	service_provider_name, ' for $',
								                        	round(esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric),2)
																				/*/ case
																					when months_of_service = 0 or months_of_service is null
																						then 12
																					else months_of_service
																				  end*/, '/mth')
					                end), ' | ') as wan_services,
					    array_to_string(
	                    	array_agg(case
	                    				when wan_conditions_met=true and consortium_shared=false
	                    					then concat(service_provider_name, ' - ',
	                    								extract(month from contract_end_date::timestamp), '/',
	                    								extract(year from contract_end_date::timestamp))
	                    			end), ' | ') as wan_contract_expiration,
	                    array_to_string(
				          array_agg( distinct
				            case
				              when wan_conditions_met = TRUE and consortium_shared=false
				                then service_provider_name
				            end
				          ), ' | ') as wan_sp,
						case
							when campus_count is null
								then num_schools
							else campus_count
						end as campus_count,
						frl_percent,
						flag_array,
						flag_count,
						tag_array,
						c1_discount_rate,
						c2_discount_rate,
						sum(case
									when num_open_flags	=	0
									and ('cc_updated_15' = any(open_tag_labels) or
										 'purpose_updated_15' = any(open_tag_labels) or
										 'num_lines_updated_15' = any(open_tag_labels) or
										 'bw_updated_15' = any(open_tag_labels))
										then allocation_lines
									else	0
								end) as machine_cleaned_lines,
--clean and dirty for stage_indicator
						sum(case
									when (not(connect_category ilike '%fiber%')
										or connect_type in ('DS-1', 'Digital Subscriber Line (DSL)'))
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as non_fiber_lines_w_dirty,
						sum(case
									when (not(connect_category ilike '%fiber%')
										or connect_type in ('DS-1', 'Digital Subscriber Line (DSL)'))
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as non_fiber_internet_upstream_lines_w_dirty,
						sum(case
									when connect_category ILIKE '%Fiber%'
									and connect_type not in ('DS-1', 'Digital Subscriber Line (DSL)')
									and (internet_conditions_met = true or upstream_conditions_met = true)
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_internet_upstream_lines_w_dirty,
						sum(case
									when connect_category ILIKE '%Fiber%'
									and connect_type not in ('DS-1', 'Digital Subscriber Line (DSL)')
									and wan_conditions_met = true
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_wan_lines_w_dirty,
						sum(case
									when isp_conditions_met = false
									and backbone_conditions_met = false
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as lines_w_dirty,
						sum(case
									when wan_conditions_met = true
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as wan_lines_w_dirty,
						sum(allocation_lines) as line_items_w_dirty,
						sum(case
									when num_open_flags	=	0
									and connect_category ILIKE '%Fiber%'
									and connect_type not in ('DS-1', 'Digital Subscriber Line (DSL)')
									and wan_conditions_met = true
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_wan_lines,
--consortium
						array_to_string(array_agg(distinct
													case
														when 	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
																and real_applicant_id::varchar!=ldli.district_esh_id
																and real_applicant_type!='School'
																and real_applicant_id::varchar not in (	select esh_id
																							from public.fy2016_districts_demog_matr
																							where include_in_universe_of_districts=true)
																	then applicant_name
														when	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
																and service_provider_id in (5452, 5997, 6058, 6140, 6396, 6687, 6724, 6889, 6983, 7032,	7150,
																							7277, 7350, 7555, 7672, 7690, 7869, 8008, 8117, 8120, 8157, 8171,
																							8192, 8284, 8294, 8492, 8557, 8588, 8632, 8651, 8735, 8823, 8920,
																							8967, 9361, 9398, 9444, 9708, 9793, 10046, 10091, 10126, 10179, 10276,
																							10565, 10632, 412)
																	then service_provider_name
													end), ' | ') as consortium_affiliation,
						case
							when ( 	sum(case
											when 	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
													and real_applicant_type!='School'
													and real_applicant_id::varchar!=ldli.district_esh_id
													and real_applicant_id::varchar not in (	select esh_id
																				from public.fy2016_districts_demog_matr
																				where include_in_universe_of_districts=true)
														then 1
											else 0
										end)>0
								OR
									sum(case
											when 	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
													and service_provider_id in (5452, 5997, 6058, 6140, 6396, 6687, 6724, 6889, 6983, 7032,	7150,
																				7277, 7350, 7555, 7672, 7690, 7869, 8008, 8117, 8120, 8157, 8171,
																				8192, 8284, 8294, 8492, 8557, 8588, 8632, 8651, 8735, 8823, 8920,
																				8967, 9361, 9398, 9444, 9708, 9793, 10046, 10091, 10126, 10179, 10276,
																				10565, 10632, 412)

														then 1
											else 0
										end)>0)
								and sum(case
											when 	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
													and real_applicant_id::varchar=ldli.district_esh_id
													and service_provider_id not in (5452, 5997, 6058, 6140, 6396, 6687, 6724, 6889, 6983, 7032,	7150,
																					7277, 7350, 7555, 7672, 7690, 7869, 8008, 8117, 8120, 8157, 8171,
																					8192, 8284, 8294, 8492, 8557, 8588, 8632, 8651, 8735, 8823, 8920,
																					8967, 9361, 9398, 9444, 9708, 9793, 10046, 10091, 10126, 10179, 10276,
																					10565, 10632, 412)
														then 1
											else 0
										end)=0
									then 'Consortium-provided'
							when (sum(	case
											when 	(isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
													and real_applicant_type!='School'
													and real_applicant_id::varchar!=ldli.district_esh_id
													and real_applicant_id::varchar not in (	select esh_id
																				from public.fy2016_districts_demog_matr
																				where include_in_universe_of_districts=true)
														then 1
											else 0
										end)>0
								OR
								sum(case
										when (isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
										and service_provider_id in (5452, 5997, 6058, 6140, 6396, 6687, 6724, 6889, 6983, 7032,	7150,
																	7277, 7350, 7555, 7672, 7690, 7869, 8008, 8117, 8120, 8157, 8171,
																	8192, 8284, 8294, 8492, 8557, 8588, 8632, 8651, 8735, 8823, 8920,
																	8967, 9361, 9398, 9444, 9708, 9793, 10046, 10091, 10126, 10179, 10276,
																	10565, 10632, 412)

											then 1
										else 0
									end)>0)
								and sum(case
											when (isp_conditions_met=true OR internet_conditions_met=true OR upstream_conditions_met=true)
											and real_applicant_id::varchar=ldli.district_esh_id
											and service_provider_id not in (5452, 5997, 6058, 6140, 6396, 6687, 6724, 6889, 6983, 7032,	7150,
																	7277, 7350, 7555, 7672, 7690, 7869, 8008, 8117, 8120, 8157, 8171,
																	8192, 8284, 8294, 8492, 8557, 8588, 8632, 8651, 8735, 8823, 8920,
																	8967, 9361, 9398, 9444, 9708, 9793, 10046, 10091, 10126, 10179, 10276,
																	10565, 10632, 412)

												then 1
											else 0
										end)>0
									then 'Consortium+District'
							when sum(case
									when isp_conditions_met = false
									and backbone_conditions_met = false
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) = 0 then 'Unknown'
							else 'Self-procured'
						end as ia_procurement_type,
--cleanliness
						sum(case
									when ('exclude_for_cost_only_restricted'= any(open_tag_labels) or ('exclude_for_cost_only_unknown'= any(open_tag_labels)))
									and (internet_conditions_met or upstream_conditions_met or isp_conditions_met or backbone_conditions_met)
										then allocation_lines
									else	0
								end) as ia_no_cost_lines,
						sum(case
									when ('exclude_for_cost_only_restricted'= any(open_tag_labels) or ('exclude_for_cost_only_unknown'= any(open_tag_labels)))
									and wan_conditions_met
										then allocation_lines
									else	0
								end) as wan_no_cost_lines,
						include_in_universe_of_districts,
--state landing page
						min( case
									 when ( isp_conditions_met = true
									       or internet_conditions_met = true
												 or upstream_conditions_met = true )
									 and backbone_conditions_met = false
									 and consortium_shared = false
									 and erate
										 then contract_end_date
								  end ) as most_recent_ia_contract_end_date,
--progress tracking
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_tag_labels))
									and	num_open_flags	=	0
									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
									and real_applicant_id::varchar = dd.esh_id
										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
									else	0
								end)	as	ia_monthly_cost_direct_to_district_district_applied,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_tag_labels))
									and	num_open_flags	=	0
									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
									and real_applicant_id::varchar != dd.esh_id
										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
									else	0
								end)	as	ia_monthly_cost_direct_to_district_other_applied,
						sum(case
									when	(backbone_conditions_met
											or (consortium_shared	and	(internet_conditions_met or	isp_conditions_met)))
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
									and real_applicant_id::varchar = dd.esh_id
										then	esh_rec_cost::numeric	/ district_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_shared_district_applied,
						sum(case
									when	(backbone_conditions_met
											or (consortium_shared	and	(internet_conditions_met or	isp_conditions_met)))
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
									and real_applicant_id::varchar != dd.esh_id
										then	esh_rec_cost::numeric	/ district_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_shared_other_applied,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_tag_labels))
									and	num_open_flags	=	0
									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
										then	esh_rec_cost::numeric*(allocation_lines::numeric/num_lines::numeric)*discount_rate
									else	0
								end)	as	ia_monthly_funding_direct_to_district,
						sum(case
									when	(backbone_conditions_met
											or (consortium_shared	and	(internet_conditions_met or	isp_conditions_met)))
									and	num_open_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
									and real_applicant_id::varchar != dd.esh_id
										then	(esh_rec_cost::numeric/district_info_by_li.num_students_served::numeric)*discount_rate
									else	0
								end)	as	ia_monthly_funding_per_student_shared

from	public.fy2016_districts_demog_matr dd
left join public.fy2016_lines_to_district_by_line_item_matr	ldli
on 	dd.esh_id = ldli.district_esh_id
left join
  ( SELECT
fy2016.line_items.id,fy2016.line_items.frn_complete,fy2016.line_items.frn,fy2016.line_items.application_number,fy2016.line_items.application_type,fy2016.line_items.applicant_ben,fy2016.line_items.applicant_name,fy2016.line_items.applicant_postal_cd,fy2016.line_items.service_provider_id,fy2016.line_items.service_provider_name,fy2016.line_items.service_type,fy2016.line_items.service_category,fy2016.line_items.connect_type,fy2016.line_items.connect_category,fy2016.line_items.purpose,fy2016.line_items.bandwidth_in_mbps,fy2016.line_items.bandwidth_in_original_units,fy2016.line_items.num_lines,fy2016.line_items.total_cost,fy2016.line_items.one_time_elig_cost,fy2016.line_items.rec_elig_cost,fy2016.line_items.months_of_service,fy2016.line_items.contract_end_date,fy2016.line_items.num_open_flags,fy2016.line_items.open_flag_labels,fy2016.line_items.open_tag_labels,fy2016.line_items.num_recipients,fy2016.line_items.erate,fy2016.line_items.broadband,fy2016.line_items.consortium_shared,fy2016.line_items.isp_conditions_met,fy2016.line_items.upstream_conditions_met,fy2016.line_items.internet_conditions_met,fy2016.line_items.wan_conditions_met,fy2016.line_items.exclude,fy2016.line_items.upload_bandwidth_in_mbps,fy2016.line_items.backbone_conditions_met,fy2016.line_items.function,
           eb.entity_id as real_applicant_id,
           eb.entity_type as real_applicant_type,
           CASE
               WHEN rec_elig_cost > 0 then rec_elig_cost
               ELSE one_time_elig_cost/ CASE
                                            WHEN months_of_service = 0
                                                 OR months_of_service is null then 12
                                            ELSE months_of_service
                                        END
           END AS esh_rec_cost,
           reporting_name,
           frns.discount_rate::numeric/100 as discount_rate
   FROM fy2016.line_items
   left join public.entity_bens eb
   on eb.ben = fy2016.line_items.applicant_ben
   left join fy2016.frns
   on line_items.frn = frns.frn
   left join(
    select distinct name, reporting_name
    from service_provider_categories
    ) spc
   on fy2016.line_items.service_provider_name = spc.name
   WHERE broadband = true
     AND (not('canceled' = any(open_flag_labels)
              OR 'video_conferencing' = any(open_flag_labels)
              OR 'exclude' = any(open_flag_labels))
          OR open_flag_labels is null) ) li
on	ldli.line_item_id	=	li.id
left join (
		select	ldli.line_item_id,
						sum(d.num_students::numeric)	as	num_students_served

		from fy2016_lines_to_district_by_line_item_matr	ldli

		join fy2016_districts_demog_matr	d
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
									when campus_id is null or campus_id = 'Unknown'
										then address
									else campus_id
								end) as campus_count,
				case
					when sum(	frl_percentage_denomenator) > 0
						then sum(frl_percentage_numerator)/sum(	 frl_percentage_denomenator)
				end as frl_percent

		from public.fy2016_schools_demog_matr

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
			num_schools,
			frl_percent,
			flag_array,
			flag_count,
			tag_array,
			c1_discount_rate,
			c2_discount_rate,
			include_in_universe_of_districts

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 4/13/2017 - jh added exclude for cost only unknown
Name of QAing Analyst(s):
Purpose: Districts' line item aggregation (bw, lines, cost of pieces contributing to metrics),
as well as school metric, flag/tag, and discount rate aggregation
Methodology: Utilizing other aggregation tables
*/