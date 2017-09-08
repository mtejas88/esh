select 
  district_esh_id,
  fiber_target_status,
  exclude_from_wan_analysis,
  case
    --for districts that aren't targets, they just need to be fit for wan to be fit for campus
    when exclude_from_wan_analysis = false
     and fiber_target_status != 'Target'
      then false
    --for all districts, if they are not fit for wan analysis then they are not fit for campus
    when exclude_from_wan_analysis = true
      then true
    --for targets, if they have any category = Incorrect Non-fiber or 'Correct Non-fiber and Incorrect Fiber' then they are not fit for campus
    when count(
              case 
                when category in ('Incorrect Non-fiber','Correct Non-fiber and Incorrect Fiber')
                  then campus_id
              end) > 0
      then true
    --for targets, if they have any non-fiber allocated to the district BEN then not fit
    when sum(campus_nonfiber_lines_w_dirty) < non_fiber_lines_w_dirty
      then true
    --for targets, if they have any correct non fiber and every campus has a connection and not in the above then  fit for campus
    when count(
              case
                when category = 'Correct Non-fiber'
                  then campus_id
              end) > 0
     and count(case when category is null then campus_id end) = 0
      then false
    else true
  end as exclude_from_campus_analysis
            

from public.fy2017_campus_summary_matr


group by 
  district_esh_id,
  non_fiber_lines_w_dirty,
  exclude_from_wan_analysis,
  fiber_target_status


/*
Author: Jeremy Holtzman
Created On Date: 9/8/2017
Name of QAing Analyst(s):
Purpose: use the campus summary to determine if fit for campus analysis
Methodology:
1. All districts that are not fiber targets and are fit for WAN analysis are fit for campus analysis
2. All districts that are not fit for WAN analysis are NOT fit for campus analysis
3. Remaining districts that have any incorrectly allocated non-fiber, non-fiber to the district, 
    or a campus with Correct non-fiber and incorrect fiber are NOT fit for campus analysis
4. Remaining districts that have any correct non-fiber and every campus has some sort of connection are fit fot campus analysis
5. Remaining districts are NOT fit for campus analysis
*/