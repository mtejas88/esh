/*
Date Created: Spring 2016
Date Last Modified : 06/02/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: Aggregate answers to 2015 survey questions by district
Methodology: If the answer is a checkbox, sum for each applicant; if the answer is a value, average for each applicant
QA Feedback: Should we update this for the 2016 survey answers?
*/

select  entity_id,
--answers to these questions are a checkbox that seems to show 'Y' when checked and null when not
        count(case 
                when "BroadBand Too Slow" = 'Y' then 1 
              end) as "BroadBand Too Slow",
        count(case 
                when "Phys Strct" = 'Y' then 1 
              end) as "Phys Strct",
        count(case 
                when "Undep Service" = 'Y' then 1 
              end) as "Undep Service",
        count(case 
                when "Equip Too $" = 'Y' then 1 
              end) as "Equip Too $",
        count(case 
                when "Inadeq LAN" = 'Y' then 1 
              end) as "Inadeq LAN",
        count(case 
                when "Install Too $" = 'Y' then 1 
              end) as "Install Too $",
        count(case 
                when "Lack Train" = 'Y' then 1 
              end) as "Lack Train",
        count(case 
                when "Outdate Equip" = 'Y' then 1 
              end) as "Outdate Equip",
--answers to these questions are # of schools, so averaging between each application
        avg("Comp Suff"::numeric) as "Comp Suff",
        avg("Most Suff"::numeric) as "Most Suff",
        avg("Some Suff"::numeric) as "Some Suff",
        avg("Rare Suff"::numeric) as "Rare Suff",
        avg("Not Suff"::numeric) as "Not Suff",
--answers to these questions are a checkbox that seems to show 'Y' when checked and null when not
        count(case 
                when ">50KLib Pop" = 'Y' then 1 
            end) as ">50KLib Pop",
        count(case 
                when ">50KLib <100 Mbps" = 'Y' then 1 
            end) as ">50KLib <100 Mbps",
        count(case 
                when ">50KLib 100 - 1000 Mbps" = 'Y' then 1 
            end) as ">50KLib 100 - 1000 Mbps",
        count(case 
                when ">50KLib >1 Gbps" = 'Y' then 1 
            end) as ">50KLib >1 Gbps"
        
--only district applicants will appear in this list due to the inner joins 
from public.fy2015_connectivity_questions cq
join public.fy2015_basic_information_and_certifications bic
on cq."Application Number" = bic."Application Number"
join (select distinct entity_id, ben
      from public.entity_bens
      where entity_type = 'District') eim
on bic."BEN" = eim.ben
group by entity_id
