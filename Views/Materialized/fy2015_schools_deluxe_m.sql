select
	distinct
   sm.campus_id,
   sm.school_esh_ids,
   sm.district_esh_id,
   dd.name as district_name,
   sm.postal_cd,
   sm.num_students,
   sm.num_schools,
   sm.num_campuses,
   case
   		when dd.exclude_from_analysis = false and sm.ia_bandwidth_per_student_kbps > 0
			then false
		else true
   end as exclude_from_analysis,
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
	sm.wan_lines,
	sm.ia_monthly_cost_no_backbone

from public.fy2015_schools_metrics_m sm
left join public.districts dd
on sm.district_esh_id = dd.esh_id

/*
Author: Justine Schott
Created On Date: 12/8/2016
Last Modified Date:
Name of QAing Analyst(s):
*/