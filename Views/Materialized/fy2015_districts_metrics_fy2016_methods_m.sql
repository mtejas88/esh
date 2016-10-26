select			district_esh_id,
				num_students,
				exclude_from_analysis,
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
              else .08* (campus_count - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_scalable_campuses,
            case
              when campus_count < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .92* (campus_count - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_unscalable_campuses

from	fy2015_districts_aggregation_fy2016_methods_m

/*
Author: Justine Schott
Created On Date:
Last Modified Date: 10/26/2016
Name of QAing Analyst(s):
Purpose: For comparing across years
Methodology: Utilizing line items and 2016 districts universe
*/