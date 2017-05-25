select
  d17.esh_id,
  case
    when  d17.exclude_from_ia_analysis = false
          and d17.ia_bandwidth_per_student_kbps < 100
            then 'Target'
    when  d17.exclude_from_ia_analysis = false
          and d17.ia_bandwidth_per_student_kbps >= 100
            then 'Not Target'
    when  d16.exclude_from_ia_analysis = false
          and (d16.ia_bw_mbps_total * 1000)::numeric / d17.num_students::numeric  >= 100 --might want to make this higher bc some districts may have dropped add'l connections
            then 'Not Target'
    when  d15.exclude_from_analysis = false
          and d15.ia_bandwidth_per_student != 'Insufficient data'
          and (d15.total_ia_bw_mbps * 1000)::numeric / d17.num_students::numeric  >= 100
            then 'Not Target'
    when  d17.ia_applicants is null or d17.ia_applicants = ''
            then 'No Data'
    else 'Potential Target'
  end as bw_indicator,
  d15.ia_bandwidth_per_student as ia_bandwidth_per_student_kbps_2015,
  d16.ia_bandwidth_per_student_kbps as ia_bandwidth_per_student_kbps_2016,
  d17.ia_bandwidth_per_student_kbps as ia_bandwidth_per_student_kbps_2017,
  d15.exclude_from_analysis as exclude_from_analysis_2015,
  d16.exclude_from_ia_analysis as exclude_from_analysis_2016,
  d17.exclude_from_ia_analysis as exclude_from_analysis_2017,
  d17.ia_applicants

from fy2017_districts_predeluxe_matr d17

left join fy2016_districts_deluxe_matr d16
on d17.esh_id::varchar = d16.esh_id

left join fy2015_districts_deluxe_m d15
on d16.esh_id = d15.esh_id::varchar

where d17.include_in_universe_of_districts_all_charters

/*
Author: Jeremy Holtzman
Created On Date: 4/27/2017
Last Modified Date:
Name of QAing Analyst(s):
Purpose: To identify districts' bandwidth target status
Methodology: If clean in 2017, check if meeting goals. If not clean in 2017,
  see if clean and meeting in 2016. Repeat for 2015
*/
