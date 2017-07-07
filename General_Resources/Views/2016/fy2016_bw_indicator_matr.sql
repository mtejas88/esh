select
  d16.esh_id,
  case
    when  d16.exclude_from_ia_analysis = false
          and d16.ia_bandwidth_per_student_kbps < 100
            then 'Target'
    when  d16.exclude_from_ia_analysis = false
          and d16.ia_bandwidth_per_student_kbps >= 100
            then 'Not Target'
    when  d15.exclude_from_analysis = false
          and d15.ia_bandwidth_per_student != 'Insufficient data'
          and d15.ia_bandwidth_per_student::numeric >= 100
            then 'Not Target'
    when  d16.ia_applicants is null or d16.ia_applicants = ''
            then 'No Data'
    else 'Potential Target'
  end as bw_indicator,
  d15.ia_bandwidth_per_student as ia_bandwidth_per_student_kbps_2015,
  d16.ia_bandwidth_per_student_kbps as ia_bandwidth_per_student_kbps_2016,
  d15.exclude_from_analysis as exclude_from_analysis_2015,
  d16.exclude_from_ia_analysis as exclude_from_analysis_2016,
  d16.ia_applicants

from fy2016_districts_predeluxe_matr d16
left join fy2015_districts_deluxe_m d15
on d16.esh_id = d15.esh_id::varchar
where d16.include_in_universe_of_districts or d16.district_type = 'Charter'

/*
Author: Justine Schott
Created On Date: 8/17/2016
Last Modified Date: 1/30/2017 - changed so that districts that are dirty in both years can't be Not Targets
Name of QAing Analyst(s):
Purpose: To identify districts' bandwidth target status
Methodology: Compare 2015 and 2016 bw/student values, as well as whether they receive services
*/