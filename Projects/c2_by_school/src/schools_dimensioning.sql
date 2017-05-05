select
  case
    when eb_bens > 1
      then '>1 ben'
    when eb_bens = 0
      then 'no ben'
    when er_students = 0
      then 'no student values'
    when er_students > 1
      then 'multiple student values'
    when c2_bens = 0
      then 'no c2 scrape'
    when c2_rem_balance = 0
      then 'no remaining budget value'
    else 'included in sample'
  end as category,
  count(*)

from(
  select school_esh_id,
    count(*) as entries, count(distinct eb.ben) as eb_bens, count(distinct er.entity_number) as er_bens, count(distinct c2.ben) as c2_bens,
    sum(case when number_of_full_time_students::numeric > 0  then 1 else 0 end) as er_students,
    sum(case when remaining_balance is not null  then 1 else 0 end) as c2_rem_balance

  from public.fy2016_schools_demog_matr sd
  left join public.entity_bens eb
  on sd.school_esh_id = eb.entity_id::varchar
  left join fy2016.entity_reports er
  on eb.ben = er.entity_number
  left join(
    select *
    from c2_budgets
    where year = 2016) c2
  on eb.ben = c2.ben::varchar
  where sd.district_include_in_universe_of_districts = true
  group by school_esh_id
) schools

group by 1