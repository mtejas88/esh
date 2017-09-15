with districts as (
  select 
    dd.esh_id,
    num_students,
    exclude_from_ia_analysis,
    meeting_2014_goal_no_oversub,
    num_students*sum("TOTFRL"::numeric)/sum("MEMBER"::numeric) as frl_students
  from fy2017_districts_deluxe_matr dd
  left join public.fy2014_fy2015_schools_membership mem 
  on dd.nces_cd = mem."LEAID" 
  left join public.fy2014_fy2015_schools_lunch_program_eligibility frl
  on dd.nces_cd = frl."LEAID"
  where mem."MEMBER"::numeric > 0
  and frl."TOTFRL"::numeric > 0 
  and dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
  group by 1, num_students, 3, 4
),

demog as (
  select 
    sum(dd.num_students) as member_population,
    sum(frl_students)/sum(d.num_students)*sum(dd.num_students) as frl_population,
    sum(case
          when d.exclude_from_ia_analysis= false 
            then d.num_students
          else 0
        end) as member_sample,
    sum(case
          when d.exclude_from_ia_analysis= false 
            then frl_students
          else 0
        end) as frl_sample    
  from fy2017_districts_deluxe_matr dd
  left join districts d 
  on dd.esh_id = d.esh_id 
  where dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
)


select
  'overall' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then num_students::numeric
        else 0
      end)/member_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then num_students::numeric
        else 0
      end)/member_sample*member_population/1000000 as extrap_students_not_meeting_goals_mil,
  member_population as population
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by member_sample, member_population

UNION

select
  'frl' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then frl_students
        else 0
      end)/frl_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then frl_students 
        else 0
      end)/frl_sample*frl_population/1000000 as extrap_students_not_meeting_goals_mil,
  frl_population as population
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by frl_sample, frl_population
