select 
  d16.esh_id,
  case 
    when  d16.exclude_from_analysis = false 
          and d16.ia_bandwidth_per_student_kbps < 100
            then 'Target'
    when  d16.exclude_from_analysis = false 
          and d16.ia_bandwidth_per_student_kbps >= 100
            then 'Not Target'
    when  (d15.ia_bandwidth_per_student_kbps = 'Insufficient data' or d15.ia_bandwidth_per_student_kbps is null) 
          and (d16.ia_applicants is null or d16.ia_applicants = '')
          and d16.postal_cd in ('AZ',  'CO', 'IL', 'MD', 'MA', 'MT', 'NH', 'NM', 'OK', 'RI','TX', 'VA')
            then 'Target'
    when  (d15.ia_bandwidth_per_student_kbps = 'Insufficient data' or d15.ia_bandwidth_per_student_kbps is null) 
          and (d16.ia_applicants is null or d16.ia_applicants = '')
            then 'Potential Target'
    when  (d15.ia_bandwidth_per_student_kbps = 'Insufficient data' or d15.ia_bandwidth_per_student_kbps is null) 
            then 'No Data'
    when  d15.ia_bandwidth_per_student_kbps::numeric >= 100 
            then 'Not Target'
    when  d15.ia_bandwidth_per_student_kbps::numeric < 100 
            then 'Potential Target'
    else 'Error'
  end as bw_indicator,
  d15.ia_bandwidth_per_student_kbps as ia_bandwidth_per_student_kbps_2015,
  d16.ia_bandwidth_per_student_kbps as ia_bandwidth_per_student_kbps_2016,
  d15.exclude_from_analysis as exclude_from_analysis_2015,
  d16.exclude_from_analysis as exclude_from_analysis_2016,
  d16.ia_applicants

from fy2016_districts_deluxe_m d16
left join fy2015_districts_deluxe_m d15
on d16.esh_id = d15.esh_id::varchar

/*
Author: Justine Schott
Created On Date: 8/17/2016
Last Modified Date: 9/13/2016
Name of QAing Analyst(s): 
Purpose: To identify districts' bandwidth target status
Methodology: Compare 2015 and 2016 bw/student values, as well as whether they receive services
*/