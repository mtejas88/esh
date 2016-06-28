/*
Date Created: Spring 2016
Date Last Modified : 06/27/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: For each district, find the highest and lowest bandwidth (in mbps) broadband services requested in 2016 
*/

-- note columns Maximum Capacity / Minimum Capacity have clean formatting
select  entity_id, 
        array_agg("Category One Description") as description,
        max(case
          when right("Maximum Capacity",4) = 'Gbps'
            then 1000
          when right("Maximum Capacity",4) = 'Kbps'
            then 1/1000
          else
            1
        end *
        left("Maximum Capacity",char_length("Maximum Capacity")-5)::numeric) as max_mbps_requested,
        min(case
          when right("Minimum Capacity",4) = 'Gbps'
            then 1000
          when right("Minimum Capacity",4) = 'Kbps'
            then 1/1000
          else
            1
        end *
        left("Minimum Capacity",char_length("Minimum Capacity")-5)::numeric) as min_mbps_requested
from fy2016.form470s f470
join ( select distinct entity_id, ben
            from public.esh_id_mappings
            where entity_type = 'District' ) eim
  on f470."BEN" = eim.ben 
where "Service Type" = 'Internet Access and/or Telecommunications'
  and "Function" not ilike '%voice%'
  and "Fund Year" = '2016'
group by entity_id