select	dd.*,
				case 
		          when dd.district_size in ('Tiny', 'Small') then 1
		          when dd.district_size = 'Medium' then 1.5
		          when dd.district_size = 'Large' then 1.75
		          when dd.district_size = 'Mega' then 2.25
		        end as ia_oversub_ratio,	
				case
					when da.campus_count is null
						then num_schools
					else da.campus_count
				end as num_campuses,
				da.flag_array,
				da.tag_array,
				broadband_internet_upstream_lines,							
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
				ia_monthly_cost_direct_to_district	+	
				    			(ia_monthly_cost_per_student_backbone_pieces*num_students) as ia_monthly_cost,
				ia_monthly_cost_direct_to_district,
				ia_monthly_cost_per_student_backbone_pieces*num_students as ia_monthly_cost_shared,    													
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
				    then  (ia_monthly_cost_direct_to_district	+	
				    			(ia_monthly_cost_per_student_backbone_pieces*num_students))/
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
			  end as	ia_monthly_cost_per_mbps,
				case											
				  when wan_lines_cost > 0									
				    then  wan_monthly_cost/wan_lines_cost					
			  end as	wan_monthly_cost_per_line,
			COALESCE (
			    case when (all_ia_connectcat ILIKE '%Fiber%') then 'Fiber' else NULL end,
			    case when (all_ia_connectcat ILIKE '%Fixed Wireless%') then 'Fixed Wireless' else NULL end,
			    case when (all_ia_connectcat ILIKE '%Cable%') then 'Cable' else NULL end,
			    case when ( all_ia_connectcat ILIKE '%DSL%' or 
			    			all_ia_connectcat ILIKE '%Copper%' or 
			    			all_ia_connectcat ILIKE '%T-1%') then 'Copper' else NULL end,
				case when (all_ia_connectcat ILIKE '%Satellite/LTE%') then 'Satellite/LTE' else NULL end,
			    case when (all_ia_connectcat ILIKE '%Uncategorized%') then 'Uncategorized' else 'None - Error' end
			) as hierarchy_connect_category,
			all_ia_connectcat,
		    case
		      when campus_count < fiber_lines + fixed_wireless_lines + 	case 
		      																when num_students < 100 
		      																	then cable_lines 
		      																else 0 
		      															end
		        then campus_count 
		        else fiber_lines + fixed_wireless_lines + 	case 
																when num_students < 100 
																	then cable_lines 
																else 0 
															end
		    end as known_scalable_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 
		          case 
		            when campus_count > fiber_lines + fixed_wireless_lines + 	case 
																					when num_students < 100 
																						then cable_lines 
																					else 0 
																				end
		              then campus_count - fiber_lines + fixed_wireless_lines + 	case 
																					when num_students < 100 
																						then cable_lines 
																					else 0 
																				end
		              else 0
		          end
		        else 0
		    end as assumed_scalable_campuses,
		    case
		      when num_students < 100 and copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
		        then 
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines + cable_lines)
		              then 0
		            when campus_count - (fiber_lines + fixed_wireless_lines + cable_lines) < copper_dsl_lines
		              then campus_count - (fiber_lines + fixed_wireless_lines + cable_lines)
		              else copper_dsl_lines
		          end
		      when num_students >= 100 and (copper_dsl_lines + cable_lines)> 0  and not(num_schools > 5 and wan_lines = 0 ) 
		        then
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines)
		              then 0
		            when campus_count - (fiber_lines + fixed_wireless_lines ) < copper_dsl_lines + cable_lines
		              then campus_count - (fiber_lines + fixed_wireless_lines)
		              else copper_dsl_lines + cable_lines
		          end
		        else 0
		    end as known_unscalable_campuses,
		    case 
		      when num_schools > 5 and wan_lines = 0 
		        then 0 
		        else 
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines + copper_dsl_lines + cable_lines)
		              then 0
		              else campus_count - (fiber_lines + fixed_wireless_lines + copper_dsl_lines + cable_lines)
		          end
		    end as assumed_unscalable_campuses,
		      case
		        when campus_count < fiber_lines 
		          then campus_count 
		          else fiber_lines 
		      end as nga_v2_known_scalable_campuses,
		      case 
		        when num_schools > 5 and wan_lines = 0 
		          then 
		            case 
		              when campus_count > fiber_lines 
		                then campus_count - fiber_lines 
		                else 0
		            end
		          else 0
		      end as nga_v2_assumed_scalable_campuses,
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
		      end as nga_v2_known_unscalable_campuses,
		      case 
		        when num_schools > 5 and wan_lines = 0 
		          then 0 
		          else 
		            case
		              when campus_count < (fiber_lines + copper_dsl_lines)
		                then 0
		                else campus_count - (fiber_lines + copper_dsl_lines)
		            end
		      end as nga_v2_assumed_unscalable_campuses,
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
			fiber_internet_upstream_lines,
			fixed_wireless_internet_upstream_lines,
			cable_internet_upstream_lines,
			copper_internet_upstream_lines,
			satellite_lte_internet_upstream_lines,
			uncategorized_internet_upstream_lines,
			wan_lines,
			wan_bandwidth_low,
			wan_bandwidth_high,
			gt_1g_wan_lines,
			lt_1g_fiber_wan_lines,
			lt_1g_nonfiber_wan_lines,
			ia_applicants,
			dedicated_isp_sp,
			dedicated_isp_services,
			dedicated_isp_contract_expiration,
			bundled_internet_sp,
			bundled_internet_services,
			bundled_internet_contract_expiration,
			upstream_sp,
			upstream_services,
			upstream_contract_expiration,
			wan_applicants,
			wan_sp,
			wan_services,
			wan_contract_expiration,
			frl_percent,
		    c1_discount_rate as discount_rate_c1,
		    c2_discount_rate as discount_rate_c2,
		    flag_count,
		    wan_monthly_cost,
		    machine_cleaned_lines,
		    non_fiber_lines,
		    dd.num_self_procuring_charters,
		    non_fiber_lines_w_dirty,
		    non_fiber_internet_upstream_lines_w_dirty,
		    fiber_internet_upstream_lines_w_dirty,
		    fiber_wan_lines_w_dirty,
		    lines_w_dirty									
												
from	fy2016_districts_demog_m		 dd									
left	join	fy2016_districts_aggregation_mat	da									
on	dd.esh_id	=	da.district_esh_id									

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 9/06/2016
Name of QAing Analyst(s): 
Purpose: Districts in 2016 universe, including metric calculations and cleanliness
Methodology: Utilizing other aggregation tables
*/