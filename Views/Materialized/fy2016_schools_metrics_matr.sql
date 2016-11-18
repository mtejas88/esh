select	sd.*,  --all school demographic information!--  -- ia bandwidth per student 
-- ia monthly cost per Mbps --  
-- fiber?
				case
					when campus_count is null
						then 1  -- since each dataset is a school :)
					else campus_count
				end as num_campuses,
				sa.flag_array,
				sa.tag_array,
				sa.broadband_internet_upstream_lines,
				sa.not_broadband_internet_upstream_lines,
				case
					when com_info_bandwidth	>	0
						then com_info_bandwidth
					when upstream_bandwidth	=	0
						then isp_bandwidth
					when isp_bandwidth	=	0
						then upstream_bandwidth
					when upstream_bandwidth > isp_bandwidth
						then isp_bandwidth
					else upstream_bandwidth
				end	+	internet_bandwidth as	ia_bandwidth,
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
									end	+	internet_bandwidth) / num_students * 1000
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
				    			((ia_monthly_cost_per_student_backbone_pieces +
									ia_monthly_cost_per_student_shared_ia_pieces)*num_students) as ia_monthly_cost,
				ia_monthly_cost_direct_to_district	+
				    			(ia_monthly_cost_per_student_shared_ia_pieces*num_students) as ia_monthly_cost_no_backbone,
				ia_monthly_cost_direct_to_district,
				(ia_monthly_cost_per_student_backbone_pieces +
					ia_monthly_cost_per_student_shared_ia_pieces)*num_students as ia_monthly_cost_shared,
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
				    			((ia_monthly_cost_per_student_backbone_pieces +
									ia_monthly_cost_per_student_shared_ia_pieces)*num_students))/
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
		      when campus_count < fiber_lines + fixed_wireless_lines + satellite_lte_lines + 	case
								      																when num_students < 100
								      																	then cable_lines
								      																else 0
								      															end
		        then campus_count
		        else fiber_lines + fixed_wireless_lines + satellite_lte_lines +	case
																					when num_students < 100
																						then cable_lines
																					else 0
																				end
		    end as sots_known_scalable_campuses,
		    case
		      when num_schools > 5 and wan_lines = 0
		        then
		          case
		            when campus_count > fiber_lines + fixed_wireless_lines + satellite_lte_lines + case
																										when num_students < 100
																											then cable_lines
																										else 0
																									end
		              then campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines + 	case
																										when num_students < 100
																											then cable_lines
																										else 0
																									end)
		              else 0
		          end
		        else 0
		    end as sots_assumed_scalable_campuses,
		    case
		      when num_students < 100 and copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
		        then
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines + satellite_lte_lines + cable_lines)
		              then 0
		            when campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines + cable_lines) < copper_dsl_lines
		              then campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines + cable_lines)
		              else copper_dsl_lines
		          end
		      when num_students >= 100 and (copper_dsl_lines + cable_lines)> 0  and not(num_schools > 5 and wan_lines = 0 )
		        then
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines + satellite_lte_lines)
		              then 0
		            when campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines) < copper_dsl_lines + cable_lines
		              then campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines)
		              else copper_dsl_lines + cable_lines
		          end
		        else 0
		    end as sots_known_unscalable_campuses,
		    case
		      when num_schools > 5 and wan_lines = 0
		        then 0
		        else
		          case
		            when campus_count < (fiber_lines + fixed_wireless_lines + satellite_lte_lines + copper_dsl_lines + cable_lines)
		              then 0
		              else campus_count - (fiber_lines + fixed_wireless_lines + satellite_lte_lines + copper_dsl_lines + cable_lines)
		          end
		    end as sots_assumed_unscalable_campuses,
		    case
		      when campus_count < fiber_lines
		        then campus_count
		        else fiber_lines
		    end as current_known_scalable_campuses,
		    case
		      when copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines > 0
		        then
		          case
		            when campus_count < (fiber_lines )
		              then 0
		            when campus_count - (fiber_lines ) < copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		              then campus_count - (fiber_lines)
		              else copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		          end
		        else 0
		    end as current_known_unscalable_campuses,
            case
              when campus_count < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .92* (campus_count - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_scalable_campuses,
            case
              when campus_count < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .08* (campus_count - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_unscalable_campuses,
			wan_lines,
			frl_percent,
		    c1_discount_rate as discount_rate_c1,
		    c2_discount_rate as discount_rate_c2,
		    flag_count,
		    non_fiber_lines,
		    non_fiber_lines_w_dirty,
		    non_fiber_internet_upstream_lines_w_dirty,
		    fiber_internet_upstream_lines_w_dirty,
		    fiber_wan_lines_w_dirty,
		    lines_w_dirty,
		    line_items_w_dirty,
		    fiber_wan_lines

from fy2016_schools_demog_matr as sd
left join public.fy2016_schools_aggregation_matr as sa
on	sd.school_esh_id = sa.school_esh_id
where sd.postal_cd in ('DE', 'HI') 

/*
Author: Jess Seok
Created On Date: 11/18/2016
Last Modified Date: 
Name of QAing Analyst(s):Justine Schott
*/