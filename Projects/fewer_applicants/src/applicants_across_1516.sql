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
  sum(applications_2016) as applications_2016,
  sum(case
        when recipients_2015 = 0
          then 0
        else recipients_2015
      end) as recipients_2015,
  sum(case
        when recipients_2016 = 0
          then 0
        else recipients_2016
      end) as recipients_2016,
  sum(case
        when students_2015 = 0
          then 0
        else students_2015
      end) as students_2015,
  sum(case
        when students_2016 = 0
          then 0
        else students_2016
      end) as students_2016
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
left join (
  select
    applicant_ben,
    count(ben) as recipients_2016,
    sum(case
          when number_of_students > 13300
            then 13300
          else number_of_students
        end) as students_2016
  from (
    select distinct
      applicant_ben,
      ben
    from fy2016.recipients_of_services
  ) ros
  left join (
    select
      child_entity_ben,
      avg(child_number_of_students::numeric) as number_of_students
      from fy2016.discount_calculations
      group by 1
  ) dc
  on ros.ben = dc.child_entity_ben
  group by 1
) ros16
on applicants.billed_entity_number = ros16.applicant_ben
left join (
  select
    applicant_ben,
    count(ben) as recipients_2015,
    sum(case
          when number_of_students > 13300
            then 13300
          else number_of_students
        end) as students_2015
  from (
    select distinct
      bic."BEN" as applicant_ben,
      ae."BEN" as ben
    from public.fy2015_item21_allocations_by_entities ae
    join public.fy2015_basic_information_and_certifications bic
    on ae."Application Number" = bic."Application Number"
  ) ros
  left join (
    select
      "BEN" as child_entity_ben,
      avg("Full/Part Count"::numeric) as number_of_students
      from public.fy2015_discount_calculations
      group by 1
  ) dc
  on ros.ben = dc.child_entity_ben
  group by 1
) ros15
on applicants.billed_entity_number = ros15.applicant_ben
group by 1
order by 1