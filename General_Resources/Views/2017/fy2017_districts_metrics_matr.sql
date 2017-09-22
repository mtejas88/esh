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

				case 
					when (upstream_bandwidth = 0 and isp_bandwidth != 0)
						or (upstream_bandwidth != 0 and isp_bandwidth = 0 and com_info_bandwidth = 0)
					then true
					else false 
				end as incomplete_upstream_isp,

				broadband_internet_upstream_lines,

				not_broadband_internet_upstream_lines,

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

		    case  when c1_discount_rate::numeric is not null then c1_discount_rate::numeric
			      when locale in ('Urban', 'Suburban') then
			        case  when frl_percent < .10 then 20
			              when frl_percent < .20 then 40
			              when frl_percent < .35 then 50
			              when frl_percent < .50 then 60
			              when frl_percent < .75 then 80
			              when frl_percent >= .75 then 90
			              else 70
			        end
			      else case when frl_percent < .10 then 25
			                when frl_percent < .20 then 50
			                when frl_percent < .35 then 60
			                when frl_percent < .50 then 70
			                when frl_percent < .75 then 80
			                when frl_percent >= .75 then 90
			                else 70
			      end
			end as discount_rate_c1_matrix,

		    c2_discount_rate as discount_rate_c2,

		    flag_count,

		    wan_monthly_cost,

		    machine_cleaned_lines,

		    non_fiber_lines,

		    non_fiber_lines_w_dirty,

		    non_fiber_internet_upstream_lines_w_dirty,

		    fiber_internet_upstream_lines_w_dirty,

		    fiber_wan_lines_w_dirty,

		    wan_lines_w_dirty,

		    lines_w_dirty,

		    line_items_w_dirty,

		    fiber_wan_lines,

		    consortium_affiliation,

		    ia_procurement_type,

		    ia_no_cost_lines,

		    wan_no_cost_lines,

			most_recent_ia_contract_end_date,

			ia_monthly_cost_direct_to_district_district_applied +

				(ia_monthly_cost_per_student_shared_district_applied*num_students) as ia_monthly_cost_district_applied,

			ia_monthly_cost_direct_to_district_other_applied+

				(ia_monthly_cost_per_student_shared_other_applied*num_students) as ia_monthly_cost_other_applied,

			ia_monthly_funding_direct_to_district+

				(ia_monthly_funding_per_student_shared*num_students) as ia_monthly_funding_total




from	fy2017_districts_demog_matr dd

left	join	fy2017_districts_aggregation_matr	da

on	dd.esh_id	=	da.district_esh_id




/*

Author: Justine Schott

Created On Date: 6/20/2016

Last Modified Date: 9/22/17 JMB adding incomplete_upstream_isp to eventually be used to make clean districts that aren't receiving both upstream and isp dirty

Name of QAing Analyst(s):

Purpose: Districts in 2016 universe, including metric calculations and cleanliness

Methodology: Utilizing other aggregation tables

*/
