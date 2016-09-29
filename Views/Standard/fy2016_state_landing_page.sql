SELECT dd.esh_id,
		dd.nces_cd,
		dd.name,
		dd.num_schools,
		dd.num_students,
	   CASE WHEN bw_target_status = 'Target' THEN true
	        ELSE false
	   END as needs_bandwidth, --doesn't include potentials
	   CASE WHEN fiber_target_status = 'Target' THEN true
	        ELSE false
	   END as needs_fiber, --doesn't include potentials
		 CASE WHEN exists (select * from endpoint.fy2016_wifi_connectivity_informations where parent_entity_id = dd.esh_id::text::int) THEN true
					ELSE false
		 END as needs_wifi,
		 CASE WHEN exists (select * from endpoint.fy2016_wifi_connectivity_informations where parent_entity_id = dd.esh_id::text::int) THEN 'some'
		 END as num_schools_need_wifi, -- stub until we can figure out methodology to calculate this
	   CASE WHEN true THEN true
	    	ELSE false
	   END as needs_better_price, --stub, need to update to affordability metric once finalized
		 CASE WHEN exclude_from_ia_analysis or exclude_from_ia_cost_analysis or dd.exclude_from_wan_analysis or exclude_from_wan_cost_analysis THEN true
			 ELSE false
		 END as needs_more_info,
	   CASE WHEN most_recent_ia_contract_end_date <= '2017-06-30' THEN true
	   	    ELSE false
	   END as contract_expiring_2017,
	   CASE WHEN agg_470s.entity_id is not null THEN true
	        ELSE false
	   END as filed_470_2017,
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
					AND ts.fiber_target_status not in ('Not Target', 'No Data')
					THEN (dd.current_known_scalable_campuses + dd.current_assumed_scalable_campuses) / dd.num_campuses::numeric
		 END as percentage_scalable_campuses,
		 CASE WHEN NOT(dd.exclude_from_wan_analysis)
				  AND NOT(exclude_from_ia_analysis)
				  THEN dd.nga_known_unscalable_campuses
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
from public.fy2016_districts_deluxe_m dd
left join fy2016.districts d
on dd.esh_id = d.esh_id::varchar
left join public.fy2016_fiber_bw_target_status ts
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
on ts.esh_id = agg_470s.entity_id::varchar

/*
Author:
Created On Date:
Last Modified Date: 9/28/2016
Name of QAing Analyst(s):
Purpose:
Methodology:

Dependencies: [endpoint.fy2016_districts_deluxe, endpoint.fy2016_wifi_connectivity_informations, endpoint.fy2016_fiber_bw_target_status]
*/
