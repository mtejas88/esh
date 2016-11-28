select
	distinct
   sm.campus_id,
   sm.school_esh_ids,
   sm.district_esh_id,
   sm.name,
   sm.school_type,
   sm.address,
   sm.city,
   sm.postal_cd,
   sm.zip,
   sm.locale,
   sm.num_students,
   sm.frl_percent,
   case
   		when dd.exclude_from_ia_analysis = false and ia_bandwidth > 0
			then false
		else true
   end as exclude_from_ia_analysis,
	sm.ia_bandwidth_per_student_kbps,
	case
		when sm.ia_bandwidth_per_student_kbps >= 100
			then true
		when sm.ia_bandwidth_per_student_kbps < 100
			then false
	end as meeting_2014_goal_no_oversub,
	case
    	when sm.ia_bandwidth_per_student_kbps >= 100
      	and broadband_internet_upstream_lines > 0
      		then TRUE
    	when sm.ia_bandwidth_per_student_kbps < 100
    	or broadband_internet_upstream_lines = 0
    	or broadband_internet_upstream_lines is null
      		then FALSE
	end as meeting_2014_goal_no_oversub_fcc_25,
	case
		when not_broadband_internet_upstream_lines > 0
			then true
		else false
	end as at_least_one_line_not_meeting_broadband_goal,
	sm.ia_monthly_cost_per_mbps,
	ia_bandwidth as ia_bw_mbps_total,
	ia_monthly_cost as ia_monthly_cost_total,
	sm.ia_monthly_cost_direct_to_district,
	sm.ia_monthly_cost_shared,
	case
		when sm.ia_monthly_cost_per_mbps <= 3
			then true
		when sm.ia_monthly_cost_per_mbps > 3
			then false
	end as meeting_3_per_mbps_affordability_target,
	sm.current_known_scalable_campuses,
	sm.current_assumed_scalable_campuses,
	sm.current_known_unscalable_campuses,
	sm.current_assumed_unscalable_campuses,
	sm.wan_lines,
	sm.ia_monthly_cost_no_backbone

from public.fy2016_schools_metrics_matr sm
left join public.fy2016_districts_deluxe_matr dd
on sm.district_esh_id = dd.esh_id

order by sm.postal_cd,
		 sm.campus_id

/*
Author: Jess Seok
Created On Date: 11/28/2016
Last Modified Date:
Name of QAing Analyst(s):Justine Schott
*/