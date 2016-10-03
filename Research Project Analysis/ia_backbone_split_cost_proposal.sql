select			dd.*,
				da.flag_array,								
				case											
					when	circuit_lines_fiber >= circuit_lines_cabledsl 
							and circuit_lines_fiber >= circuit_lines_copper 
							and circuit_lines_fiber >= circuit_lines_fixedwireless 								
						then	'Fiber'										
					when	circuit_lines_fixedwireless >= circuit_lines_fiber 
							and circuit_lines_fixedwireless >= circuit_lines_copper 
							and circuit_lines_fixedwireless >= circuit_lines_cabledsl 								
						then	'Fixed Wireless'										
					when	circuit_lines_cabledsl >= circuit_lines_fiber 
							and circuit_lines_cabledsl >= circuit_lines_copper 
							and circuit_lines_cabledsl >= circuit_lines_fixedwireless 								
						then	'Cable / DSL'
					when	circuit_lines_copper >= circuit_lines_fiber 
							and circuit_lines_copper >= circuit_lines_fixedwireless 
							and circuit_lines_copper >= circuit_lines_cabledsl 								
						then	'Copper'	
				end	as highest_connect_category_circuit_lines,
				case											
					when	com_info_bandwidth	>	0								
						then	com_info_bandwidth										
					when	upstream_bandwidth	=	0								
						then	isp_bandwidth										
					when	isp_bandwidth	=	0								
						then	upstream_bandwidth										
					when	upstream_bandwidth	>	isp_bandwidth								
						then	isp_bandwidth										
					else	upstream_bandwidth										
				end	+	internet_bandwidth	as	ia_bandwidth,							
				case
					when num_students != 'No data'
						then case
								when num_students::numeric > 0
									then (case											
													when	com_info_bandwidth	>	0								
														then	com_info_bandwidth										
													when	upstream_bandwidth	=	0								
														then	isp_bandwidth										
													when	isp_bandwidth	=	0								
														then	upstream_bandwidth										
													when	upstream_bandwidth	>	isp_bandwidth								
														then	isp_bandwidth										
													else	upstream_bandwidth										
												end	+	internet_bandwidth)/num_students::numeric*1000
							end
				end as ia_bandwidth_per_student_kbps,								
				case											
					when	com_info_bandwidth_cost	>	0								
						then	com_info_bandwidth_cost										
					when	upstream_bandwidth_cost	=	0								
						then	isp_bandwidth_cost										
					when	isp_bandwidth_cost	=	0								
						then	upstream_bandwidth_cost										
					when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
						then	isp_bandwidth_cost										
					else	upstream_bandwidth_cost										
				end	+	internet_bandwidth_cost	as	ia_bandwidth_for_cost_per_mbps,	
				ia_cost_direct_to_district	+	
				    			(ia_cost_per_student_backbone_pieces*case
				    													when num_students != 'No data'
				    														then num_students::numeric
				    													else 0
				    												end) as ia_cost,										
				case											
				  when (case											
			          	when	com_info_bandwidth_cost	>	0								
			          	then	com_info_bandwidth_cost										
			          	when	upstream_bandwidth_cost	=	0								
			          	then	isp_bandwidth_cost										
			          	when	isp_bandwidth_cost	=	0								
			          	then	upstream_bandwidth_cost										
			          	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
			          	then	isp_bandwidth_cost										
			          	else	upstream_bandwidth_cost										
			          end	+	internet_bandwidth_cost) > 0									
				    then  (ia_cost_direct_to_district	+	
				    			(ia_cost_per_student_backbone_pieces*case
				    													when num_students != 'No data'
				    														then num_students::numeric
				    													else 0
				    												end))/
				    				(case									
                    	when	com_info_bandwidth_cost	>	0								
                    	then	com_info_bandwidth_cost										
                    	when	upstream_bandwidth_cost	=	0								
                    	then	isp_bandwidth_cost										
                    	when	isp_bandwidth_cost	=	0								
                    	then	upstream_bandwidth_cost										
                    	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
                    	then	isp_bandwidth_cost										
                    	else	upstream_bandwidth_cost										
                    end	+	internet_bandwidth_cost)					
			  end as	ia_cost_per_mbps_annual,
				ia_cost_direct_to_district	+	
				    			(ia_cost_per_ia_bandwidth_backbone_pieces*case
					    													when ia_bandwidth_per_student != 'Insufficient data' and num_students != 'No data'
					    														then ia_bandwidth_per_student::numeric*num_students::numeric
					    													else 0
					    												end) as ia_cost_proposed,										
				case											
				  when (case											
			          	when	com_info_bandwidth_cost	>	0								
			          	then	com_info_bandwidth_cost										
			          	when	upstream_bandwidth_cost	=	0								
			          	then	isp_bandwidth_cost										
			          	when	isp_bandwidth_cost	=	0								
			          	then	upstream_bandwidth_cost										
			          	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
			          	then	isp_bandwidth_cost										
			          	else	upstream_bandwidth_cost										
			          end	+	internet_bandwidth_cost) > 0									
				    then  (ia_cost_direct_to_district	+	
				    			(ia_cost_per_ia_bandwidth_backbone_pieces*case
					    													when ia_bandwidth_per_student != 'Insufficient data' and num_students != 'No data'
					    														then ia_bandwidth_per_student::numeric*num_students::numeric
					    													else 0
					    												end))/
				    				(case									
                    	when	com_info_bandwidth_cost	>	0								
                    	then	com_info_bandwidth_cost										
                    	when	upstream_bandwidth_cost	=	0								
                    	then	isp_bandwidth_cost										
                    	when	isp_bandwidth_cost	=	0								
                    	then	upstream_bandwidth_cost										
                    	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
                    	then	isp_bandwidth_cost										
                    	else	upstream_bandwidth_cost										
                    end	+	internet_bandwidth_cost)					
			  end as	ia_cost_per_mbps_annual_proposed,
				case
		      when num_campuses < fiber_lines 
		        then num_campuses 
		        else fiber_lines 
		    end as known_scalable_campuses,
		    case 
		      when num_schools::numeric > 5 and wan_lines = 0 
		        then 
		          case 
		            when num_campuses > fiber_lines 
		              then num_campuses - fiber_lines 
		              else 0
		          end
		        else 0
		    end as assumed_scalable_campuses,
		    case
		      when copper_dsl_lines > 0 and not(num_schools::numeric > 5 and wan_lines = 0 )
		        then 
		          case
		            when num_campuses < (fiber_lines )
		              then 0
		            when num_campuses - (fiber_lines ) < copper_dsl_lines
		              then num_campuses - (fiber_lines)
		              else copper_dsl_lines
		          end
		        else 0
		    end as known_unscalable_campuses,
		    case 
		      when num_schools::numeric > 5 and wan_lines = 0 
		        then 0 
		        else 
		          case
		            when num_campuses < (fiber_lines + copper_dsl_lines)
		              then 0
		              else num_campuses - (fiber_lines + copper_dsl_lines)
		          end
		    end as assumed_unscalable_campuses,
		    case
		      when num_campuses < fiber_lines
		        then num_campuses 
		        else fiber_lines
		    end as known_fiber_campuses,
		    case 
		      when num_schools::numeric > 5 and wan_lines = 0 
		        then 
		          case 
		            when num_campuses > fiber_lines 
		              then num_campuses - fiber_lines
		              else 0
		          end
		        else 0
		    end as assumed_fiber_campuses,
		    case
		      when non_fiber_lines > 0 and not(num_schools::numeric > 5 and wan_lines = 0 )
		        then 
		          case
		            when num_campuses < fiber_lines
		              then 0
		            when num_campuses - fiber_lines < non_fiber_lines
		              then num_campuses - fiber_lines 
		              else non_fiber_lines
		          end
		        else 0
		    end as known_nonfiber_campuses,
		    case 
		      when num_schools::numeric > 5 and wan_lines = 0 
		        then 0 
		        else 
		          case
		            when num_campuses < fiber_lines + non_fiber_lines
		              then 0
		              else num_campuses - (fiber_lines + non_fiber_lines)
		          end
		    end as assumed_nonfiber_campuses,
		    da.max_wan_bandwidth_mbps,
		    da.min_wan_bandwidth_mbps,
			case
				when num_students != 'No data' 
					then case
							when num_students::numeric > 0
								then da.wan_bandwidth/num_students::numeric*1000
						end
			end as wan_bandwidth_per_student_kbps,
			case
				when wan_num_lines_cost is not null and wan_num_lines_cost > 0
					then da.wan_cost/da.wan_num_lines_cost
			end as wan_cost_per_connection_annual,								
		    da.com_info_bandwidth,
		    da.internet_bandwidth,
		    da.upstream_bandwidth,
		    da.isp_bandwidth,
		    da.com_info_bandwidth_cost,
		    da.internet_bandwidth_cost,
		    da.upstream_bandwidth_cost,
		    da.isp_bandwidth_cost,
		    da.ia_cost_direct_to_district,
		    da.ia_cost_per_student_backbone_pieces,
		    da.ia_cost_per_ia_bandwidth_backbone_pieces,
		    da.wan_lines,
		    da.fiber_lines,
		    da.copper_dsl_lines,
		    da.non_fiber_lines										
												
from	public.districts		 dd									
left	join	(	select  ldli.district_esh_id,
					--connect_category pieces
					        sum(case                                            
					                    when (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                                
					                    and exclude =  false 
					                    and (not('backbone' = any(open_flags)) or open_flags is null) 
					                    and isp_conditions_met = false
					                    and connect_category = 'Fiber'                            
					                        then allocation_lines                                
					                    else    0                                       
					                end)    as  circuit_lines_fiber,    
					        sum(case                                            
					                    when (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                                
					                    and exclude =  false 
					                    and (not('backbone' = any(open_flags)) or open_flags is null) 
					                    and isp_conditions_met = false
					                    and connect_category = 'Cable / DSL'                            
					                        then allocation_lines                                
					                    else    0                                       
					                end)    as  circuit_lines_cabledsl,   
					        sum(case                                            
					                    when (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                                
					                    and exclude =  false 
					                    and (not('backbone' = any(open_flags)) or open_flags is null) 
					                    and isp_conditions_met = false
					                    and connect_category = 'Copper'                            
					                        then allocation_lines                                
					                    else    0                                       
					                end)    as  circuit_lines_copper,  
					        sum(case                                            
					                    when (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                                
					                    and exclude =  false 
					                    and (not('backbone' = any(open_flags)) or open_flags is null) 
					                    and isp_conditions_met = false
					                    and connect_category = 'Fixed Wireless'                            
					                        then allocation_lines                                
					                    else    0                                       
					                end)    as  circuit_lines_fixedwireless,  

					--ia bw/student pieces                                          
					        sum(case                                            
					                    when    'committed_information_rate'    =   any(open_flags)                                
					                    and number_of_dirty_line_item_flags =   0 
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                             
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  com_info_bandwidth,                                 
					        sum(case                                            
					                    when    internet_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                               
					                    and number_of_dirty_line_item_flags =   0 
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                 
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  internet_bandwidth,                                 
					        sum(case                                            
					                    when    upstream_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                               
					                    and number_of_dirty_line_item_flags =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)         
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  upstream_bandwidth,                                 
					        sum(case                                            
					                    when    isp_conditions_met  =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags is  null)                               
					                    and number_of_dirty_line_item_flags =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)             
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  isp_bandwidth,  
					--ia cost/mbps pieces
					        sum(case                                            
					                    when    'committed_information_rate'    =   any(open_flags)
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  com_info_bandwidth_cost,                                    
					        sum(case                                            
					                    when    internet_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  internet_bandwidth_cost,                                    
					        sum(case                                            
					                    when    upstream_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  upstream_bandwidth_cost,                                    
					        sum(case                                            
					                    when    isp_conditions_met  =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  isp_bandwidth_cost,                                                                 
					        sum(case                                            
					                    when    (isp_conditions_met =   TRUE                                
					                                or  internet_conditions_met =   TRUE                                
					                                or  upstream_conditions_met =   TRUE                                
					                                or  'committed_information_rate'    =   any(open_flags))                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)
					                    and num_lines::numeric>0
					                        then    total_cost::numeric *   (allocation_lines::numeric  /   num_lines::numeric)                     
					                    else    0                                       
					                end)    as  ia_cost_direct_to_district,                                 
					        sum(case                                            
					                    when    ((consortium_shared =   TRUE    and (internet_conditions_met    =   TRUE    or  isp_conditions_met  =   true))
					                                    or 'backbone' = any(open_flags))                                                      
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and district_info_by_li.num_students_served::numeric > 0
					                        then    total_cost::numeric / district_info_by_li.num_students_served::numeric                              
					                    else    0                                       
					                end)    as  ia_cost_per_student_backbone_pieces,
					        sum(case                                            
					                    when    ((consortium_shared =   TRUE    and (internet_conditions_met    =   TRUE    or  isp_conditions_met  =   true))
					                                    or 'backbone' = any(open_flags))                                                      
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and district_info_by_li.num_students_served::numeric > 0
					                        then    total_cost::numeric / district_info_by_li.ia_bandwidth_served::numeric                              
					                    else    0                                       
					                end)    as  ia_cost_per_ia_bandwidth_backbone_pieces,        
					-- wan bandwidth pieces
					        max(case                                            
					                    when    wan_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps                                                        
					                end)    as  max_wan_bandwidth_mbps,
					        min(case                                            
					                    when    wan_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps                                                        
					                end)    as  min_wan_bandwidth_mbps,  
					        sum(case                                            
					                    when    wan_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    bandwidth_in_mbps   *   allocation_lines                                
					                    else    0                                       
					                end)    as  wan_bandwidth, 
					-- wan cost pieces
					        sum(case                                            
					                    when    wan_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    total_cost::numeric *   (allocation_lines::numeric  /   num_lines::numeric)                                
					                    else    0                                       
					                end)    as  wan_cost, 
					        sum(case                                            
					                    when    wan_conditions_met =   TRUE                                
					                    and (not('committed_information_rate'   =   any(open_flags)) or    open_flags    is  null)                               
					                    and number_of_dirty_line_item_flags  =   0
					                    and (not('exclude_for_cost_only'   =   any(open_flags)) or open_flags is null)
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                     
					                        then    allocation_lines                                
					                    else    0                                       
					                end)    as  wan_num_lines_cost, 
					-- campus fiber percentage pieces       
					        sum(case                                            
					                    when    wan_conditions_met = true   
					                    and isp_conditions_met = false                              
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                 
					                        then allocation_lines                               
					                    else    0                                       
					                end) as wan_lines,
					        sum(case                                            
					                    when    connect_category ilike '%fiber%'
					                    and isp_conditions_met = false                              
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                             
					                        then    allocation_lines                                
					                    else    0                                       
					                end) as fiber_lines,
					        sum(case                                            
					                    when    connect_category in ('Other Copper', 'T-1', 'DSL')
					                    and isp_conditions_met = false                              
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                         
					                        then    allocation_lines                                
					                    else    0                                       
					                end) as copper_dsl_lines,
					        sum(case                                            
					                    when not(connect_category ilike '%fiber%')
					                    and isp_conditions_met = false                              
					                    and number_of_dirty_line_item_flags  =   0
					                    and consortium_shared = false
					                    and (not('backbone' = any(open_flags)) or open_flags is null)                                 
					                        then    allocation_lines                                
					                    else    0                                       
					                end) as non_fiber_lines,
					        flag_array

					from    lines_to_district_by_line_item_2015 ldli                                    
					join    public.line_items   li                                  
					on  ldli.line_item_id   =   li.id                               
					left join (
					        select  ldli.line_item_id,                                      
					                        sum(d.num_students::numeric)    as  num_students_served,
					                        sum(d.ia_bandwidth_per_student::numeric*d.num_students::numeric)    as  ia_bandwidth_served                                   
					                                                    
					        from lines_to_district_by_line_item_2015    ldli                                    
					                                                    
					        join public.districts   d                                   
					        on ldli.district_esh_id =   d.esh_id                                
					                                                    
					        join public.line_items  li                                  
					        on ldli.line_item_id    =   li.id                               
					                                                    
					        where   (li.consortium_shared=true                                      
					        or 'backbone' = any(open_flags))
					        and broadband = true 
					        and d.num_students != 'No data'
					        and d.ia_bandwidth_per_student != 'Insufficient data'                                       
					                                                    
					        group   by  ldli.line_item_id   
					) district_info_by_li                                   
					on  district_info_by_li.line_item_id    =   ldli.line_item_id
					full outer join (
					        select  entity_id,
					                array_agg(distinct label) as flag_array                                 
					                                                    
					        from public.entity_flags
					        where status = 0
					                                                   
					        group   by  entity_id    
					) flag_info                                 
					on  flag_info.entity_id =   ldli.district_esh_id                              
					where broadband = true
					group by    ldli.district_esh_id,
					            flag_array

					/*
					Author: Justine Schott
					Created On Date: 7/29/2016
					Last Modified Date: 
					Name of QAing Analyst(s): 
					Purpose: testing new backbone split
					Methodology: copy of district_aggregation_2015
					*/

)	da									
on	dd.esh_id	=	da.district_esh_id
where include_in_universe_of_districts = true									

/*
Author: Justine Schott
Created On Date: 7/29/2016
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: testing new backbone split
Methodology: copy of district_metrics_2015
*/