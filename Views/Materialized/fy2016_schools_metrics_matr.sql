select			sd.*,
				school_esh_ids,
				num_schools,
				1 as num_campuses,
				broadband_internet_upstream_lines,
				not_broadband_internet_upstream_lines,
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
            end as current_assumed_unscalable_campuses,
			wan_lines,
			frl_percent

from public.fy2016_schools_demog_matr as sd
left join public.fy2016_schools_aggregation_matr as sa
on	sd.campus_id = sa.campus_id
where sd.postal_cd in ('DE', 'HI', 'RI')

/*
Author: Jess Seok
Created On Date: 11/28/2016
Last Modified Date:
Name of QAing Analyst(s):Justine Schott
*/