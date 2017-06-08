select
  case
    when applications_2016 = 0
      then 'dropped off'
    when applications_2015 = 0
      then 'new'
    when applications_2015 > applications_2016
      then 'less apps'
    when applications_2015 < applications_2016
      then 'more apps'
    else 'same both years'
  end as category,
  count(*) as applicants,
  sum(applications_2015) as applications_2015,
  sum(applications_2016) as applications_2016
from(
  select
    case
      when bi16.billed_entity_number is null
        then bi15."BEN"
      else bi16.billed_entity_number
    end as billed_entity_number,
    count(distinct  bi16.application_number) as applications_2016,
    count(distinct  bi15."Application Number") as applications_2015
  from fy2016.basic_informations bi16
  full outer join public.fy2015_basic_information_and_certifications bi15
  on bi16.billed_entity_number = bi15."BEN"
  group by 1
) applicants
group by 1