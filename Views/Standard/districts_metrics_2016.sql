select	dd.*,	
				da.campus_count,
				da.flag_array,
				da.tag_array,								
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
					when num_students != 0
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
									end	+	internet_bandwidth)/num_students*1000
				end as ia_bandwidth_per_student,								
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
				    			(ia_cost_per_student_backbone_pieces*num_students) as ia_cost,										
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
				    			(ia_cost_per_student_backbone_pieces*num_students))/
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
			  end as	ia_cost_per_mbps,
				case
		      when campus_count < fiber_lines 
		        then campus_count 
		        else fiber_lines 
		    end as known_scalable_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 
		          case 
		            when campus_count > fiber_lines 
		              then campus_count - fiber_lines 
		              else 0
		          end
		        else 0
		    end as assumed_scalable_campuses,
		    case
		      when copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
		        then 
		          case
		            when campus_count < (fiber_lines )
		              then 0
		            when campus_count - (fiber_lines ) < copper_dsl_lines
		              then campus_count - (fiber_lines)
		              else copper_dsl_lines
		          end
		        else 0
		    end as known_unscalable_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 0 
		        else 
		          case
		            when campus_count < (fiber_lines + copper_dsl_lines)
		              then 0
		              else campus_count - (fiber_lines + copper_dsl_lines)
		          end
		    end as assumed_unscalable_campuses,
		    case
		      when campus_count < fiber_lines
		        then campus_count 
		        else fiber_lines
		    end as known_fiber_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 
		          case 
		            when campus_count > fiber_lines 
		              then campus_count - fiber_lines
		              else 0
		          end
		        else 0
		    end as assumed_fiber_campuses,
		    case
		      when non_fiber_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
		        then 
		          case
		            when campus_count < fiber_lines
		              then 0
		            when campus_count - fiber_lines < non_fiber_lines
		              then campus_count - fiber_lines 
		              else non_fiber_lines
		          end
		        else 0
		    end as known_nonfiber_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 0 
		        else 
		          case
		            when campus_count < fiber_lines + non_fiber_lines
		              then 0
		              else campus_count - (fiber_lines + non_fiber_lines)
		          end
		    end as assumed_nonfiber_campuses,
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
		    da.wan_lines,
		    da.fiber_lines,
		    da.copper_dsl_lines,
		    da.non_fiber_lines										
												
from	districts_demog_2016		 dd									
left	join	district_aggregation_2016	da									
on	dd.esh_id	=	da.district_esh_id									

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: Districts in 2016 universe, including metric calculations and cleanliness
Methodology: Utilizing other aggregation tables
*/