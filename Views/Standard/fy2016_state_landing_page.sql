select 	*,
		case
			when needs_bandwidth_reason = 'Target'
				then true
			else false
		end needs_bandwidth,
		case
			when needs_fiber_reason = 'Target'
				then true
			else false
		end needs_fiber,
		case
			when needs_wifi_reason = 'Target'
				then true
			else false
		end needs_wifi,
		case
			when needs_better_price_reason = 'Target'
				then true
			else false
		end needs_better_price,
		case
			when needs_more_info_reason != 'Data'
				then true
			else false
		end needs_more_info,
		case
			when contract_expiring_2017_reason = 'Target'
				then true
			else false
		end contract_expiring_2017,
		case
			when filed_470_2017_reason = 'Target'
				then true
			else false
		end filed_470_2017

from (	SELECT 	dd.esh_id,
				dd.nces_cd,
				dd.name,
				dd.num_schools,
				dd.num_students,
			   	CASE 	WHEN bw_target_status IN ('Target', 'Not Target') THEN bw_target_status
			   			WHEN bw_target_status = 'No Data' and apps.applicant_id is null THEN 'No Data Non-Filer'
			   			when bw_target_status IN ('No Data', 'Potential Target') THEN 'No Data Clarification Needed'
			        	ELSE 'Error'
			   	END as needs_bandwidth_reason, --assumes potentails should be marked as needs Clarification Needed
			   	CASE 	WHEN fiber_target_status IN ('Target', 'Not Target') THEN fiber_target_status
			   			WHEN fiber_target_status = 'No Data' and apps.applicant_id is null THEN 'No Data Non-Filer'
			   			when fiber_target_status IN ('No Data', 'Potential Target') THEN 'No Data Clarification Needed'
			        	ELSE 'Error'
			   	END as needs_fiber_reason, --assumes potentails should be marked as needs Clarification Needed
				CASE 	WHEN wifi.count_wifi_needed > 0 THEN 'Target'
			   			WHEN wifi.count_wifi_needed = 0 THEN 'Not Target'
			   			WHEN apps.applicant_id is null THEN 'No Data Non-Filer'
			        	ELSE 'No Data Clarification Needed'
			   	END as needs_wifi_reason,
			   	CASE 	WHEN wifi.count_wifi_needed > 0 THEN 'Some'
			   			WHEN wifi.count_wifi_needed = 0 THEN 'None'
			   			WHEN apps.applicant_id is null THEN 'No Data Non-Filer'
			        	ELSE 'No Data Clarification Needed'
			   	END as num_schools_need_wifi, -- stub until we can figure out methodology to calculate this
				CASE 	WHEN NOT(exclude_from_ia_cost_analysis) and dd.ia_monthly_cost_per_mbps<=3  THEN 'Not Target'
			   			WHEN NOT(exclude_from_ia_cost_analysis) and dd.ia_monthly_cost_per_mbps>3  THEN 'Target'
			   			WHEN apps.applicant_id is null THEN 'No Data Non-Filer'
			        	ELSE 'No Data Clarification Needed'
			   	END as needs_better_price_reason, --stub, need to update to affordability metric once finalized
				CASE 	WHEN 	(exclude_from_ia_analysis or exclude_from_ia_cost_analysis or dd.exclude_from_wan_analysis or exclude_from_wan_cost_analysis
								or bw_target_status IN ('No Data', 'Potential Target') or fiber_target_status IN ('No Data', 'Potential Target'))
								and apps.applicant_id is null THEN 'No Data Non-Filer'
			        	WHEN 	(exclude_from_ia_analysis or exclude_from_ia_cost_analysis or dd.exclude_from_wan_analysis or exclude_from_wan_cost_analysis
								or bw_target_status IN ('No Data', 'Potential Target') or fiber_target_status IN ('No Data', 'Potential Target')) then 'No Data Clarification Needed'
			   			ELSE 'Data'
			   	END as needs_more_info_reason,
			   	CASE 	WHEN most_recent_ia_contract_end_date <= '2017-06-30' THEN 'Target'
			   	    	WHEN most_recent_ia_contract_end_date > '2017-06-30' THEN 'Not Target'
			   	    	WHEN apps.applicant_id is null THEN 'No Data Non-Filer'
			   	    	ELSE 'No Data Clarification Needed'
			   	END as contract_expiring_2017_reason,
			   	CASE 	WHEN agg_470s.entity_id is not null THEN 'Filed 470'
			   	    	WHEN apps.applicant_id is null THEN 'No Data Non-Filer'
			   	    	ELSE 'No Data Clarification Needed'
			   	END as filed_470_2017_reason,
				CASE WHEN NOT(exclude_from_ia_analysis)
						  THEN dd.ia_bw_mbps_total
				END as ia_bw_mbps_total,
				CASE WHEN NOT(exclude_from_ia_analysis)
				 					 and (dd.num_students::numeric*.1) - dd.ia_bw_mbps_total < 0
						  THEN 0
							WHEN NOT(exclude_from_ia_analysis)
				 			THEN round( ((dd.num_students::numeric*.1) - dd.ia_bw_mbps_total)::numeric ,2)
				END as ia_bw_in_mbps_needed_for_2014_goal,
				CASE WHEN NOT(exclude_from_ia_analysis)
				      THEN dd.hierarchy_ia_connect_category
				END as hierarchy_ia_connect_category,
				CASE WHEN NOT(exclude_from_ia_analysis)
				      THEN dd.ia_bandwidth_per_student_kbps
				END as ia_bandwidth_per_student_kbps,
			   	CASE WHEN NOT(exclude_from_ia_cost_analysis)
				      THEN dd.ia_monthly_cost_per_mbps
				END as ia_monthly_cost_per_mbps,
				CASE WHEN NOT(exclude_from_ia_cost_analysis)
				      THEN dd.ia_monthly_cost_per_mbps * 12
				END as ia_annual_cost_per_mbps,
				CASE WHEN NOT(dd.exclude_from_wan_analysis)
				      THEN dd.wan_bandwidth_high
				END as wan_bandwidth_high,
				CASE WHEN NOT(dd.exclude_from_wan_analysis)
				      THEN dd.wan_bandwidth_low
				END as wan_bandwidth_low,
				CASE WHEN NOT(exclude_from_wan_cost_analysis)
				      THEN dd.wan_monthly_cost_per_line
				END as wan_monthly_cost_per_line,
				CASE WHEN NOT(dd.exclude_from_wan_analysis)
				      THEN dd.wan_monthly_cost_per_line * 12
				END as wan_annual_cost_per_line,
				CASE WHEN NOT(dd.exclude_from_wan_analysis)
							AND NOT(exclude_from_ia_analysis)
							THEN (dd.current_known_scalable_campuses + dd.current_assumed_scalable_campuses) / dd.num_campuses::numeric
				END as percentage_scalable_campuses,
				CASE WHEN NOT(dd.exclude_from_wan_analysis)
						  AND NOT(exclude_from_ia_analysis)
						  THEN dd.current_known_unscalable_campuses
				END as current_known_unscalable_campuses,
				dd.lines_w_dirty as total_circs,
				d.ap_name,
				d.ap_email,
				d.ap_phone,
				d.cp_name,
				d.cp_email,
				d.cp_phone,
				dd.address,
				dd.city,
			   	dd.postal_cd,
			   	dd.zip,
				agg_470s.cat_1_urls, --only included if district is applicant
				agg_470s.cat_2_urls, --only included if district is applicant
			   	concat(	'http://www.compareandconnectk12.org/2016/',
				          d.postal_cd,
					        '/districts/',
					        d.slug,
					        '?postal_cd=',
					        d.postal_cd) as link_to_district_cck12
		from public.fy2016_districts_deluxe dd
		left join fy2016.districts d
		on dd.esh_id = d.esh_id::varchar
		left join endpoint.fy2016_fiber_bw_target_status ts
		on dd.esh_id = ts.esh_id
		left join (
			select 	eb.entity_id,
					array_agg(distinct 	case
											when url."Service Type" = 'Internet Access and/or Telecommunications'
												then "Form 470 URL"
										end) as cat_1_urls,
					array_agg(distinct 	case
											when url."Service Type" != 'Internet Access and/or Telecommunications'
												then "Form 470 URL"
										end) as cat_2_urls
			from fy2017.form470s info
			left join fy2017.form470_rfps url
			on info."470 Number" = url."470 Number"
			left join public.entity_bens eb
			on info."BEN" = eb.ben
			group by eb.entity_id
		) agg_470s
		on dd.esh_id = agg_470s.entity_id::varchar
		left join (
			select distinct applicant_id
			from fy2016.line_items
			where broadband = true
		) apps
		on dd.esh_id = apps.applicant_id::varchar
		left join endpoint.fy2016_wifi_connectivity_informations wifi
		on dd.esh_id = wifi.parent_entity_id::varchar
		where dd.include_in_universe_of_districts = true
) agg

/*
Author:
Created On Date:
Last Modified Date: 9/30/2016 - Justine Schott - updated targeting fields to better serve landing page map
Name of QAing Analyst(s):
Purpose:
Methodology:

Dependencies: [endpoint.fy2016_districts_deluxe, endpoint.fy2016_wifi_connectivity_informations, endpoint.fy2016_fiber_bw_target_status]
*/
