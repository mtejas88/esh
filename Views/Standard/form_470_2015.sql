select entity_id, 
       array_agg("Internet/Telecom Services") as description
from public.fy2015_form470s f470
join ( select distinct entity_id, ben
            from public.entity_bens
            where entity_type = 'District' ) eim
on f470."Applicant Entity Number" = eim.ben 
where "Funding Year"= '2015'
and "Internet/Telecom RFP?" = 'Yes'

group by entity_id