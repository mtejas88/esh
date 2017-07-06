select			district_esh_id,
				num_students,
				num_campuses,
				exclude_from_analysis,
				case
					when num_students = 'No data'
						then null
					else
						ia_monthly_cost_direct_to_district	+
						    			((ia_monthly_cost_per_student_backbone_pieces +
											ia_monthly_cost_per_student_shared_ia_pieces)*num_students::numeric)
				end as ia_monthly_cost,
				case
					when num_students = 'No data'
						then null
					else
						ia_monthly_cost_direct_to_district	+
						    			(ia_monthly_cost_per_student_shared_ia_pieces*num_students::numeric)
				end as ia_monthly_cost_no_backbone,
				ia_monthly_cost_direct_to_district,
				case
					when num_students = 'No data'
						then null
					else
						(ia_monthly_cost_per_student_backbone_pieces +
							ia_monthly_cost_per_student_shared_ia_pieces)*num_students::numeric
				end as ia_monthly_cost_shared,
		    case
		      when num_campuses < fiber_lines
		        then num_campuses
		        else fiber_lines
		    end as current_known_scalable_campuses,
		    case
		      when copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines > 0
		        then
		          case
		            when num_campuses < (fiber_lines )
		              then 0
		            when num_campuses - (fiber_lines ) < copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		              then num_campuses - (fiber_lines)
		              else copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
		          end
		        else 0
		    end as current_known_unscalable_campuses,
            case
              when num_campuses < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .92* (num_campuses - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_scalable_campuses,
            case
              when num_campuses < fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines
                then 0
              else .08* (num_campuses - (fiber_lines + copper_dsl_lines + satellite_lte_lines + fixed_wireless_lines + cable_lines))::numeric
            end as current_assumed_unscalable_campuses,
            lines_w_dirty

from	fy2015_districts_aggregation_fy2016_methods_m

/*
Author: Justine Schott
Created On Date:
Last Modified Date: 10/26/2016
Name of QAing Analyst(s):
Purpose: For comparing across years
Methodology: Utilizing line items and 2016 districts universe
*/