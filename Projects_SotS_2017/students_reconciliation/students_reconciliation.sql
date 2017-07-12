with summary as (
  select 
    case
      when dd16.esh_id is null
        then '1) new districts'
      when dd17.esh_id is null
        then '7) lost district'
      when dd16.num_students > dd17.num_students
      and dd16.num_schools > dd17.num_schools
        then '6) dropped students and schools across years'
      when dd16.num_students > dd17.num_students
        then '5) dropped students only across years'
      when dd16.num_students < dd17.num_students
      and dd16.num_schools < dd17.num_schools
        then '3)new students and schools across years'
      when dd16.num_students < dd17.num_students
        then '2) new students only across years'
      else '4) same both years'
    end as category,
    count(*) as districts,
    sum(dd16.num_students) as students_2016,
    sum(dd17.num_students) as students_2017
  from (
    select *
    from public.fy2016_districts_deluxe_matr 
    where include_in_universe_of_districts
    and district_type = 'Traditional'
  ) dd16
  full outer join (
    select *
    from public.fy2017_districts_deluxe_matr 
    where include_in_universe_of_districts
    and district_type = 'Traditional'
  )  dd17
  on dd16.esh_id = dd17.esh_id
  group by 1
) 


select *
from(
  select  *,
          (students_2017-students_2016)/students_2016 as pct_change
  from summary
  
  UNION
  
  select
    '0) TOTAL' as category,
    null as districts,
    sum(students_2016) as students_2016,
    sum(students_2017) as students_2017,
    (sum(students_2017)-sum(students_2016))/sum(students_2016) as pct_change
  from summary
) final
order by category