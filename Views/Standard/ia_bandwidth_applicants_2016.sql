/*
Date Created: Spring 2016
Date Last Modified : 06/02/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: Estimate internet access bandwidth received by district in 2016
Methodology: Used clean + dirty data since we haven't started cleaning; Estimate using Internet and Upstream added together; Used applicant view (without recipients) for simplicity
*/

select  applicant_id, --using applicant view since allocations are not accurate yet (6/2/2016)
        sum(case
              when  internet_conditions_met = true
                    or upstream_conditions_met = true
                then bandwidth_in_mbps * case
                                          when num_lines = 'Unknown'
                                            then 1  --if num_lines unknown, assume 1 to be conservative
                                          else num_lines::numeric
                                        end
              else
                0
            end) as sum_internet_bandwidth
from fy2016.line_items 
where broadband = true
group by applicant_id
