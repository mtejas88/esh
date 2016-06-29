select  entity_id,
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
        avg("Comp Suff"::numeric) as "Comp Suff",
        avg("Most Suff"::numeric) as "Most Suff",
        avg("Some Suff"::numeric) as "Some Suff",
        avg("Rare Suff"::numeric) as "Rare Suff",
        avg("Not Suff"::numeric) as "Not Suff",
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
from public.fy2015_connectivity_questions cq
join public.fy2015_basic_information_and_certifications bic
on cq."Application Number" = bic."Application Number"
join (select distinct entity_id, ben
      from public.entity_bens
      where entity_type = 'District') eim
on bic."BEN" = eim.ben
group by entity_id

