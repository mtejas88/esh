select  applicant_id, 
        sum(case
              when  internet_conditions_met = true
                    or upstream_conditions_met = true
                then bandwidth_in_mbps * case
                                          when num_lines = 'Unknown'
                                            then 1  
                                          else num_lines::numeric
                                        end
              else
                0
            end) as sum_internet_bandwidth
from fy2016.line_items 
where broadband = true
group by applicant_id

