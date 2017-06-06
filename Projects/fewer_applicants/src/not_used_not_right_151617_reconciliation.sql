with applicants_16 as (
  select
    billed_entity_number,
    count(*) as applications_2016
  from fy2016.basic_informations bi16
  group by 1
),
applicants_17 as (
  select
    billed_entity_number,
    count(*) as applications_2017
  from fy2017.basic_informations bi17
  group by 1
),
applicants_15 as (
  select
    "BEN" as billed_entity_number,
    count(*) as applications_2015
  from public.fy2015_basic_information_and_certifications bi15
  group by 1
),
applicants as (
  select
    case
      when a1617.billed_entity_number is null
        then a15.billed_entity_number
      else a1617.billed_entity_number
    end as billed_entity_number,
    case
      when applications_2015 is null
        then 0
      else applications_2015
    end as applications_2015,
    applications_2016,
    applications_2017
  from(
    select
      case
        when a16.billed_entity_number is null
          then a17.billed_entity_number
        else a16.billed_entity_number
      end as billed_entity_number,
      case
        when applications_2016 is null
          then 0
        else applications_2016
      end as applications_2016,
      case
        when applications_2017 is null
          then 0
        else applications_2017
      end as applications_2017
    from applicants_16 a16
    full outer join applicants_17 a17
    on a16.billed_entity_number = a17.billed_entity_number
  ) a1617
  full outer join applicants_15 a15
  on a1617.billed_entity_number = a15.billed_entity_number
)

select
  case
    when applications_2016 + applications_2017 = 0
      then 'dropped off after 2015'
    when applications_2017 = 0
      then 'dropped off after 2016'
    when applications_2015 + applications_2016 = 0
      then 'new 2017'
    when applications_2015 = 0
      then 'new 2016'
    else '15-17'
  end as category,
  count(*) as applicants,
  sum(applications_2015) as applications_2015,
  sum(applications_2016) as applications_2016,
  sum(applications_2017) as applications_2017
from applicants
group by 1


