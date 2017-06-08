select
  case
    when applications_2017 = 0
      then 'dropped off'
    when applications_2016 = 0
      then 'new'
    when applications_2016 > applications_2017
      then 'less apps'
    when applications_2016 < applications_2017
      then 'more apps'
    else 'same both years'
  end as category,
  count(*) as applicants,
  sum(applications_2016) as applications_2016,
  sum(applications_2017) as applications_2017
from(
  select
    case
      when bi16.billed_entity_number is null
        then bi17.billed_entity_number
      else bi16.billed_entity_number
    end as billed_entity_number,
    count(distinct  bi16.application_number) as applications_2016,
    count(distinct  bi17.application_number) as applications_2017
  from fy2016.basic_informations bi16
  full outer join fy2017.basic_informations bi17
  on bi16.billed_entity_number = bi17.billed_entity_number
  group by 1
) applicants
group by 1