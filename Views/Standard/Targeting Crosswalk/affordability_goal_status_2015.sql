/*
Date Created: Spring 2016
Date Last Modified : 06/27/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: For each district, find affordability ($3 per mbps) and bandwidth (100 kbps per student) meeting status 
*/

select  esh_id,
        exclude_from_analysis,
        case
          when exclude_from_analysis = true then 'Unknown for 2015'
          when ia_cost_per_mbps = 'Insufficient data' then 'Unknown for 2015'
          when ia_cost_per_mbps::numeric/12 <= 3 then 'Meeting'
          when ia_cost_per_mbps::numeric/12 > 3 then 'Not meeting'
        end as afford_status,
        ia_cost_per_mbps,
        case
          when ia_bandwidth_per_student = 'Insufficient data' then 'Unknown for 2015'
          when ia_bandwidth_per_student::numeric >= 100 then 'Meeting'
          when ia_bandwidth_per_student::numeric < 100 then 'Not meeting'
        end as bandwidth_status,
        ia_bandwidth_per_student,
        slug -- slug is a short-hand for unique district name created by ENG Team
        
from public.districts
where include_in_universe_of_districts = true