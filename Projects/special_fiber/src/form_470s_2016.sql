select "BEN" as applicant_ben,
eb.entity_id as applicant_id,
"470 Number" as form_470,
"Billed Entity State" as postal_cd,
"Applicant Type" as applicant_type,
"Service Type" as service_type,
"Function" as function

from fy2016.form470s 

left join public.entity_bens eb
on form470s."BEN" = eb.ben

where "Function" = 'Self-provisioning'