select			sa.*,
				1 as num_campuses,
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
		      when 1 < fiber_lines
		        then 1
		        else fiber_lines
		    end as current_known_scalable_campuses,
		    case
		      when copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines > 0
		        then
		          case
		            when 1 < (fiber_lines )
		              then 0
		            when 1 - (fiber_lines ) < copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		              then 1 - (fiber_lines)
		              else copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		          end
		        else 0
		    end as current_known_unscalable_campuses,
            case
              when 1 < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .92* (1 - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_scalable_campuses,
            case
              when 1 < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .08* (1 - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_unscalable_campuses

from public.fy2015_schools_aggregation_m as sa

/*
Author: Justine Schott
Created On Date: 12/8/2016
Last Modified Date:
Name of QAing Analyst(s):
*/